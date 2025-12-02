# Settlus of Catan

Love2D로 구현한 카탄 클론 코딩 프로젝트

## Demo

https://github.com/user-attachments/assets/8a142610-b04a-4c21-8e22-bee08e57ca98

## 소개


클래식 카탄의 핵심 재미를 재현한 미니멀 스타일의 전략 보드게임입니다.
TDD 기반 게임 개발 학습과 AI 워크플로우(Claude Code, BMAD Method) 활용 경험을 목표로 합니다.

## 기술 스택

- **Game Engine:** [Love2D](https://love2d.org/) 11.5
- **Language:** Lua
- **Testing:** [busted](https://lunarmodules.github.io/busted/)
- **Libraries:** serpent, classic, hump
- **Workflow:** [BMAD Method](https://github.com/bmadcode/BMAD-METHOD)

## 기능

- 🎲 19타일 헥스 보드 + 주사위 시스템
- 🏠 Settlement, City, Road 건설
- 📦 5종 자원 관리 (Brick, Lumber, Wool, Grain, Ore)
- 👥 로컬 핫시트 2-4인 멀티플레이
- 🏆 10점 선점 승리 조건

## 실행 방법

### 요구사항

- [Love2D](https://love2d.org/) 11.5+

### 실행

```bash
# macOS
/Applications/love.app/Contents/MacOS/love .

# Windows
love.exe .

# Linux
love .
```

### 테스트

```bash
busted
```

## 프로젝트 구조

```
├── src/
│   ├── game/       # 순수 Lua 게임 로직 (Love2D 의존 없음)
│   │   ├── board.lua
│   │   ├── game_state.lua
│   │   ├── rules.lua
│   │   └── ...
│   ├── scenes/     # 게임 씬 (메뉴, 플레이)
│   └── ui/         # Love2D 의존 UI 컴포넌트
├── tests/          # busted 테스트
├── docs/           # 설계 문서 및 스프린트 아티팩트
└── assets/         # 폰트, 이미지, 미디어
```

## 개발 현황

현재 MVP 기능 구현 진행 중입니다.

- [x] Phase 0: 환경 설정
- [x] Phase 1: 데이터 모델 (Hex, Vertex, Edge)
- [x] Phase 2: 보드 렌더링 + 배치 시스템
- [ ] Phase 3: 자원 시스템 + 거래
- [ ] Phase 4: 게임 플로우 완성

## License

MIT License
