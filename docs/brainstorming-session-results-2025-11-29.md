# Brainstorming Session Results

**Session Date:** 2025-11-29
**Facilitator:** Game Designer Samus Shepard
**Participant:** BMad

## Session Start

**접근 방식:** 게임 디자인 특화 브레인스토밍
**선택된 기법:** (진행 중 결정)

## Executive Summary

**Topic:** Love2D 카탄 클론 개발

**Session Goals:**
- 원작에 충실한 카탄 클론 개발
- 미니멀 아트 스타일 (리소스 최소화)

**TODO (나중에 고민할 것):**
- 싱글플레이어 AI 설계
- 모바일 UX 최적화
- 튜토리얼/온보딩

**Techniques Used:** Progressive Flow, Devil's Advocate, Risk Matrix, First Principles, Mind Mapping, Six Thinking Hats, SCAMPER, Pre-mortem Analysis, Decision Matrix, Five Whys

**Total Ideas Generated:** 50+

### Key Themes Identified:

1. **TDD 중심 개발** - 순수 로직 분리, 테스트 가능한 작은 단위
2. **확장 가능한 아키텍처** - Command 패턴 라이트, Player 추상화
3. **헥스 좌표계가 핵심** - Axial 저장, Cube 계산, 정규화 필수
4. **YAGNI 준수** - 인터페이스만 열어두기, 구현은 나중에

## Technique Sessions

### Topic 1: MVP 범위 정의

**Priority High (MVP 필수)**
- 🗺️ 헥스 타일 보드 (19개 타일, 랜덤 배치)
- 🎲 주사위 굴리기 & 자원 생산
- 🏠 정착지/도시/도로 건설
- 🏆 승리 조건 (10점)

**Priority Middle (2차 구현)**
- 🃏 개발 카드 (기사, 승점, 독점 등)
- 🏴‍☠️ 도둑 메커닉 (7 굴림)

**Priority Low (3차 구현)**
- 🔄 플레이어 간 자원 거래
- 🛡️ 최대 군대 / 🛤️ 최장 도로

**구현 순서:** High → Middle → Low

### Topic 2: 핵심 룰 구현 순서 (TDD 접근)

**원칙:** UI 없이 테스트 가능한 순수 로직부터, 작은 단위로 분해

**Phase 0: 환경 설정** 🆕
- Lua 테스트 프레임워크 선택 (busted 추천)
- 프로젝트 구조 설정
- (선택) 헥스 좌표 Spike 프로토타입

**Phase 1: 데이터 모델** (의존성 없음)
- 자원 타입 enum
- 건물 비용 정의
- 플레이어 자원 관리 (add/remove/has)
- 승리 점수 계산

**Phase 2a: 헥스 좌표 시스템** ⚠️ 고위험
- 좌표계 선택 (axial/cube/offset)
- 방향 및 이웃 계산
- 레퍼런스: Red Blob Games 헥스 가이드

**Phase 2b: 정점/변 계산**
- 인접 헥스 계산
- 정점(vertex) 위치 계산
- 변(edge) 위치 계산

**Phase 3: 보드 상태**
- 타일 배치 & 숫자 토큰
- 정점에 건물 배치
- 변에 도로 배치
- 특정 숫자의 타일 조회

**Phase 4a: 기본 턴 컨텍스트**
- 현재 플레이어 관리
- 턴 페이즈 상태

**Phase 4b: 건설 규칙 검증** ⚠️ 고위험
- 주사위 → 자원 분배 로직
- 건설 가능 위치 검증 (거리 규칙, 연결 규칙)
- 건설 실행 (자원 차감 + 배치)
- 승리 조건 체크

**Phase 4c: 초기 배치** (별도 규칙)
- 무료 건설
- 역순 배치
- 두 번째 정착지 자원 지급

**Phase 5: 일반 게임 플로우**
- 턴 순서 관리
- 페이즈 전이

**리스크 분석:**
- 🔴 헥스 좌표 시스템: 좌표계 혼란 가능 → 레퍼런스 문서 준비 (Red Blob Games)
- 🟠 배치 규칙 검증: 엣지케이스 많음 → 룰북 정밀 분석 필요

**병렬 개발 가능:**
- UI/렌더링은 Phase 3 이후부터 병렬 개발 가능

**병목 지점:**
- Phase 2a(헥스)가 병목 - 여기서 막히면 전체 지연
- 대응: Spike 프로토타입으로 좌표계 먼저 검증 권장

**의존성 체인 (Task 관리용):**
```
헥스 보드 → 주사위/자원 → 건설 → 승리조건
```
- 도둑: 보드 + 주사위
- 개발 카드: 자원
- 최대군대/최장도로: 건설 + 카드
- 거래: 자원 + UI

### Topic 3: 멀티플레이어 방식

**결정:** 하이브리드 접근
- MVP: 로컬 핫시트 (한 기기에서 턴 교대)
- 확장: 온라인 멀티플레이어까지 확장 가능한 구조

**아키텍처 원칙:**
- 게임 로직과 입력/렌더링 완전 분리 (TDD 필수)
- 상태 변경은 Command 패턴 "라이트" (단순 액션 테이블)
- 게임 상태는 직렬화 가능하게 설계 (세이브/로드에도 필요)
- "확장 가능" ≠ "확장 구현" - 인터페이스만 열어두기
- **Player 추상화:** Human/AI/Network 모두 동일 인터페이스

**입력 소스 통합:**
```
Human Input ──┐
              │
AI Engine   ──┼──▶ Action ──▶ Game State
              │
Network     ──┘
```

**Player 인터페이스:**
```lua
Player = {
  getAction = function(self, gameState)
    return action  -- Human: UI / AI: 알고리즘 / Network: 서버
  end
}
```

**Command 패턴 라이트 예시:**
```lua
local action = {
  type = "BUILD_SETTLEMENT",
  player = 1,
  vertex = {q=0, r=1, dir="N"},
  timestamp = os.time(),  -- 메타데이터: 리플레이/디버깅용
  source = "human",       -- 메타데이터: human/ai/network
  seq = game:nextSeq(),   -- 메타데이터: 액션 순서 보장
}
game:execute(action)  -- 모든 소스에서 동일하게 실행
```

**SCAMPER 아이디어 (확장점):**
| 아이디어 | 적용 시점 | 우선순위 |
|---------|----------|:--------:|
| 액션 히스토리 저장 (리플레이) | Phase 4 이후 | 중 |
| State → 가능한 Actions 목록 | AI 구현 시 | 중 |
| 액션 로그 → 튜토리얼 | 나중에 | 낮음 |
| Observer 타입 (관전) | 온라인 시 | 낮음 |

**리스크:**
- 🟠 상태 직렬화: Lua 테이블 순환참조 주의 → serpent/binser 라이브러리 사용
- 🟠 YAGNI 함정: 온라인 고려하다 MVP 지연 주의 → 확장점만 열어두기

**확장 시 고려사항 (나중에):**
- 상태 동기화
- 서버/클라이언트 분리
- 네트워크 지연 처리
- 재연결/복구

### Topic 4: 게임 상태 모델링

#### 4-1. 헥스 좌표계
**결정:** Axial 저장 + Cube 계산 + Pixel 렌더링

```
Storage: Axial (q, r)
    ↓ 변환
Calculation: Cube (x, y, z)  -- x + y + z = 0
    ↓ 변환
Rendering: Pixel (px, py)
```

**레퍼런스:** Red Blob Games - Hexagonal Grids

#### 4-2. 정점/변 표현
**결정:** 헥스 기준 + 방향 + 정규화

```lua
-- 정점: 헥스 + 방향 (N, S만 사용)
local vertex = {q = 0, r = 0, dir = "N"}

-- 변: 헥스 + 방향 (NE, E, SE만 사용)
local edge = {q = 0, r = 0, dir = "E"}
```

- 정규화 함수로 같은 위치의 다른 표현 통일
- 카탄 보드: 정점 54개, 변 72개

#### 4-3. 직렬화 구조
**원칙:** 순환 참조 X, 함수 X, ID로 참조

```lua
local gameState = {
  board = {
    tiles = {{q=0, r=0, terrain="forest", number=8}, ...},
    robber = {q = 0, r = 0},
  },
  -- buildings: Map 구조 (정규화 키 → O(1) 조회, 중복 방지)
  buildings = {
    settlements = {
      ["0,1,N"] = {player = 1},
      ["1,0,S"] = {player = 2},
    },
    cities = {},
    roads = {
      ["0,0,E"] = {player = 1},
    },
  },
  players = {
    {id=1, resources={wood=2, brick=1, sheep=0, wheat=1, ore=0}},
    ...
  },
  turn = {
    current = 1,
    phase = "build",  -- "roll", "build", "trade"
    rolled = 8,
    history = {prevRolls = {}},  -- 통계/리플레이용
  },
  actionSeq = 42,
}
```

**디버그 유틸리티 (Phase 2에서 구현):**
- `hexToString(q, r)` → "(0, 1)"
- `vertexToString(q, r, dir)` → "(0,1,N)"
- 시각화 도구로 좌표 검증

**검증:** Phase 3에서 serpent 직렬화 테스트 수행

**리스크:**
- 🔴 정점 정규화: 엣지케이스 많음 → TDD로 모든 케이스 커버

**나중에 고려:** robber를 board에서 최상위로 분리

### Topic 5: Love2D 기술 스택

#### 5-1. 라이브러리 선택

| 영역 | 선택 | 이유 |
|-----|------|------|
| 테스트 | `busted` | TDD 필수, BDD 스타일, 풍부한 기능 |
| 직렬화 | `serpent` | 디버깅 친화적, 읽기 쉬운 출력 |
| UI | 직접 구현 | 카탄 특수 UI (헥스 보드, 자원 카드) |
| 상태관리 | `hump.gamestate` | 검증됨, 간단 |
| 클래스 | `classic` | 단순, 단일 파일 |

#### 5-2. 프로젝트 구조

```
catan/
├── main.lua                 -- 엔트리포인트
├── conf.lua                 -- Love2D 설정
├── src/
│   ├── game/                -- 순수 게임 로직 (Love2D 의존 X)
│   │   ├── hex.lua          -- 헥스 좌표계, 변환
│   │   ├── board.lua        -- 보드 상태, 타일 배치
│   │   ├── vertex.lua       -- 정점 정규화, 인접 계산
│   │   ├── edge.lua         -- 변 정규화, 인접 계산
│   │   ├── player.lua       -- 플레이어 데이터, 자원 관리
│   │   ├── rules.lua        -- 건설 규칙, 승리 조건
│   │   ├── actions.lua      -- 액션 정의 (Command 패턴)
│   │   ├── state.lua        -- GameState 통합, 직렬화
│   │   └── constants.lua    -- 자원 타입, 건물 비용
│   ├── players/             -- 플레이어 타입
│   │   ├── base.lua         -- Player 인터페이스
│   │   ├── human.lua        -- Human 입력 처리
│   │   └── dummy_ai.lua     -- 테스트용 더미 AI
│   ├── ui/                  -- 렌더링 (Love2D 의존)
│   │   ├── renderer.lua     -- 메인 렌더러
│   │   ├── board_view.lua   -- 헥스 보드 그리기
│   │   ├── hud.lua          -- 자원, 점수 표시
│   │   ├── input.lua        -- 마우스/터치 → 헥스 변환
│   │   └── colors.lua       -- 색상 팔레트
│   ├── scenes/              -- 씬/상태
│   │   ├── menu.lua
│   │   ├── game.lua
│   │   └── game_over.lua
│   └── utils/               -- 유틸리티
│       ├── debug.lua        -- hexToString 등
│       └── serialize.lua    -- serpent 래퍼
├── lib/                     -- 외부 라이브러리
│   ├── classic.lua
│   ├── serpent.lua
│   └── hump/gamestate.lua
├── assets/                  -- 이미지, 폰트
└── tests/                   -- busted 테스트
    └── game/*_spec.lua
```

**핵심 원칙:**
- `src/game/`: Love2D 의존 없음 → 순수 Lua 테스트 가능
- `src/ui/`: Love2D 의존 → 렌더링만 담당
- 의존성: ui → game (단방향)

## Idea Categorization

### Immediate Opportunities (즉시 적용)

- 프로젝트 구조 생성 (Topic 5 기준)
- 라이브러리 설치: busted, serpent, classic, hump
- Phase 0 환경 설정: 테스트 프레임워크, 프로젝트 스캐폴딩
- (선택) 헥스 좌표 Spike 프로토타입

### During Development (개발 중 적용)

- TDD Phase 1~5 순차 진행
- Command 패턴 라이트 (액션 메타데이터 포함)
- Map 기반 buildings 구조
- Player 추상화 인터페이스
- 디버그 유틸리티 (hexToString 등)

### Future (나중에)

- 싱글플레이어 AI 설계/구현
- 모바일 UX 최적화
- 온라인 멀티플레이어
- 튜토리얼/온보딩
- robber 구조 분리 검토

### Insights and Learnings

1. **TDD와 Love2D는 궁합이 좋다**
   - 로직/렌더링 분리가 자연스러움
   - `src/game/`은 순수 Lua로 테스트 가능

2. **확장성은 "인터페이스만 열어두기"**
   - YAGNI 준수: 구현은 나중에
   - Command 패턴 라이트로 AI/Network 확장점 확보

3. **헥스 좌표계가 핵심 병목**
   - Phase 2a가 가장 위험
   - Red Blob Games 레퍼런스 필수
   - Spike 프로토타입 권장

4. **정규화가 복잡도의 원천**
   - 정점/변 정규화 버그 가능성 높음
   - TDD로 모든 케이스 커버 필수

## Action Planning

### Top 3 Priority Ideas

#### #1 Priority: Phase 0 - 환경 설정

- **Rationale:** 모든 것의 기반, TDD 시작점
- **Next steps:**
  1. 프로젝트 폴더 구조 생성
  2. busted 설치 및 테스트 실행 확인
  3. serpent, classic, hump 라이브러리 설치
  4. 첫 번째 더미 테스트 작성 및 통과
- **Resources needed:** luarocks, Love2D 설치

#### #2 Priority: Phase 1 - 데이터 모델

- **Rationale:** 가장 안전, 빠른 성공 경험, 의존성 없음
- **Next steps:**
  1. constants.lua - 자원 타입, 건물 비용 정의
  2. player.lua - 자원 관리 (add/remove/has)
  3. 각 단계마다 TDD (Red → Green → Refactor)
- **Resources needed:** 카탄 룰북 참조

#### #3 Priority: Phase 2a - 헥스 좌표 Spike

- **Rationale:** 고위험 병목 먼저 검증
- **Next steps:**
  1. Red Blob Games 헥스 가이드 정독
  2. Axial ↔ Cube ↔ Pixel 변환 함수 구현
  3. 이웃 헥스 계산 테스트
  4. 시각화로 검증 (선택)
- **Resources needed:** https://www.redblobgames.com/grids/hexagons/

## Reflection and Follow-up

### What Worked Well

- 5개 토픽 체계적으로 탐구 (MVP → TDD → 멀티플레이어 → 데이터 → 기술스택)
- Advanced Elicitation으로 깊이 있는 분석 (Devil's Advocate, Risk Matrix, SCAMPER 등)
- TDD 관점에서 Phase 분해 → 테스트 가능한 작은 단위
- 아키텍처 확장성 고려 (AI/Network 인터페이스 열어두기)

### Areas for Further Exploration

- 싱글플레이어 AI 알고리즘 (몬테카를로? 휴리스틱?)
- 모바일 터치 UX (헥스 선택, 줌/팬)
- 온라인 상태 동기화 상세 설계

### Recommended Follow-up

- **Option A:** Game Brief 작성 (이 브레인스토밍 기반으로 정식 문서화)
- **Option B:** 바로 Phase 0 구현 시작 (환경 설정)

### Key Questions for Future

- AI 난이도 조절은 어떻게?
- 멀티플랫폼 빌드 (PC/Mobile) 파이프라인은?
- 아트 에셋은 어디서? (미니멀이지만 최소한 필요)

---

_Session facilitated using the BMAD BMGD brainstorming framework_
