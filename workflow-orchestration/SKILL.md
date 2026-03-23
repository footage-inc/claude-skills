---
name: workflow-orchestration
description: >
  Workflow orchestration and task management rules for Claude Code agent behavior.
  Enforces planning-first development, subagent delegation, self-improvement loops,
  verification standards, and elegant solutions. Use this skill whenever Claude is
  working on any non-trivial coding task, bug fix, architecture decision, or
  multi-step implementation. Also trigger when the user mentions task planning,
  todo tracking, lessons learned, or asks Claude to fix/build/refactor anything
  that involves more than a single obvious change. This skill should be consulted
  even for bug reports — it defines autonomous fixing behavior.
---

# Workflow Orchestration

Guidelines for how Claude should approach development tasks — from planning through verification.

## 0. Session Start Protocol

**These two rules are mandatory and must be followed at the start of every task or instruction — no exceptions.**

### 0-a. Always Load Skills First
At the very beginning of any task or instruction, always read the relevant skill files. Never proceed with implementation before loading the applicable skills.

### 0-b. Sync Design Documents Before and After Work
For tasks that have an associated design document (e.g., Notion Hub, architecture docs, task boards):
- **Before starting**: Load the latest version of all related design documents and confirm the current progress/state.
- **After finishing**: Update all design documents (Notion, Git commit logs, architecture docs, etc.) to reflect the completed work. Every piece of information that needs to be logged must be updated before the task is considered done.

If a design document is not up to date at the end of a task, the task is **not complete**.

---

## 1. Plan Node Default

Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions). Planning is the default, not the exception.

- If something goes sideways, STOP and re-plan immediately — don't keep pushing down a broken path
- Use plan mode for verification steps too, not just building
- Write detailed specs upfront to reduce ambiguity and rework

## 2. Subagent Strategy

Use subagents liberally to keep the main context window clean and focused.

- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents rather than struggling in a single thread
- One task per subagent for focused execution — don't overload a single subagent with multiple concerns

## 3. Self-Improvement Loop

After ANY correction from the user, capture the lesson so it never happens again.

- Update `tasks/lessons.md` with the pattern that caused the mistake
- Write rules for yourself that prevent the same mistake from recurring
- Ruthlessly iterate on these lessons until the mistake rate drops to zero
- Review lessons at session start for the relevant project

## 4. Verification Before Done

Never mark a task complete without proving it works. "It should work" is not acceptable.

- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness with evidence
- If you can't prove it works, it's not done

### Verify + Guard Pattern (autoresearch統合)

反復的な改善タスクでは、Verify（メトリクス改善）+ Guard（既存テスト通過）の二重検証を標準とする。

- **Verify**: 改善対象のメトリクスが向上したか（テストカバレッジ、パフォーマンス、エラー数等）
- **Guard**: 既存のテスト・ビルド・型チェックが通るか（リグレッション防止）
- **Auto-rollback**: commit → verify → guard失敗時は `git revert` で即座にロールバック。`git reset --hard` は使わない（実験履歴を残す）
- **判定ルール**:
  - Verify改善 + Guard通過 → Keep
  - Verify改善 + Guard失敗 → 実装を変えてリトライ（最大2回）、それでも失敗 → Revert
  - Verify変化なし/悪化 → Revert
- メトリクス駆動の改善には `/autoresearch` を使用する

## 5. Demand Elegance (Balanced)

For non-trivial changes, pause and ask "is there a more elegant way?" before committing to an approach.

- If a fix feels hacky, step back: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes — don't over-engineer straightforward changes
- Challenge your own work before presenting it to the user

## 6. Autonomous Bug Fixing

When given a bug report: just fix it. Don't ask for hand-holding or unnecessary clarification.

- Point at logs, errors, failing tests — then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how
- The user reported the bug; your job is to make it disappear

---

## Task Management

Follow this workflow for every task:

1. **Plan First** — Write a plan to `tasks/todo.md` with checkable items (`- [ ]` format)
2. **Verify Plan** — Check in with the user before starting implementation
3. **Track Progress** — Mark items complete (`- [x]`) as you go
4. **Explain Changes** — Provide a high-level summary at each step so the user stays informed
5. **Document Results** — Add a review section to `tasks/todo.md` summarizing what was done
6. **Capture Lessons** — Update `tasks/lessons.md` after any corrections or mistakes

---

## Core Principles

These principles override all other considerations:

- **Simplicity First** — Make every change as simple as possible. Impact minimal code. The best solution is the one with the smallest footprint.
- **No Laziness** — Find root causes. No temporary fixes. Hold yourself to senior developer standards at all times.
- **Minimal Impact** — Changes should only touch what's necessary. Avoid introducing bugs by keeping the blast radius small.
