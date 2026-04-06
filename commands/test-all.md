# /test-all — 전체 테스트 실행

> Tester spawn으로 모든 테스트를 실행하고 결과를 보고한다.

---

## 실행

> 📋 [Orchestrator] → Tester spawn 중... (전체 테스트)

```bash
claude -p "
프로젝트 루트: $(pwd)
전체 테스트를 실행하고 결과를 보고하라.
1. Docker 필요 여부 확인 (TestContainers)
2. ./gradlew test
3. 패키지별 결과, 실패 상세 분석
결과를 표준 출력으로 보고하라.
" \
  --systemPrompt "$(cat ~/.claude/agents/tester/CLAUDE.md)" \
  --allowedTools "View,Bash" \
  --max-turns 20
```

---

## 결과

```
═══════════════════════════════════════
🧪 테스트 결과
═══════════════════════════════════════

■ 전체: ✅ PASSED / ❌ FAILED
  총: [N] | 성공: [N] | 실패: [N] | 스킵: [N]

■ 패키지별
  [패키지 1]: ✅ [N] tests
  [패키지 2]: ❌ [N] passed, [M] failed

■ 실패 상세 (있으면)
  1. [클래스]#[메서드]: [에러]

═══════════════════════════════════════
```

코드 수정 없음.
