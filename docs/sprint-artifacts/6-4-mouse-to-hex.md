# Story 6-4: Mouse to Hex Conversion

**Epic:** 6 - Visual Experience
**Story ID:** 6-4
**Title:** Mouse to Hex Conversion
**Status:** review
**Created:** 2025-12-01
**Author:** BMad

---

## User Story

**As a** 플레이어
**I want** 마우스 클릭 위치가 헥스/정점/변 좌표로 변환되기를
**So that** 보드에서 원하는 위치를 선택하여 건물을 배치할 수 있다

---

## Acceptance Criteria

### AC 6-4.1: 헥스 좌표 변환
- [x] 픽셀 좌표를 헥스 (q, r) 좌표로 변환하는 함수 구현
- [x] 보드 내 클릭 시 올바른 헥스 좌표 반환
- [x] 보드 외부 클릭 시 nil 반환

### AC 6-4.2: 정점 좌표 변환
- [x] 픽셀 좌표를 가장 가까운 정점 (q, r, dir) 좌표로 변환
- [x] threshold(임계값) 내 클릭 시 정점 좌표 반환
- [x] threshold 외부 클릭 시 nil 반환

### AC 6-4.3: 변 좌표 변환
- [x] 픽셀 좌표를 가장 가까운 변 (q, r, dir) 좌표로 변환
- [x] threshold 내 클릭 시 변 좌표 반환
- [x] threshold 외부 클릭 시 nil 반환

### AC 6-4.4: 정점/변 픽셀 좌표 계산
- [x] 정점 좌표 (q, r, dir)를 픽셀 좌표로 변환하는 함수 구현
- [x] 변 좌표 (q, r, dir)를 양 끝점 픽셀 좌표로 변환하는 함수 구현

### AC 6-4.5: 디버그 출력
- [x] 클릭 시 콘솔에 변환된 좌표 출력 (개발용)

---

## Tasks

### Task 1: Input 모듈 생성
- [x] 1.1 src/ui/input.lua 파일 생성
- [x] 1.2 hex.lua 의존성 추가 (cubeToPixel, pixelToCube)
- [x] 1.3 vertex.lua 의존성 추가 (정점 정규화)
- [x] 1.4 edge.lua 의존성 추가 (변 정규화)

### Task 2: pixelToHex 함수 구현
- [x] 2.1 pixelToHex(px, py, hexSize, offsetX, offsetY) 함수 구현
- [x] 2.2 hex.pixelToCube 활용하여 큐브 좌표 변환
- [x] 2.3 큐브 좌표를 axial 좌표로 변환하여 반환
- [x] 2.4 보드 범위 체크 (선택적, 19개 헥스 내)

### Task 3: pixelToVertex 함수 구현
- [x] 3.1 pixelToVertex(px, py, hexSize, offsetX, offsetY, threshold) 함수 구현
- [x] 3.2 가장 가까운 헥스의 6개 정점과 거리 계산
- [x] 3.3 threshold 내 가장 가까운 정점 반환
- [x] 3.4 vertex.normalize로 정규화된 좌표 반환

### Task 4: pixelToEdge 함수 구현
- [x] 4.1 pixelToEdge(px, py, hexSize, offsetX, offsetY, threshold) 함수 구현
- [x] 4.2 가장 가까운 헥스의 6개 변과 거리 계산 (점-선분 거리)
- [x] 4.3 threshold 내 가장 가까운 변 반환
- [x] 4.4 edge.normalize로 정규화된 좌표 반환

### Task 5: 좌표→픽셀 변환 함수
- [x] 5.1 getVertexPixel(q, r, dir, hexSize, offsetX, offsetY) 구현
- [x] 5.2 getEdgePixels(q, r, dir, hexSize, offsetX, offsetY) 구현
- [x] 5.3 hex.cubeToPixel 활용하여 정점/변 끝점 계산

### Task 6: main.lua 통합
- [x] 6.1 Input 모듈 require
- [x] 6.2 love.mousepressed 콜백에서 좌표 변환 테스트
- [x] 6.3 디버그 출력으로 변환 결과 표시

### Task 7: 테스트 작성
- [x] 7.1 tests/ui/input_spec.lua 생성
- [x] 7.2 pixelToHex 테스트 (중앙, 경계, 외부)
- [x] 7.3 pixelToVertex 테스트 (근접, threshold 내외)
- [x] 7.4 pixelToEdge 테스트 (근접, threshold 내외)
- [x] 7.5 getVertexPixel, getEdgePixels 테스트

---

## Dev Notes

### 기술적 고려사항
- hex.lua의 pixelToCube, cubeToPixel 함수 재활용
- vertex.lua의 normalize 함수로 정점 정규화
- edge.lua의 normalize 함수로 변 정규화
- Pointy-top 헥스 레이아웃 기준

### 정점 방향 (dir)
- "N": 북쪽 정점 (위)
- "S": 남쪽 정점 (아래)

### 변 방향 (dir)
- "E": 동쪽 변
- "SE": 남동쪽 변
- "SW": 남서쪽 변

### 참조 설정값 (tech-spec)
```lua
HEX_SIZE = 50
BOARD_OFFSET_X = 640
BOARD_OFFSET_Y = 360
VERTEX_THRESHOLD = 15
EDGE_THRESHOLD = 10
```

### 좌표 변환 공식 참조
- hex.lua:pixelToCube - 픽셀 → 큐브 좌표
- hex.lua:cubeToPixel - 큐브 좌표 → 픽셀
- vertex.normalize - 정점 정규화 (N/S)
- edge.normalize - 변 정규화 (E/SE/SW)

---

## Dev Agent Record

### Context Reference
- docs/sprint-artifacts/6-4-mouse-to-hex.context.xml

### Implementation Notes
- Input 모듈 생성: src/ui/input.lua (265 lines)
- 5개 public 함수: pixelToHex, pixelToVertex, pixelToEdge, getVertexPixel, getEdgePixels
- 보드 범위 체크를 위해 BOARD_COORDS 상수 복사 (board.lua와 동기화 필요시 주의)
- 점-선분 거리 계산 알고리즘 구현 (pointToSegmentDistance 로컬 함수)
- 정점/변 탐색 시 현재 헥스 + 6개 이웃 헥스 검사하여 정확도 향상
- 292개 테스트 모두 통과 (기존 274개 + 신규 18개)

### File List
- src/ui/input.lua (신규)
- main.lua (수정)
- tests/ui/input_spec.lua (신규)

---

## Senior Developer Review (AI)

**Reviewer:** BMad
**Date:** 2025-12-01
**Outcome:** ✅ **Approve**

### Summary
Story 6-4 Mouse to Hex Conversion 구현이 완료되었습니다. Input 모듈이 모든 요구사항을 충족하며, 5개 public 함수(pixelToHex, pixelToVertex, pixelToEdge, getVertexPixel, getEdgePixels)가 정상 동작합니다. 292개 테스트 모두 통과.

### Acceptance Criteria Coverage

| AC | Description | Status | Evidence |
|----|-------------|--------|----------|
| 6-4.1.1 | 픽셀→헥스 변환 함수 | ✅ | src/ui/input.lua:135-152 |
| 6-4.1.2 | 보드 내 클릭 시 좌표 반환 | ✅ | src/ui/input.lua:147-151 |
| 6-4.1.3 | 보드 외부 nil 반환 | ✅ | src/ui/input.lua:147-148 |
| 6-4.2.1 | 픽셀→정점 변환 | ✅ | src/ui/input.lua:164-213 |
| 6-4.2.2 | threshold 내 정점 반환 | ✅ | src/ui/input.lua:205-208 |
| 6-4.2.3 | threshold 외부 nil | ✅ | src/ui/input.lua:206-208 |
| 6-4.3.1 | 픽셀→변 변환 | ✅ | src/ui/input.lua:225-274 |
| 6-4.3.2 | threshold 내 변 반환 | ✅ | src/ui/input.lua:266-268 |
| 6-4.3.3 | threshold 외부 nil | ✅ | src/ui/input.lua:267-268 |
| 6-4.4.1 | 정점→픽셀 변환 | ✅ | src/ui/input.lua:95-107 |
| 6-4.4.2 | 변→픽셀 변환 | ✅ | src/ui/input.lua:119-124 |
| 6-4.5.1 | 디버그 출력 | ✅ | main.lua:98-131 |

**Summary: 12 of 12 acceptance criteria fully implemented**

### Task Completion Validation

| Task | Verified | Evidence |
|------|----------|----------|
| 1.1-1.4 Input 모듈 생성 | ✅ | src/ui/input.lua:1-8 |
| 2.1-2.4 pixelToHex 구현 | ✅ | src/ui/input.lua:135-152 |
| 3.1-3.4 pixelToVertex 구현 | ✅ | src/ui/input.lua:164-213 |
| 4.1-4.4 pixelToEdge 구현 | ✅ | src/ui/input.lua:225-274 |
| 5.1-5.3 좌표→픽셀 변환 | ✅ | src/ui/input.lua:95-124 |
| 6.1-6.3 main.lua 통합 | ✅ | main.lua:7, 98-131 |
| 7.1-7.5 테스트 작성 | ✅ | tests/ui/input_spec.lua (18 tests) |

**Summary: 27 of 27 completed tasks verified, 0 falsely marked complete**

### Test Coverage
- 신규 테스트: 18개 (tests/ui/input_spec.lua)
- 전체 테스트: 292개 통과
- 커버리지: pixelToHex, pixelToVertex, pixelToEdge, getVertexPixel, getEdgePixels 모두 테스트됨

### Architectural Alignment
- ✅ src/ui/ → src/game/ 단방향 의존성 준수
- ✅ Pointy-top 헥스 레이아웃 (tech-spec 일치)
- ✅ 정점/변 정규화 규칙 준수

### Action Items
**None** - Story approved without changes

---

_Story drafted by BMAD Story Creation Workflow_
