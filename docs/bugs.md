# Bug Tracking

## Open

- [ ] **BUG-002**: Setup 2라운드에서 settlement가 아닌 city를 배치해야 함

## In Progress

## Fixed

- [x] **BUG-001**: Settlement/City 배치 시 N 방향 vertex에만 배치 가능
  - 원인: `Vertex.getHexVertices()`와 `Vertex.getAdjacentEdges()`가 잘못된 좌표 반환
  - 수정: Pointy-top 헥스의 6개 꼭지점 및 인접 변 좌표를 픽셀 좌표 기반으로 검증 후 수정
  - 관련 파일: `src/game/vertex.lua`, `src/game/board.lua`

- [x] **BUG-003**: Setup 도로 배치 시 E 방향 edge 위치가 잘못됨
  - 원인: `Vertex.getAdjacentEdges()`에서 E 방향 변 좌표 오류
  - 수정: BUG-001 수정 시 함께 해결됨
