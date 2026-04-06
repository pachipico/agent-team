# /phase-review — 페이즈 완료 검증

> 현재 페이즈 plan 완료 상태를 보고하고, 모든 plan 완료 시 Tester spawn으로 전수 검증.

---

## Step 1: 현황 보고

> 📋 [Orchestrator] Phase [N] 완료 상태를 확인합니다.

```
📋 Phase [N]: [이름]
목표: [ROADMAP의 목표]

| Plan | 제목 | 상태 |
|------|------|------|
| 01 | [제목] | ✅ passed |
| 02 | [제목] | ⏳ 미완료 |

완료: [M]/[N] plans
```

미완료 시 → "/execute로 남은 plan을 진행하세요." 종료.

---

## Step 2: Tester spawn (모든 plan passed)

> 📋 [Orchestrator] → Tester spawn 중... (전수 검증)

```bash
claude -p "
프로젝트 루트: $(pwd)
Phase [N] 전수 검증을 실행하라.
읽어야 할 파일:
- ~/.claude/BACKEND_ARCHITECTURE.md
- .planning/ROADMAP.md
- .planning/phases/[phase]/ 내 모든 SUMMARY 파일
결과를 .planning/phases/[phase]/[phase번호]-VALIDATION.md에 저장하라.
모드: phase_validation
" \
  --systemPrompt "$(cat ~/.claude/agents/tester/CLAUDE.md)" \
  --allowedTools "View,Bash,Write" \
  --max-turns 30
```

---

## Step 3: 결과

**PASSED:**
```
> 📋 [Orchestrator] Phase [N] — PASSED ✅
→ /execute로 Phase [N+1]을 시작하세요.
```
STATE.md 전체 다시 쓰기. 기존 섹션 제목 언어 보존.
섹션별 갱신 내용:
- frontmatter: `completed_phases +1`, `stopped_at: Phase {XX} ({name}) PASSED — Phase {XX+1} 시작 대기`, `status: planning`
- `Session Continuity > Last session`: 현재 ISO timestamp
- `Session Continuity > Stopped at`: `Phase {XX} ({name}) PASSED — Phase {XX+1} 시작 대기`
- `Pending Todos`: 완료된 phase 관련 항목 삭제, 다음 phase Todo 추가
- `Blockers/Concerns`: 해결된 항목 삭제
- `Performance Metrics > By Phase`: 완료된 phase 행 추가

**FAILED:**
```
> 📋 [Orchestrator] Phase [N] — FAILED ❌
실패: [내용]
→ 수정 후 /phase-review를 다시 실행하세요.
```
