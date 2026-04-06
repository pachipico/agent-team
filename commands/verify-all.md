# /verify-all — 전수 검증

> 완료된 모든 페이즈를 Tester spawn으로 전수 검증한다.

---

## 실행

```
완료된 plan 없으면 → "검증할 작업이 없습니다." 종료
```

> 📋 [Orchestrator] → Tester spawn 중... (전수 검증)

```bash
claude -p "
프로젝트 루트: $(pwd)
완료된 모든 페이즈를 전수 검증하라.
읽어야 할 파일:
- ~/.claude/BACKEND_ARCHITECTURE.md
- .planning/ROADMAP.md
- .planning/PROJECT-INFO.md (또는 .planning/research/ 내 파일)
- .planning/phases/*/ 내 모든 SUMMARY, VALIDATION 파일
검증: 빌드, 테스트, 아키텍처, 성공 기준, git status
결과를 표준 출력으로 보고하라.
" \
  --systemPrompt "$(cat ~/.claude/agents/tester/CLAUDE.md)" \
  --allowedTools "View,Bash" \
  --max-turns 30
```

---

## 결과

```
═══════════════════════════════════════
🔍 전수 검증 결과
═══════════════════════════════════════

■ 빌드: ✅ / ❌
■ 테스트: ✅ (N tests) / ❌
■ 아키텍처: ✅ [N]/[N]
■ 성공 기준: Phase 1 ✅ | Phase 2 ✅
■ 미커밋: ✅ 없음 / ❌ 있음

최종: ✅ ALL PASSED / ❌ [N]건 실패
═══════════════════════════════════════
```

코드 수정 없음.
