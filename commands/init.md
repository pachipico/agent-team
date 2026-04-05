# /init — 프로젝트 초기화

> .planning/ 디렉토리를 확인하고 프로젝트를 초기화한다.

---

## 실행 조건

```
1. .planning/STATE.md 존재 확인
   → 존재하면: "이미 초기화된 프로젝트입니다. /status로 상태를 확인하세요." 출력 후 종료
2. .planning/ 디렉토리 존재 여부 확인
   → 존재하지 않으면: 전체 초기화 (Step 1~6)
   → 존재하고 research/ 있으면: GSD 호환 초기화 (Step 1, 2, 4, 5, 6 — Researcher 스킵)
```

---

## Step 1: 개발자 인터뷰

> 📋 [Orchestrator] 프로젝트 초기화를 시작합니다.

2~3개씩 자연스럽게 질문:
- 핵심 가치/목적, MVP 범위, Out of Scope, 팀 구성, 배포 환경, 외부 API, 제약사항

코드에서 파악 가능한 것은 묻지 않는다.

---

## Step 2: PROJECT.md 작성

> 📋 [Orchestrator] PROJECT.md 작성 중...

`.planning/PROJECT.md` 생성.

---

## Step 3: 프로젝트 분석 (research/ 없을 때만)

`.planning/research/` 디렉토리 존재 여부를 확인한다.

**research/ 존재:**
```
> 📋 [Orchestrator] GSD research 디렉토리 발견. Researcher 스킵.
> 📋 [Orchestrator] 참조 파일: FEATURES.md, PITFALLS.md, STACK.md, SUMMARY.md
> 📋 [Orchestrator] (ARCHITECTURE.md는 ~/.claude/BACKEND_ARCHITECTURE.md로 대체)
```
→ Step 4로 이동. PROJECT-INFO.md 생성하지 않음.

**research/ 미존재:**
```
> 📋 [Orchestrator] → Researcher spawn 중...
```

```bash
claude -p "
프로젝트 루트: $(pwd)
.planning/PROJECT.md를 참고하여 프로젝트를 분석하고
.planning/PROJECT-INFO.md를 생성하라.
" \
  --systemPrompt "$(cat ~/.claude/agents/researcher-CLAUDE.md)" \
  --allowedTools "View,Bash,Write" \
  --max-turns 30
```

> 📋 [Orchestrator] → Researcher 완료. PROJECT-INFO.md 확인 중...

---

## Step 4: ROADMAP.md 작성

> 📋 [Orchestrator] ROADMAP.md 작성 중...

**작성 기준:**
- 페이즈 수: **3~6개** (7개 이상 금지)
- 페이즈당 plan 수: 3~6개
- plan당 task 수: 2~4개

기존 `.planning/ROADMAP.md`가 이미 있으면 (GSD가 생성한 경우) 내용을 확인하고, 필요시 개발자에게 수정 여부를 물어본다.

---

## Step 5: STATE.md 초기화

> 📋 [Orchestrator] STATE.md 초기화 중...

`.planning/STATE.md` 생성. `.planning/phases/` 디렉토리도 생성.

기존 STATE.md가 있으면 (GSD가 생성한 경우) 섹션 제목의 언어를 확인하고 유지한다.

---

## Step 6: 완료 보고

```
> 📋 [Orchestrator] 프로젝트 초기화 완료 ✅

생성된 파일:
- .planning/PROJECT.md
- .planning/PROJECT-INFO.md (또는 "research/ 기존 파일 활용")
- .planning/ROADMAP.md
- .planning/STATE.md

다음: /execute 로 Phase 1 첫 번째 plan을 시작하세요.
```
