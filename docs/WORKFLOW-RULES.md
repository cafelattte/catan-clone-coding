# 프로젝트 워크플로우 규칙

## Git Commit 규칙

Story 완료 후 git commit을 생성하기 전에 반드시 다음 단계를 거쳐야 한다:

1. **Story 작업 완료** - 코드 작성 및 테스트
2. **사용자 확인** - 사용자가 직접 변경사항 검토
3. **code-review 에이전트 실행** - `/bmad:bmgd:workflows:code-review`
4. **검증 완료** - 위 단계 모두 통과
5. **git commit 생성** - 검증 완료 후에만 커밋

## 예외 사항

- 문서만 변경하는 경우 (docs/)
- BMAD 설정 파일 변경
- 초기 프로젝트 설정

---

_Created: 2025-11-30_
