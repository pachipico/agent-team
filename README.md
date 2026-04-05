# Agent Team System

> GSD 벤치마킹 멀티 에이전트 시스템. 토큰 절약 + 일관된 산출물 + 개발자 Git 제어.

---

## 아키텍처

```
개발자
  ↕ 커맨드 (/init, /execute, ...)
메인 세션 (Orchestrator) ← 컨텍스트 30~40%
  │
  ├── claude -p (Researcher)  ← 초기화 시 1회 (research/ 없을 때만)
  ├── claude -p (Planner)     ← plan 작성
  ├── claude -p (Worker)      ← 코드 구현 (git 금지)
  └── claude -p (Tester)      ← 검증
```

---

## GSD 대비 차이점

| GSD | Agent Team | 절약 |
|-----|-----------|------|
| 5개 research 파일 | 1개 PROJECT-INFO.md (또는 기존 research/ 재활용) | 중복 제거 |
| 매 페이즈 research | 초기화 시 1회 | 반복 비용 0 |
| architecture.md 생성 | `BACKEND_ARCHITECTURE.md` 고정 참조 | 재분석 0 |
| 에이전트가 git 커밋 | **개발자 직접** 커밋/푸시/병합 | 제어권 유지 |

---

## GSD 호환

GSD로 이미 초기화된 프로젝트(`.planning/research/` 존재)에서도 동작한다:

- `FEATURES.md`, `PITFALLS.md`, `STACK.md`, `SUMMARY.md` → 참조 자료로 활용
- `ARCHITECTURE.md` → **사용하지 않음** (`~/.claude/BACKEND_ARCHITECTURE.md` 대체)
- `PROJECT-INFO.md` → 생성하지 않음 (research/ 파일로 대체)
- 기존 `STATE.md`의 영어 섹션 제목 → 영어 유지

---

## 파일 배치

```
~/.claude/
├── BACKEND_ARCHITECTURE.md    ← 아키텍처 가이드 (절대 참조)
└── agents/
    ├── researcher-CLAUDE.md
    ├── planner-CLAUDE.md
    ├── worker-CLAUDE.md
    └── tester-CLAUDE.md

[프로젝트]/
├── CLAUDE.md                  ← orchestrator-CLAUDE.md 내용
├── .claude/commands/
│   ├── init.md
│   ├── execute.md
│   ├── phase-review.md
│   ├── step-review.md
│   ├── status.md
│   ├── verify-all.md
│   └── test-all.md
└── .planning/
    ├── PROJECT.md
    ├── PROJECT-INFO.md        ← research/ 없을 때만
    ├── STATE.md
    ├── ROADMAP.md
    ├── research/              ← GSD 생성 시에만 존재
    │   ├── ARCHITECTURE.md    ← 참조 안 함
    │   ├── FEATURES.md        ← 참조
    │   ├── PITFALLS.md        ← 참조
    │   ├── STACK.md           ← 참조
    │   └── SUMMARY.md         ← 참조
    └── phases/
        ├── 01-[name]/
        │   ├── CONTEXT.md
        │   ├── 01-01-PLAN.md
        │   ├── 01-01-SUMMARY.md
        │   └── 01-VALIDATION.md
        └── 02-[name]/
```

**파일명 규칙:** 에이전트가 생성하는 모든 `.md`는 **대문자**.

---

## 커맨드

| 커맨드 | 역할 | spawn |
|--------|------|-------|
| `/init` | 프로젝트 초기화 | Researcher (research/ 없을 때) |
| `/execute` | 다음 작업 실행 | Planner / Worker / Tester |
| `/phase-review` | 페이즈 완료 검증 | Tester |
| `/step-review` | 현재 plan 상태 | 없음 (읽기 전용) |
| `/status` | 전체 현황 | 없음 (읽기 전용) |
| `/verify-all` | 전수 검증 | Tester |
| `/test-all` | 전체 테스트 | Tester |

### 사용 흐름

```
/init                     ← 최초 1회
  ↓
/execute                  ← Planner spawn → PLAN 작성
  ↓
/execute                  ← Worker spawn → 구현 → "커밋해 주세요"
  ↓
(개발자: git commit/push) ← 직접 커밋
  ↓
/execute                  ← Tester spawn → SUMMARY 작성
  ↓
  ... plan 반복 ...
  ↓
/phase-review             ← Tester spawn → VALIDATION
  ↓
  ... 페이즈 반복 ...
  ↓
/verify-all               ← 최종 전수 검증
```

### /execute 분기 로직

| STATE.md 상태 | spawn | 결과 |
|--------------|-------|------|
| plan 없음 | **Planner** | PLAN.md 생성 |
| plan 있고 SUMMARY 없음 | **Worker** | 코드 구현 → 커밋 대기 |
| Worker 완료 + 커밋됨 | **Tester** | SUMMARY.md 생성 |

Worker 완료 후 **개발자가 직접 커밋**해야 다음으로 진행.

---

## Git 흐름

```
Worker 구현 완료
  ↓
Orchestrator: 변경 파일 목록 + 권장 커밋 메시지 표시
  ↓
개발자:
  git add .
  git commit -m "feat(도메인): 설명"
  git push  (선택)
  ↓
/execute → Tester 검증
```

에이전트는 `git add/commit/push/merge` **절대 금지**.

---

## STATE.md 관리

- frontmatter와 본문 **항상 동기화**
- 업데이트 시 **전체 다시 쓰기**
- 기존 섹션 제목이 영어면 → **영어 유지**
- 200줄 이내, 최근 결정 5건 이내

---

## 컨텍스트 최적화

| 대상 | 보유량 |
|------|-------|
| Orchestrator (메인) | STATE.md + ROADMAP.md + CONTEXT.md (30~40%) |
| 서브에이전트 | 자기 작업 파일만 (매번 새 200k, 끝나면 소멸) |

| 파일 | 크기 제한 |
|------|----------|
| STATE.md | 200줄 |
| CONTEXT.md | 150줄 |
| PROJECT-INFO.md | 300줄 |

# README 패치: /close 커맨드 추가

> AGENT-TEAM-README.md의 커맨드 테이블과 사용 흐름에 아래 내용을 추가한다.

---

## 커맨드 테이블에 추가

```markdown
| `/close` | 세션 종료 + STATE.md 정리 | 없음 (읽기 + STATE 업데이트) |
```

## 사용 흐름 하단에 추가

```markdown
  ... 작업 중 ...
  ↓
/close                    ← 세션 종료. STATE.md 정리 + 다음 세션 안내
```

## 커맨드 상세에 추가

```markdown
### /close — 세션 종료

현재 작업 상태를 점검하고 STATE.md를 업데이트한다. 미커밋 변경이 있으면 안내한다. 
다음 세션에서 `/status` → `/execute`로 이어갈 수 있도록 "다음 작업" 섹션을 구체적으로 기록한다.
```

## commands/ 디렉토리에 추가

```
.claude/commands/
├── init.md
├── execute.md
├── phase-review.md
├── step-review.md
├── status.md
├── verify-all.md
├── test-all.md
└── close.md              ← 추가
```