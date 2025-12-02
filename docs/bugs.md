# Bug Tracking

## Open

## In Progress

## Fixed

- [x] **BUG-005**: 자원 획득 후 Road 건설 버튼 클릭 시 크래시
  - 원인: `handleButtonClick`(276줄)이 `updateValidLocations`(362줄)를 호출하는데, 둘 다 `local function`으로 정의되어 Lua의 forward reference 문제 발생
  - 수정: 파일 상단에 forward declaration 추가 (`local getSetupRoadLocations`, `local updateValidLocations`)
  - 관련 파일: `src/scenes/game.lua`

- [x] **BUG-004**: 건설 가능 위치 검증 함수 결함 - 초기 배치에서 인접 vertex에도 건설 가능 (거리 규칙 미적용)
  - 원인: BUG-001 좌표 체계 변경의 여파로 여러 함수가 불일치
  - 수정 내용:
    1. `Vertex.getAdjacentVertices()`: Edge 기반으로 재작성
    2. `Vertex.getAdjacentHexes()`: 인접 헥스 좌표 수정 ((-1,0) → (1,-1), (1,0) → (-1,1))
    3. `Edge.getAdjacentEdges()`: Vertex.getAdjacentEdges 기반으로 재작성
  - 관련 파일: `src/game/vertex.lua`, `src/game/edge.lua`
  - 검증: 좌표 시스템 교차 검증 테스트 추가 (`tests/game/vertex_spec.lua`)

- [x] **BUG-002**: Setup 2라운드에서 settlement가 아닌 city를 배치해야 함
  - 결론: Invalid - Cities & Knights 확장판 규칙 혼동, 기본 카탄은 Round 2도 settlement 배치가 정상

- [x] **BUG-001**: Settlement/City 배치 시 N 방향 vertex에만 배치 가능
  - 원인: `Vertex.getHexVertices()`와 `Vertex.getAdjacentEdges()`가 잘못된 좌표 반환
  - 수정: Pointy-top 헥스의 6개 꼭지점 및 인접 변 좌표를 픽셀 좌표 기반으로 검증 후 수정
  - 관련 파일: `src/game/vertex.lua`, `src/game/board.lua`

- [x] **BUG-003**: Setup 도로 배치 시 E 방향 edge 위치가 잘못됨
  - 원인: `Vertex.getAdjacentEdges()`에서 E 방향 변 좌표 오류
  - 수정: BUG-001 수정 시 함께 해결됨
