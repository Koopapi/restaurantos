#!/usr/bin/env bash
# Protege main y develop usando GitHub CLI (gh).
# Requisitos: gh instalado y autenticado (gh auth status), ejecutar DENTRO del repo.
# gh resuelve {owner}/{repo} desde el remoto 'origin'.
#
# Nota solo-dev: required_approving_review_count = 0 (PR obligatorio, sin aprobación
# externa, para que puedas mergear tus propios PR). enforce_admins = false para no
# bloquearte si un check se atora. Sube approvals a 1 y enforce_admins a true con equipo.
set -euo pipefail

protect () {
  local branch="$1"
  echo "→ Protegiendo '$branch'…"
  gh api -X PUT "repos/{owner}/{repo}/branches/${branch}/protection" \
    -H "Accept: application/vnd.github+json" \
    --input - <<JSON
{
  "required_status_checks": { "strict": true, "contexts": ["build-test"] },
  "enforce_admins": false,
  "required_pull_request_reviews": { "required_approving_review_count": 0 },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_linear_history": true
}
JSON
  echo "  ✓ '$branch' protegida"
}

protect main
protect develop

echo ""
echo "Verificación:"
gh api "repos/{owner}/{repo}/branches/main/protection" \
  --jq '{pr_required: (.required_pull_request_reviews != null), checks: .required_status_checks.contexts, force_push: .allow_force_pushes.enabled}'
