# 프로젝트 워크플로우 규칙

## Git Commit 규칙

Story 완료 후 git commit을 생성하기 전에 반드시 다음 단계를 거쳐야 한다:

1. **Story 작업 완료** - 코드 작성 및 테스트
2. **사용자 확인** - 사용자가 직접 변경사항 검토
3. **code-review 에이전트 실행** - `/bmad:bmgd:workflows:code-review`
4. **검증 완료** - 위 단계 모두 통과
5. **git commit 생성** - 검증 완료 후에만 커밋

## Code Review 완료 후 자동 커밋

code-review 워크플로우에서 **Approve** 후 스토리 상태를 `done`으로 변경할 때, git commit을 함께 생성한다.

**커밋 메시지 형식**:
```
Story X-Y: [스토리 제목 요약]

- 주요 변경 사항 bullet points
- 버그 수정 내용 (있는 경우)
- 테스트 추가 내용

All N acceptance criteria implemented, M tests passing.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

**포함 파일**:
- 스토리에서 수정/추가된 소스 코드 파일
- 스토리 마크다운 파일 (`docs/sprint-artifacts/X-Y-*.md`)
- 컨텍스트 파일 (`docs/sprint-artifacts/X-Y-*.context.xml`)
- sprint-status.yaml
- 테스트 파일

**제외 파일**:
- `.claude/settings.local.json` (로컬 설정)

## 예외 사항

- 문서만 변경하는 경우 (docs/)
- BMAD 설정 파일 변경
- 초기 프로젝트 설정

---

_Created: 2025-11-30_
_Updated: 2025-12-01_
