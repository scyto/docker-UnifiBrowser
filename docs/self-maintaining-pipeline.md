# Self-maintaining wrapper — design notes (PARKED)

> Status: **draft / parked.** Captured from a design discussion. Not implemented.
> Pick up at: **Layer 2 — the autonomy & escalation model.**

## Goal

Make `docker-UnifiBrowser` a *self-maintaining wrapper*: a pipeline that
(1) proves the image works against a **real** UniFi controller, (2) has an agent
**judge whether an upstream change actually affects us**, and (3) has an agent
**implement + prove + open a PR** for the change — escalating to a human at the
right boundaries.

Built on what already exists: `check-releases.yml` (tracks the upstream version +
PHP floor and dispatches `release.yml`), the write-free `build → smoke → publish`
phases, and `tracked-versions.json` as the pinned-dependency source of truth.

---

## The mental model — three layers

1. **Real integration test** — replace "boots + HTTP 200" with "talks to a live
   controller and gets data."
2. **Evaluator agent** — "did this upstream release actually require *us* to change?"
3. **Implementer agent** — "make the change, prove it on the integration test, open a PR."

**Layer 1 is the ground truth that makes Layers 2–3 trustworthy.** An agent's
judgment is only as safe as the test that can prove it wrong.

---

## Layer 1 — Real integration test against a live controller (the hard part)

You can't run real UDM/UniFi-OS firmware in CI, but you don't need to — you need
the same **API surface**.

Options (best-first):
- **UniFi *Network Application* container** as a CI service (MongoDB + Java app).
  Speaks the classic login/`fetch_sites` API and (recent versions) mints **API keys**.
- **UniFi OS Server in a VM** — only if you specifically need the `/proxy/network/...`
  UniFi-OS path; heavier/more fragile; add as a second occasional matrix leg.

Flow:
1. Start controller container; wait for ready.
2. **Provision headlessly** — create a local admin (setup API, or restore a small
   pre-baked backup / Mongo seed to skip the wizard). Mint an **API key** via the
   controller's API once the admin exists.
3. Run *our* image against it **twice**: classic (`USER`/`PASSWORD`) and official
   (`APIKEY`). Assert the real path: login, `fetch_sites.php` returns a sites array,
   a collection fetch returns JSON. No `LoginFailedException`, no 403, no
   headers-already-sent.
4. Bar = **"auth + API reachable + sites/collection returns data."** No adopted
   hardware needed to exercise login/sites/most collections.

This is the genuinely fragile piece (slow boot, provisioning, version drift between
the app container and real UDM firmware, API-key automation). De-risk with a
**pinned, pre-seeded controller image/backup** (deterministic provisioning) and
treat the **controller version as a tracked dependency** (same pattern as our
upstream pin) so you test against current software on purpose.

> Build this FIRST. It has pure value even with zero AI — it would have caught the
> headers-already-sent "no data" bug.

---

## Layer 2 — "Does this upstream change require us to change?" (evaluator agent)

Key insight: don't ask "did upstream change" (it changes constantly) — ask "did
upstream change something **we depend on**." That requires making the dependency
surface explicit.

- Write an **`UPSTREAM_CONTRACT.md`**: the exact things we rely on — `config/config.php`
  location + `$controllers` shape, `users.php`, the env vars we surface, `start.sh`
  running `php -S`, the PHP floor source (`platform_check.php`), the auth shapes
  (`user/password`, `api_key/verify_ssl`).
- On a new upstream release the agent gets: the **diff** (pinned tag → new tag),
  release notes, and the contract. It emits a **structured verdict** (see schema below).
- **Ground it + verify it.** The contract keeps false positives down; an
  **adversarial second agent** ("try to prove this verdict wrong") keeps false
  negatives down. Even a wrong verdict can't ship — Layer 1 gates it.

Concrete example: the **API-key feature** (added by hand this week) is exactly what
this layer catches — diffing upstream `config/config-template.php` shows the new
`'type' => 'official'` block → verdict `new-feature-to-surface: add APIKEY/VERIFYSSL`.

---

## The autonomy & escalation model  ← **resume here**

The question isn't "can the agent do it?" — it's "what's the routing model?"
**The agent should never be the thing that decides whether it's allowed to ship.**

### Core principle
**Gate autonomy on *verifiability* and *blast radius* — not on the agent's
confidence.** Self-assessed confidence is the least trustworthy signal. The agent
**proposes**; a **policy you author + an oracle (the integration test)** dispose.
The agent is never both the actor and the judge of whether to act.

### Two axes decide everything
- **Axis 1 — Is there an oracle?** Can a machine prove this correct?
  - Yes (Layer-1 test passes/fails on it) → automatable; the *test* is the gate.
  - No (UX/default/security judgment; "is this surfaced *well*?") → human, even if
    the agent wrote 100% of the code.
- **Axis 2 — Blast radius / reversibility.**
  - Docs, comments, additive feature behind a new env flag → low → more rope.
  - Touches existing behavior, defaults, auth, credentials, SSL, data → high →
    escalate regardless of how clean the diff looks.

### Routing table (change-type → who decides)

| Upstream change | Oracle? | Model |
|---|---|---|
| **Mechanical/contract** (config path moved, PHP floor bump, env rename) | Yes | Agent implements → test gates → **auto-PR, maybe auto-merge** |
| **Additive feature** (new auth mode, like API-key) | Partial | Agent implements + tests, but there's a *design choice* → **agent proposes design, human ratifies, agent ships** |
| **Behavioral/breaking** (changes existing auth, defaults, output) | Test catches breakage, not intent | **Advisory only** — agent analyzes + drafts a PR, human merges |
| **Novel / doesn't map to our model** | No | **Hard stop, ask the human** — agents hallucinate plausible-but-wrong here |

The API-key feature sits in row 2: the agent could detect + write it, but *the
human* should still pick "auto-detect from `APIKEY`" and "`VERIFYSSL` default false."
Agent does the labour; human makes the one judgment call.

### Escalate (don't ship) if ANY fire
- **No oracle** — can't be machine-verified.
- **Behavior/default change** — affects existing users.
- **Security/secret/data surface** — auth, keys, SSL, credentials.
- **A design fork** — more than one reasonable way to do it.
- **Agent's "unknowns" list is non-trivial**, or the **adversarial check disagrees**.
- **Repeated red** — can't get the integration test green after N tries → stop,
  surface, don't thrash.

Fully autonomous is the narrow corner: oracle-verified **and** low blast radius
**and** known-safe category **and** the skeptic agent agrees.

### What AI is good vs bad at here (honestly)
- **Good** (use it): reading/understanding the diff, classifying impact against the
  contract, drafting the change, writing tests, **debugging a red build iteratively**
  (tight loop against a checker = sweet spot), writing a crisp escalation.
- **Bad** (not final authority): deciding "good enough to ship" with no oracle,
  security/default/UX judgment, anything novel where confidently-wrong is expensive.

> AI is the right model to **evaluate and propose**; the wrong model to be the **sole
> decider of release.** Release authority = your policy + the oracle + you for the residual.

### The structured verdict the evaluator emits (makes escalation cheap)
```
classification:  additive-feature        # mechanical | additive-feature | behavioral | breaking | novel
blast_radius:    changes-defaults        # docs | additive-flagged | changes-defaults | touches-auth-or-secrets
oracle_result:   integration test GREEN (classic + official)
proposed_change: <diff>
design_choices_for_you:
  - VERIFYSSL default: false (pragmatic) vs true (secure)?
unsure_about:
  - whether upstream's new field is required or optional
adversarial_check: agrees | disagrees: <why>
```
An agent that reliably says *"here's what I'm unsure about"* is worth more than one
that's confidently autonomous — the unknowns are what you route on.

### Calibration — earn autonomy per-category
Start everything **advisory / PR-with-human-merge**. Track classification accuracy
and especially the **false-negative** rate. Promote a category to auto-merge only
after it's earned it ("floor bumps: 20/20 correct → auto"). Autonomy is granted
per-category by evidence, never globally by vibe.

### The human's role shifts
From "do the work" to: **(1) author the routing policy, (2) ratify designs on
additive features, (3) adjudicate the residual of genuine-judgment cases.**

---

## Layer 3 — Implement + prove + PR (implementer agent)

Given a "needs change" verdict + proposed patch:
1. Branch, apply the change (config.php / Dockerfile ENV / README / workflow),
   mirroring existing repo patterns.
2. Run **build → Layer-1 integration test** (both auth modes). Cannot merge red.
3. Open a **PR** with: the triggering diff, the verdict + reasoning, the
   integration-test results, and (for features) README/env docs.
4. Human reviews/merges (at least at first).

This is the existing `check-releases → release` loop with an **agent inserted
between "detected a change" and "made the change."**

---

## Orchestration / where the agent runs
- **GitHub Actions + Claude Agent SDK** (or the Claude Code GitHub Action) on a
  schedule; the runner has `git`/`docker`/`gh` + the integration harness as tools
  and runs the evaluate → implement → test → PR loop.
- Secrets: controller admin creds + CI-minted API key in Actions secrets; the agent
  never sees production keys.
- Trigger: daily cron (like `check-releases`) or an upstream-release webhook.

## Hard parts / risks
- **Live controller in CI is the crux** — slow, stateful, version-sensitive.
  Pin + pre-seed; narrow the assertion bar. Prototype FIRST.
- **LLM judgment isn't the gate** — the integration test is. The agent only proposes.
- **Autonomy dial** — advisory → opens PRs → (maybe) auto-merge the safe categories
  → never auto-merge `breaking`.
- **Cost/time** — controller boot + agent loop is minutes + tokens, but upstream
  releases are rare → cheap amortized.

## Staged rollout (don't build it all at once)
1. **Integration test first** (Network App container + seed + real classic/official
   assertions). AI-independent value.
2. **Evaluator as advisory** — agent posts an impact verdict; eyeball accuracy.
3. **Let it open PRs** — implementer agent, human-merge.
4. **Dial up autonomy** per earned category.

## Next steps when resuming
- [ ] Prototype Layer 1 (`unifi-integration` workflow): Network App container, seed
      admin + API key, run our image in both modes, assert real API.
- [ ] Draft `UPSTREAM_CONTRACT.md` (the dependency surface).
- [ ] Draft `escalation-policy.md` (the deterministic routing rules) + the verdict schema.
- [ ] Research the current controller-container + API-key-minting specifics to make
      the headless seeding path solid.
