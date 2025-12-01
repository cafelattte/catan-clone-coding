# Settlus of Catan - Project Instructions

## 프로젝트 규칙

워크플로우 및 커밋 규칙은 `docs/WORKFLOW-RULES.md` 파일을 참조하세요.

**중요:** code-review 워크플로우에서 Approve 후 스토리를 `done`으로 변경할 때, 반드시 `docs/WORKFLOW-RULES.md`의 커밋 규칙에 따라 git commit을 생성해야 합니다.

## 기술 스택

- Lua + Love2D (게임 엔진)
- busted (테스트 프레임워크)
- BMAD Method (개발 워크플로우)

## 프로젝트 구조

- `src/game/` - 순수 Lua 게임 로직 (Love2D 의존 없음)
- `src/ui/` - Love2D 의존 UI 모듈
- `tests/` - busted 테스트
- `docs/` - 문서 및 스프린트 아티팩트
