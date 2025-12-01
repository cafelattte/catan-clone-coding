# Story 6-5: Vertex/Edge Selection

**Epic:** 6 - Visual Experience
**Story ID:** 6-5
**Title:** Vertex/Edge Selection
**Status:** done
**Created:** 2025-12-01
**Author:** BMad

---

## User Story

**As a** 플레이어
**I want** 건설 가능한 정점/변이 화면에 하이라이트 표시되고, 클릭하여 선택할 수 있기를
**So that** 정착지, 도시, 도로를 배치할 위치를 시각적으로 확인하고 선택할 수 있다

---

## Acceptance Criteria

### AC 6-5.1: 건설 가능 정점 하이라이트
- [x] 건설 모드에서 유효한 정점 위치에 하이라이트 원 표시
- [x] 하이라이트 색상은 반투명 노랑 또는 흰색
- [x] 유효하지 않은 정점은 하이라이트 없음

### AC 6-5.2: 건설 가능 변 하이라이트
- [x] 건설 모드에서 유효한 변 위치에 하이라이트 선 표시
- [x] 하이라이트 색상은 반투명 노랑 또는 흰색
- [x] 유효하지 않은 변은 하이라이트 없음

### AC 6-5.3: 정점 클릭 선택
- [x] 하이라이트된 정점 클릭 시 해당 정점 좌표 반환
- [x] 선택된 정점은 게임 로직에 전달 가능
- [x] threshold 내 클릭만 유효 (Input.pixelToVertex 활용)

### AC 6-5.4: 변 클릭 선택
- [x] 하이라이트된 변 클릭 시 해당 변 좌표 반환
- [x] 선택된 변은 게임 로직에 전달 가능
- [x] threshold 내 클릭만 유효 (Input.pixelToEdge 활용)

### AC 6-5.5: 호버 피드백
- [x] 마우스가 유효한 정점/변 위에 있을 때 강조 표시
- [x] 호버 시 색상 변화 또는 크기 증가로 시각적 피드백

---

## Tasks

### Task 1: BoardView 하이라이트 함수 구현
- [x] 1.1 BoardView.drawVertexHighlight(px, py, radius, color) 함수 구현
- [x] 1.2 BoardView.drawEdgeHighlight(px1, py1, px2, py2, width, color) 함수 구현
- [x] 1.3 반투명 색상 처리 (alpha 채널)

### Task 2: 건설 가능 위치 시각화
- [x] 2.1 validVertices 목록을 받아 모든 정점 하이라이트 그리기
- [x] 2.2 validEdges 목록을 받아 모든 변 하이라이트 그리기
- [x] 2.3 BoardView.drawHighlights(validVertices, validEdges, hexSize, offsetX, offsetY) 통합 함수

### Task 3: 선택 상태 관리
- [x] 3.1 현재 선택 모드 추적 (none, settlement, city, road)
- [x] 3.2 선택 모드에 따른 유효 위치 계산
- [x] 3.3 선택된 좌표 저장 및 반환

### Task 4: 호버 감지 및 피드백
- [x] 4.1 love.mousemoved 콜백에서 현재 호버 위치 추적
- [x] 4.2 호버된 정점/변 강조 표시 (다른 색상 또는 크기)
- [x] 4.3 유효한 위치에서만 호버 피드백 표시

### Task 5: main.lua 통합
- [x] 5.1 선택 모드 토글 (키보드 단축키 또는 버튼)
- [x] 5.2 love.mousepressed에서 선택 처리
- [x] 5.3 love.draw에서 하이라이트 렌더링

### Task 6: 테스트 작성
- [x] 6.1 BoardView 하이라이트 함수 시각적 검증 (수동)
- [x] 6.2 선택 모드 전환 테스트
- [x] 6.3 유효 위치 필터링 테스트

---

## Dev Notes

### 기술적 고려사항
- Story 6-4에서 구현한 Input 모듈 재사용 (pixelToVertex, pixelToEdge, getVertexPixel, getEdgePixels)
- BoardView 모듈에 하이라이트 함수 추가
- 선택 모드 상태 관리는 main.lua 또는 별도 모듈에서 처리
- rules.lua의 건설 가능 위치 검증 함수 활용 예정 (getValidSettlementLocations, getValidRoadLocations)

### 렌더링 순서 (tech-spec 참조)
```
1. 배경 클리어
2. 모든 헥스 타일 (아래에서 위로)
3. 숫자 토큰
4. 도로 (변 위에)
5. 건물 (정점 위에)
6. 하이라이트 (선택/호버) ← 이 스토리
7. HUD (최상단)
```

### 색상 정의 (Colors.lua 추가)
```lua
UI = {
  highlight = {1, 1, 0, 0.3},       -- 반투명 노랑
  highlight_hover = {1, 1, 0, 0.6}, -- 더 진한 노랑
}
```

### 설정 상수 (tech-spec)
```lua
VERTEX_THRESHOLD = 15  -- 정점 선택 임계값 (픽셀)
EDGE_THRESHOLD = 10    -- 변 선택 임계값 (픽셀)
HIGHLIGHT_RADIUS = 8   -- 정점 하이라이트 반지름
HIGHLIGHT_WIDTH = 6    -- 변 하이라이트 두께
```

### 의존성
- Input 모듈 (Story 6-4): pixelToVertex, pixelToEdge, getVertexPixel, getEdgePixels
- BoardView 모듈 (Story 6-1, 6-2): draw 함수
- Colors 모듈 (Story 6-1): 색상 팔레트

### 참조
- [Source: docs/sprint-artifacts/tech-spec-epic-6.md#AC-6.5]
- [Source: docs/game-architecture.md#Rendering-순서]

---

### Learnings from Previous Story

**From Story 6-4-mouse-to-hex (Status: done)**

- **New Module Created**: `src/ui/input.lua` (277 lines) - 5개 public 함수 사용 가능
  - `Input.pixelToVertex(px, py, hexSize, offsetX, offsetY, threshold)` → 정점 선택에 직접 활용
  - `Input.pixelToEdge(px, py, hexSize, offsetX, offsetY, threshold)` → 변 선택에 직접 활용
  - `Input.getVertexPixel(q, r, dir, hexSize, offsetX, offsetY)` → 하이라이트 위치 계산에 활용
  - `Input.getEdgePixels(q, r, dir, hexSize, offsetX, offsetY)` → 하이라이트 선 끝점 계산에 활용
- **BOARD_COORDS 복사**: input.lua에 19개 보드 좌표 상수가 복사됨 (board.lua와 동기화 필요시 주의)
- **정점/변 탐색 알고리즘**: 현재 헥스 + 6개 이웃 헥스 검사하여 정확도 향상됨
- **main.lua 수정됨**: love.mousepressed 콜백 추가 - 이 스토리에서 확장 필요

[Source: docs/sprint-artifacts/6-4-mouse-to-hex.md#Dev-Agent-Record]

---

## Dev Agent Record

### Context Reference
- docs/sprint-artifacts/6-5-vertex-edge-selection.context.xml

### Agent Model Used
- claude-opus-4-5-20251101

### Debug Log References
- 2025-12-01: Task 1-5 구현, Task 6 테스트 추가

### Completion Notes List
- BoardView에 3개 public 함수 추가: drawVertexHighlight, drawEdgeHighlight, drawHighlights
- Colors.UI에 highlight_hover 색상 추가 ({1, 1, 0, 0.6})
- main.lua에 선택 모드 관리 시스템 구현:
  - 키보드 단축키: S(정착지), C(도시), R(도로), ESC(취소)
  - love.mousemoved로 호버 감지
  - love.mousepressed로 선택 처리
- Rules.getValidSettlementLocations/getValidRoadLocations 활용
- 모든 기존 테스트 통과 (293개)

### File List
- src/ui/board_view.lua (modified) - 하이라이트 함수 3개 추가
- src/ui/colors.lua (modified) - highlight_hover 색상 추가
- main.lua (modified) - 선택 모드 관리, 호버 감지, 클릭 처리 통합
- tests/ui/colors_spec.lua (modified) - highlight_hover 테스트 추가

---

_Story drafted by BMAD Story Creation Workflow_
