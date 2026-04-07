# /step-review — 현재 Plan 상태 보고

> 읽기 전용. 현재 plan의 task별 상태를 보고한다.

---

## 실행

> 📋 [Orchestrator] Phase [N] Plan [M] 상태를 확인합니다.

읽기:
- `.planning/phases/[phase]/[번호]-PLAN.md`
- `.planning/phases/[phase]/[번호]-SUMMARY.md` (있으면)

---

## 출력

**SUMMARY 있음:**
```
📋 Phase [N] Plan [M]: [제목] — ✅ PASSED
| Task | 제목 | 수락 기준 | 결과 |
|------|------|----------|------|
| 1 | [제목] | [N]/[N] | ✅ |
→ /execute로 다음 plan 진행
```

**SUMMARY 없음, 코드 변경 있음 (git status로 확인):**
```
📋 Phase [N] Plan [M]: [제목] — 🔧 구현 완료, 커밋 대기
⚠️ /execute → Tester 검증 → 검증 완료 후 커밋
```

**PLAN만 있음:**
```
📋 Phase [N] Plan [M]: [제목] — ⏳ 미실행
| Task | 제목 | 파일 |
|------|------|------|
| 1 | [제목] | [경로] |
→ /execute → Worker 구현
```

파일 수정 없음.
