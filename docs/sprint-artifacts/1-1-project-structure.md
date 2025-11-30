# Story 1.1: 프로젝트 구조 생성

Status: done

## Story

As a 개발자,
I want 표준화된 프로젝트 디렉토리 구조를,
so that 모든 코드가 일관된 위치에 정리됨.

## Acceptance Criteria

1. **AC1: 소스 디렉토리** - 다음 디렉토리가 존재해야 함:
   - `src/game/` - 순수 게임 로직 (Love2D 의존 X)
   - `src/players/` - 플레이어 타입 (Human, AI 확장점)
   - `src/ui/` - 렌더링 (Love2D 의존)
   - `src/scenes/` - 씬/상태 관리
   - `src/utils/` - 유틸리티

2. **AC2: 지원 디렉토리** - 다음 디렉토리가 존재해야 함:
   - `lib/` - 외부 라이브러리
   - `lib/hump/` - hump 라이브러리 서브폴더
   - `tests/game/` - busted 테스트 파일
   - `assets/images/` - 이미지 에셋
   - `assets/fonts/` - 폰트 에셋

3. **AC3: 엔트리포인트** - 프로젝트 루트에 다음 파일 존재:
   - `main.lua` - Love2D 메인 엔트리포인트
   - `conf.lua` - Love2D 설정 파일

4. **AC4: 테스트 설정** - `.busted` 설정 파일이 프로젝트 루트에 존재

## Tasks / Subtasks

- [x] **Task 1: 디렉토리 구조 생성** (AC: 1, 2)
  - [x] src/ 하위 디렉토리 생성 (game, players, ui, scenes, utils)
  - [x] lib/ 및 lib/hump/ 디렉토리 생성
  - [x] tests/game/ 디렉토리 생성
  - [x] assets/ 하위 디렉토리 생성 (images, fonts)

- [x] **Task 2: main.lua 생성** (AC: 3)
  - [x] 기본 Love2D 콜백 구조 작성 (love.load, love.update, love.draw)
  - [x] 빈 구현으로 시작 (placeholder)

- [x] **Task 3: conf.lua 생성** (AC: 3)
  - [x] 창 설정: 1280x720, 타이틀 "Settlus of Catan"
  - [x] Love2D 버전: 11.5
  - [x] 콘솔 출력 활성화 (디버그용)

- [x] **Task 4: .busted 설정 파일 생성** (AC: 4)
  - [x] lpath 설정: src/ 및 lib/ 경로 포함
  - [x] ROOT 설정: tests/ 디렉토리

- [x] **Task 5: 검증**
  - [x] 모든 디렉토리 존재 확인 (ls -la)
  - [x] main.lua, conf.lua 파일 존재 확인
  - [x] .busted 파일 존재 확인

## Dev Notes

### Architecture Alignment

이 스토리는 Architecture 문서의 **Project Structure** 섹션을 직접 구현합니다.

**핵심 원칙:**
- `src/game/`은 Love2D 의존성 없이 순수 Lua로 구현 (ADR-001)
- `src/ui/`만 Love2D에 의존
- 단방향 의존: ui → game (역방향 불가)

**디렉토리 역할:**

| 디렉토리 | 책임 | Love2D 의존 |
|---------|------|:-----------:|
| src/game/ | 순수 게임 로직, 데이터 모델 | X |
| src/players/ | Human/AI 플레이어 인터페이스 | X |
| src/ui/ | 렌더링, 입력 처리 | O |
| src/scenes/ | 씬 전환 (menu, game, game_over) | O |
| src/utils/ | 디버그, 직렬화 유틸리티 | 혼합 |

### conf.lua 상세

```lua
function love.conf(t)
  t.window.title = "Settlus of Catan"
  t.window.width = 1280
  t.window.height = 720
  t.window.resizable = false
  t.version = "11.5"
  t.console = true  -- Windows에서 콘솔 창 활성화
end
```

### main.lua 상세

```lua
function love.load()
  -- 초기화 (나중에 구현)
end

function love.update(dt)
  -- 업데이트 로직 (나중에 구현)
end

function love.draw()
  -- 렌더링 (나중에 구현)
  love.graphics.print("Settlus of Catan - Foundation", 10, 10)
end
```

### .busted 상세

```lua
return {
  _all = {
    coverage = false,
    lpath = "src/?.lua;src/?/init.lua;lib/?.lua",
  },
  default = {
    verbose = true,
    ROOT = {"tests/"},
  },
}
```

### Project Structure Notes

- Architecture 문서의 Project Structure와 100% 일치
- docs/ 디렉토리는 이미 존재 (워크플로우 산출물)
- 향후 스토리에서 각 디렉토리에 실제 모듈 추가

### References

- [Source: docs/game-architecture.md#Project-Structure]
- [Source: docs/sprint-artifacts/tech-spec-epic-1.md#Detailed-Design]
- [Source: docs/epics.md#Story-1.1]

## Dev Agent Record

### Context Reference

- [Story Context XML](1-1-project-structure.context.xml)

### Agent Model Used

Claude Opus 4.5 (claude-opus-4-5-20251101)

### Debug Log References

- 2025-11-30: Task 1-5 순차 실행, 모든 AC 검증 완료

### Completion Notes List

- Architecture 문서의 Project Structure와 100% 일치하는 디렉토리 구조 생성
- Love2D 11.5 기준 conf.lua 설정 (1280x720, 타이틀 "Settlus of Catan")
- main.lua에 기본 콜백 구조 (love.load, love.update, love.draw) 구현
- .busted 설정으로 src/, lib/ 경로 및 tests/ ROOT 설정 완료
- 모든 Acceptance Criteria (AC1-AC4) 충족 확인

### File List

**생성된 디렉토리:**
- src/game/
- src/players/
- src/ui/
- src/scenes/
- src/utils/
- lib/
- lib/hump/
- tests/game/
- assets/images/
- assets/fonts/

**생성된 파일:**
- main.lua (Love2D 엔트리포인트)
- conf.lua (Love2D 설정)
- .busted (busted 테스트 설정)

## Change Log

- 2025-11-30: Story implemented (dev-story workflow)
- 2025-11-30: Senior Developer Review notes appended

---

## Senior Developer Review (AI)

### Reviewer
BMad (Claude Opus 4.5)

### Date
2025-11-30

### Outcome
✅ **APPROVE**

모든 Acceptance Criteria가 구현되었고, 모든 Task가 검증되었습니다. 아키텍처 제약사항을 준수하며, 코드 품질이 양호합니다.

### Summary
Story 1.1은 Settlus of Catan 프로젝트의 기초 디렉토리 구조와 설정 파일을 성공적으로 생성했습니다. Love2D 11.5 환경에 맞는 표준 프로젝트 구조가 확립되었습니다.

### Key Findings
없음 - 모든 요구사항 충족

### Acceptance Criteria Coverage

| AC# | Description | Status | Evidence |
|-----|-------------|--------|----------|
| AC1 | 소스 디렉토리 | ✅ IMPLEMENTED | src/game/, players/, ui/, scenes/, utils/ |
| AC2 | 지원 디렉토리 | ✅ IMPLEMENTED | lib/, lib/hump/, tests/game/, assets/images/, assets/fonts/ |
| AC3 | 엔트리포인트 | ✅ IMPLEMENTED | main.lua:1-12, conf.lua:1-8 |
| AC4 | 테스트 설정 | ✅ IMPLEMENTED | .busted:1-10 |

**Summary**: 4 of 4 acceptance criteria fully implemented

### Task Completion Validation

| Task | Marked As | Verified As | Evidence |
|------|-----------|-------------|----------|
| Task 1: 디렉토리 구조 | [x] | ✅ VERIFIED | ls 명령어로 확인 |
| Task 2: main.lua | [x] | ✅ VERIFIED | main.lua:1-12 |
| Task 3: conf.lua | [x] | ✅ VERIFIED | conf.lua:1-8 |
| Task 4: .busted | [x] | ✅ VERIFIED | .busted:1-10 |
| Task 5: 검증 | [x] | ✅ VERIFIED | 리뷰에서 재검증 |

**Summary**: 16 of 16 completed tasks verified, 0 questionable, 0 falsely marked complete

### Test Coverage and Gaps
- 이 스토리는 인프라 설정으로, 별도의 자동화 테스트 불필요
- Story 1.3에서 busted 테스트 환경 검증 예정

### Architectural Alignment
- ✅ ADR-001 준수: src/game/은 Love2D 의존 없음
- ✅ 단방향 의존 구조 (ui → game) 준비됨
- ✅ Architecture 문서의 Project Structure와 100% 일치

### Security Notes
N/A - 인프라 설정만 포함, 보안 관련 코드 없음

### Best-Practices and References
- [Love2D Wiki - Config Files](https://love2d.org/wiki/Config_Files)
- [busted Documentation](https://lunarmodules.github.io/busted/)

### Action Items

**Code Changes Required:**
없음

**Advisory Notes:**
- Note: Story 1.2에서 classic, serpent, hump 라이브러리 설치 시 lib/ 디렉토리 활용
- Note: 실제 테스트 코드는 Story 1.3에서 작성 예정
