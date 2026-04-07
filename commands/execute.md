# /execute — 다음 작업 실행

> STATE.md에서 현재 위치를 파악하고 서브에이전트를 spawn하여 다음 작업을 실행한다.

---

## 실행 조건

```
STATE.md 없으면 → "/init을 먼저 실행하세요." 출력 후 종료
```

---

## Step 1: 현재 위치 파악

> 📋 [Orchestrator] STATE.md 확인 중...

STATE.md의 `current_plan`을 읽은 뒤, **반드시 파일시스템에서** 해당 plan의 SUMMARY 파일과 그 frontmatter `status`를 확인한다.

| 상태 | 분기 |
|------|------|
| plan 없음 (null/TBD) | → Step 2: Planner spawn |
| plan 있고 SUMMARY 없음 | → Step 3: Worker spawn |
| plan 있고 SUMMARY `status: pending-review` | → Step 4: Tester spawn |
| plan 있고 SUMMARY `status: passed` | → STATE.md를 다음 plan으로 업데이트 후 Step 3 |
| 페이즈 내 모든 plan SUMMARY `status: passed` | → "/phase-review를 실행하세요." 출력 후 종료 |
| 모든 페이즈 완료 | → "/verify-all을 실행하세요." 출력 후 종료 |
| STATE.md `status: blocked` | → 사용자에게 blocked 내용 출력 후 종료 |

> 📋 [Orchestrator] 현재 위치: Phase [N] Plan [M]

---

## Step 2: Planner spawn

> 📋 [Orchestrator] → Planner spawn 중...

프롬프트에 참조 파일 경로를 포함한다. `.planning/research/` 존재 시 해당 파일들을, 아니면 `PROJECT-INFO.md`를 명시.

```bash
claude -p "
프로젝트 루트: $(pwd)
Phase [N]의 Plan [M]을 작성하라.
읽어야 할 파일:
- ~/.claude/BACKEND_ARCHITECTURE.md
- .planning/ROADMAP.md
- [PROJECT-INFO.md 또는 research/ 내 FEATURES, PITFALLS, STACK, SUMMARY]
- .planning/phases/[phase]/CONTEXT.md (있으면)
- .planning/phases/[phase]/[이전]-SUMMARY.md (있으면)
결과를 .planning/phases/[phase]/[번호]-PLAN.md에 저장하라.
" \
  --systemPrompt "$(cat ~/.claude/agents/planner/CLAUDE.md)" \
  --allowedTools "View,Bash,Write" \
  --max-turns 30
```

> 📋 [Orchestrator] → Planner 완료.

PLAN 파일 존재 확인 후:

```
> 📋 [Orchestrator] Phase [N] Plan [M] 작성 완료 ✅

Tasks:
- Task 1: [제목]
- Task 2: [제목]

→ /execute를 다시 실행하면 Worker가 구현합니다.
```

STATE.md 업데이트: `status: planning`, `current_plan: [M]`

---

## Step 3: Worker spawn

### ⚠️ Worker spawn 전 STATE.md 업데이트 (필수)

Worker spawn 전에 반드시 STATE.md를 아래 내용으로 먼저 저장한다:
- `current_plan`: 실행할 plan 번호
- `status`: executing
- `retry_count`: 0 (없으면 추가)
- `last_updated`: 현재 시각

이후 Worker를 spawn한다.

> 📋 [Orchestrator] → Worker spawn 중...

```bash
claude -p "
프로젝트 루트: $(pwd)
아래 plan을 실행하라:
- .planning/phases/[phase]/[번호]-PLAN.md
⚠️ git add, git commit, git push 절대 실행하지 마라.
완료 후 PLAN의 <output> 태그에 명시된 경로에 구현 완료 항목 SUMMARY 초안을 저장하라 (status: pending-review).
완료 보고(WORKER REPORT)를 stdout에도 출력하라.
" \
  --systemPrompt "$(cat ~/.claude/agents/worker/CLAUDE.md)" \
  --allowedTools "View,Bash,Write,Edit" \
  --max-turns 50
```

> 📋 [Orchestrator] → Worker 완료. Tester 검증으로 이어집니다.

**Worker 완료 후 바로 Step 4 Tester spawn으로 이동한다. 개발자 커밋을 기다리지 않는다.**

---

## Step 4: Tester spawn

> 📋 [Orchestrator] → Tester spawn 중...

```bash
claude -p "
프로젝트 루트: $(pwd)
아래 plan 기준으로 검증하라:
- .planning/phases/[phase]/[번호]-PLAN.md
SUMMARY 파일이 status: pending-review로 존재하면 읽어서 Worker 구현 내용을 파악한 뒤,
실제 검증(컴파일, 테스트, 수락 기준 체크)을 수행하라.
PASSED면 SUMMARY frontmatter의 status만 passed로 업데이트하라 (본문 내용 보존).
FAILED면 SUMMARY는 수정하지 않는다 (pending-review 유지).
결과는 stdout의 TESTER REPORT 형식으로 출력하라.
" \
  --systemPrompt "$(cat ~/.claude/agents/tester/CLAUDE.md)" \
  --allowedTools "View,Bash,Edit" \
  --max-turns 30
```

> 📋 [Orchestrator] → Tester 완료.

Tester stdout에서 `STATUS:` 라인을 파싱하여 분기:

**PASSED (`STATUS: PASSED`):**
```
> 📋 [Orchestrator] Phase [N] Plan [M] 검증: PASSED ✅

컴파일: ✅ | 테스트: ✅ (N tests) | 아키텍처: ✅

⚠️ 변경 내용을 확인하고 커밋해 주세요.
커밋 완료 후 /execute로 다음 plan을 진행하세요.
```
STATE.md:
- `status: waiting-commit`
- `retry_count: 0`
- `Session Continuity > Last session`: 현재 ISO timestamp (Bash tool로 `date -u +"%Y-%m-%dT%H:%M:%SZ"` 실행 결과 사용)
- `Session Continuity > Stopped at`: `Completed {phase-name} plan {XX}`

**여기서 종료. 개발자가 커밋한 후 다시 /execute를 호출한다.**

**FAILED (`STATUS: FAILED`) — 첫 번째 실패 (retry_count=0):**

STATE.md의 `retry_count`를 1로 업데이트 후 Step 5로 이동.

---

## Step 5: Worker 재수정 spawn (FAILED 1회)

> 📋 [Orchestrator] → Worker 재수정 spawn 중...

Tester stdout(TESTER REPORT)에서 ISSUES 항목을 파싱하여 Worker에게 전달한다.

```bash
claude -p "
프로젝트 루트: $(pwd)
Tester 검증에서 아래 항목이 실패했다. 수정하라:
[Tester stdout TESTER REPORT의 ISSUES 항목]

수정 대상 plan:
- .planning/phases/[phase]/[번호]-PLAN.md
⚠️ git add, git commit, git push 절대 실행하지 마라.
수정 완료 후 SUMMARY를 새 작업 내용으로 덮어쓰라 (status: pending-review).
" \
  --systemPrompt "$(cat ~/.claude/agents/worker/CLAUDE.md)" \
  --allowedTools "View,Bash,Write,Edit" \
  --max-turns 50
```

> 📋 [Orchestrator] → Worker 재수정 완료. Tester 재검증으로 이어집니다.

Step 4 Tester를 다시 spawn한다.

**재검증 결과:**

**PASSED**: Step 4 PASSED 처리와 동일. `retry_count: 0`으로 초기화.

**FAILED (retry_count=1)**: 개발자에게 보고 후 중단:
```
⚠️ [Orchestrator] Phase [N] Plan [M] — 2회 연속 FAILED ❌

실패 항목:
- [항목 1]
- [항목 2]

자동 재시도를 중단합니다. 수동으로 확인 후 /execute를 실행하면 Worker가 다시 시작합니다.
```
STATE.md: `status: blocked`, `retry_count: 0` (초기화)

---

## STATE.md 업데이트 체크리스트

```
□ frontmatter 갱신 (status, current_plan, retry_count, last_updated)
□ 본문 "현재 위치" 갱신 (frontmatter와 동기화)
□ "현재 페이즈 진행 현황" 테이블 갱신
□ "다음 작업" 갱신
□ Session Continuity > Last session 갱신 (Bash로 `date -u +"%Y-%m-%dT%H:%M:%SZ"` 실행 결과 사용)
□ Session Continuity > Stopped at 갱신
□ 기존 섹션 제목 언어 보존
□ 200줄 이내 확인
```

## status 값 정의

| status | 의미 |
|--------|------|
| `planning` | Planner 실행 중 또는 완료, Worker 미실행 |
| `executing` | Worker 실행 중 |
| `waiting-commit` | Tester PASSED, 개발자 커밋 대기 |
| `blocked` | 2회 연속 FAILED, 수동 확인 필요 |
