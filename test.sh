#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# Testes automatizados do AppFast
# ═══════════════════════════════════════════════════════════════════════════════

# NÃO usar set -e para permitir que os testes continuem após falhas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPFAST="$SCRIPT_DIR/bin/appfast"
APPFAST_PACK="$SCRIPT_DIR/bin/appfast-pack"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

passed=0
failed=0

test_pass() {
    echo -e "${GREEN}✓ PASS:${NC} $1"
    ((passed++)) || true
}

test_fail() {
    echo -e "${RED}✗ FAIL:${NC} $1"
    ((failed++)) || true
}

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║               🧪 Testes do AppFast                            ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Teste 1: Verificar se os binários existem
# ─────────────────────────────────────────────────────────────────────────────
echo "📋 Teste 1: Verificar binários"

if [[ -f "$APPFAST" ]]; then
    test_pass "appfast existe"
else
    test_fail "appfast não encontrado"
fi

if [[ -f "$APPFAST_PACK" ]]; then
    test_pass "appfast-pack existe"
else
    test_fail "appfast-pack não encontrado"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Teste 2: Empacotar exemplo hello-world
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "📋 Teste 2: Empacotar hello-world"

chmod +x "$APPFAST" "$APPFAST_PACK"

OUTPUT="$SCRIPT_DIR/hello-world.AppFast"

if "$APPFAST_PACK" "$SCRIPT_DIR/examples/hello-world" -o "$OUTPUT" > /dev/null 2>&1; then
    test_pass "Empacotamento concluído"
else
    test_fail "Falha ao empacotar"
fi

if [[ -f "$OUTPUT" ]]; then
    test_pass "Arquivo .AppFast criado"
else
    test_fail "Arquivo .AppFast não foi criado"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Teste 3: Verificar magic bytes (agora é #!APPFAST)
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "📋 Teste 3: Verificar formato do pacote"

magic=$(head -c 9 "$OUTPUT" 2>/dev/null)
if [[ "$magic" == "#!APPFAST" ]]; then
    test_pass "Magic bytes corretos (#!APPFAST)"
else
    test_fail "Magic bytes incorretos: '$magic'"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Teste 4: Executar pacote
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "📋 Teste 4: Executar pacote"

output=$("$APPFAST" "$OUTPUT" 2>&1) || true

if echo "$output" | grep -q "APPDIR"; then
    test_pass "Variável \$APPDIR presente na saída"
else
    test_fail "Variável \$APPDIR não encontrada"
fi

if echo "$output" | grep -q "APPFAST_NAME"; then
    test_pass "Variável \$APPFAST_NAME presente na saída"
else
    test_fail "Variável \$APPFAST_NAME não encontrada"
fi

if echo "$output" | grep -q "AppFast executou com sucesso"; then
    test_pass "Script prime executou corretamente"
else
    test_fail "Script prime não completou"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Teste 5: Verificar cleanup
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "📋 Teste 5: Verificar cleanup da pasta temporária"

# Aguardar um pouco para cleanup
sleep 1

temp_dirs=$(ls -d /tmp/appfast-* 2>/dev/null | wc -l) || temp_dirs=0
if [[ "$temp_dirs" -eq 0 ]]; then
    test_pass "Pastas temporárias foram limpas"
else
    test_fail "Encontradas $temp_dirs pastas temporárias não limpas"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Teste 6: Extração sem execução
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "📋 Teste 6: Extração sem execução"

cd "$SCRIPT_DIR"
rm -rf "./hello-world"

"$APPFAST" --extract "$OUTPUT" > /dev/null 2>&1 || true

if [[ -d "./hello-world" ]]; then
    test_pass "Extração criou pasta"
    
    if [[ -f "./hello-world/prime" ]]; then
        test_pass "Arquivo prime extraído"
    else
        test_fail "Arquivo prime não encontrado"
    fi
    
    rm -rf "./hello-world"
else
    test_fail "Pasta de extração não foi criada"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Teste 7: Ver informações do pacote
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "📋 Teste 7: Ver informações do pacote"

info_output=$("$APPFAST" --info "$OUTPUT" 2>&1) || true

if echo "$info_output" | grep -q "name="; then
    test_pass "Metadados exibidos corretamente"
else
    test_fail "Metadados não encontrados"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Resultado final
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo -e "Resultados: ${GREEN}$passed passaram${NC}, ${RED}$failed falharam${NC}"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Cleanup
rm -f "$OUTPUT"

if [[ $failed -gt 0 ]]; then
    exit 1
fi

exit 0
