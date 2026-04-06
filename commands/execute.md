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

STATE.md의 `current_plan`을 읽은 뒤, **반드시 파일시스템에서** 해당 plan의 SUMMARY 파일 존재 여부를 확인한다.

| 상태 | 분기 |
|------|------|
| plan 없음 (null/TBD) | → Step 2: Planner spawn |
| plan 있고 SUMMARY 없음 | → Step 3: Worker spawn |
| plan 있고 SUMMARY 있음 (STATE.md가 뒤처진 경우) | → STATE.md를 다음 plan으로 업데이트 후 Step 3 |
| 페이즈 내 모든 plan SUMMARY 완료 | → "/phase-review를 실행하세요." 출력 후 종료 |
| 모든 페이즈 완료 | → "/verify-all을 실행하세요." 출력 후 종료 |

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
- `last_updated`: 현재 시각

이후 Worker를 spawn한다.

> 📋 [Orchestrator] → Worker spawn 중...

```bash
claude -p "
프로젝트 루트: $(pwd)
아래 plan을 실행하라:
- .planning/phases/[phase]/[번호]-PLAN.md
⚠️ git add, git commit, git push 절대 실행하지 마라.
완료 후 생성/수정 파일 목록과 권장 커밋 메시지를 마지막에 출력하라.
" \
  --systemPrompt "$(cat ~/.claude/agents/worker/CLAUDE.md)" \
  --allowedTools "View,Bash,Write,Edit" \
  --max-turns 50
```

> 📋 [Orchestrator] → Worker 완료.

Worker의 출력에서 `═══ WORKER REPORT ═══` 블록을 파싱하여 개발자에게 전달:

```
> 📋 [Orchestrator] Phase [N] Plan [M] 구현 완료

생성된 파일:
- [파일 1]
- [파일 2]

수정된 파일:
- [파일 3]

검증: 컴파일 ✅ | 테스트 ✅

권장 커밋 메시지:
  feat([도메인]): [설명]

⚠️ 변경 내용을 확인하고 커밋해 주세요.
커밋 완료 후 /execute를 실행하면 Tester가 검증합니다.
```

STATE.md 업데이트: `status: executing`

**여기서 종료. 개발자가 커밋한 후 다시 /execute를 호출한다.**

---

## Step 4: Tester spawn (개발자 커밋 후)

개발자가 커밋 완료 후 `/execute`를 실행하면 이 단계로 온다.
(PLAN은 있고, SUMMARY는 없는 상태)

> 📋 [Orchestrator] → Tester spawn 중...

```bash
claude -p "
프로젝트 루트: $(pwd)
아래 plan 기준으로 검증하라:
- .planning/phases/[phase]/[번호]-PLAN.md
결과를 .planning/phases/[phase]/[번호]-SUMMARY.md에 저장하라.
" \
  --systemPrompt "$(cat ~/.claude/agents/tester/CLAUDE.md)" \
  --allowedTools "View,Bash,Write" \
  --max-turns 30
```

> 📋 [Orchestrator] → Tester 완료.

SUMMARY 파일을 읽고 보고:

**PASSED:**
```
> 📋 [Orchestrator] Phase [N] Plan [M] 검증: PASSED ✅

컴파일: ✅ | 테스트: ✅ (N tests) | 아키텍처: ✅

→ /execute로 다음 plan을 진행하세요.
```
STATE.md:
- `completed_plans_in_phase +1`, `current_plan` 다음, `status: planning`
- `Session Continuity > Last session`: 현재 ISO timestamp
- `Session Continuity > Stopped at`: `Completed {phase-name} plan {XX}` (예: `Completed 03-social-layer plan 06`)

**FAILED:**
```
> 📋 [Orchestrator] Phase [N] Plan [M] 검증: FAILED ❌

실패 항목:
- [내용]

→ 수정 후 /execute를 실행하면 Worker가 재실행됩니다.
```
STATE.md: `status: executing`

---

## STATE.md 업데이트 체크리스트

```
□ frontmatter 갱신
□ 본문 "현재 위치" 갱신 (frontmatter와 동기화)
□ "현재 페이즈 진행 현황" 테이블 갱신
□ "다음 작업" 갱신
□ Session Continuity > Last session 갱신 (현재 ISO timestamp)
□ Session Continuity > Stopped at 갱신 (Completed {phase-name} plan {XX})
□ 기존 섹션 제목 언어 보존
□ 200줄 이내 확인
```
