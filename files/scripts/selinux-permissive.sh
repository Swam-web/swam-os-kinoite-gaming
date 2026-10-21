#!/usr/bin/env bash
# ============================================================================
# selinux-permissive.sh — SELinux en mode permissif, persistant dans l'image.
#
# RATIONALE (dossier DATA/DIAG_FEDORA_2026-10-18) :
#   Les verrous historiques Fedora (greeter figé, « login accepté, aucune
#   session ») sont attribués au binôme SELinux enforcing × varlink logind
#   (tempête CreateSession: PermissionDenied, diag3). Le mode permissif logge
#   sans bloquer : les AVC restent visibles, plus rien n'est coupé.
#   HYPOTHÈSE H1 du test factoriel en cours (AUDIT_TEST_A.md) — à RETIRER
#   (git revert) si la phase enforcing du protocole disculpe SELinux.
#
# Idempotent, fail-soft : n'arrête jamais le build de l'image.
# ============================================================================
set -uo pipefail

echo "=== SELinux → permissive (persistant dans l'image) ==="
CONF=/etc/selinux/config
if [ -f "$CONF" ]; then
    sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' "$CONF"
    # filet : si aucune ligne SELINUX= n'existe (rare), l'ajouter
    grep -q '^SELINUX=' "$CONF" || echo 'SELINUX=permissive' >> "$CONF"
    echo "état : $(grep '^SELINUX=' "$CONF" | tr '\n' ' ')"
else
    echo "AVERTISSEMENT : $CONF absent — aucune modification (FAIL-SOFT)"
fi

# dontaudit off : les refus silencieux deviennent visibles dans le journal
# (leçon du dossier : les crashes « intermittents sans AVC visible »)
if command -v semodule >/dev/null 2>&1; then
    if semodule -DB; then
        echo "dontaudit désactivé ($(semodule -l 2>/dev/null | wc -l) modules chargés)"
    else
        echo "FAIL-SOFT : semodule -DB a échoué (non bloquant)"
    fi
else
    echo "FAIL-SOFT : semodule absent du contexte de build"
fi

echo "=== SELinux permissif : OK ==="
