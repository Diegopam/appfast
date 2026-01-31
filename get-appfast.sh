#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                    APPFAST - INSTALADOR REMOTO                             ║
# ║                  curl -sSL URL | sudo bash                                 ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
#
# Instala o AppFast diretamente do GitHub
# Uso: curl -sSL https://raw.githubusercontent.com/SEU_USUARIO/appfast/main/get-appfast.sh | sudo bash

set -e

VERSION="1.0.0"
REPO_URL="https://github.com/SEU_USUARIO/appfast"  # Altere para seu usuário
RAW_URL="https://raw.githubusercontent.com/SEU_USUARIO/appfast/main"  # Altere para seu usuário
INSTALL_DIR="/usr/local/bin"
TEMP_DIR=$(mktemp -d)

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

print_banner() {
    echo -e "${CYAN}"
    echo "  ╔═══════════════════════════════════════╗"
    echo "  ║    ${BOLD}🚀 AppFast Installer v${VERSION}${NC}${CYAN}     ║"
    echo "  ╚═══════════════════════════════════════╝"
    echo -e "${NC}"
}

error() {
    echo -e "${RED}[ERRO]${NC} $1" >&2
    exit 1
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Verificar root
if [[ $EUID -ne 0 ]]; then
    error "Execute com sudo: curl -sSL URL | sudo bash"
fi

print_banner

# Verificar dependências
info "Verificando dependências..."
for dep in tar mktemp grep tail curl; do
    if ! command -v "$dep" &> /dev/null; then
        error "Dependência faltando: $dep"
    fi
done
success "Dependências OK"

# Baixar arquivos
info "Baixando AppFast..."

curl -sSL "${RAW_URL}/bin/appfast" -o "$TEMP_DIR/appfast" || error "Falha ao baixar appfast"
curl -sSL "${RAW_URL}/bin/appfast-pack" -o "$TEMP_DIR/appfast-pack" || error "Falha ao baixar appfast-pack"
curl -sSL "${RAW_URL}/bin/appfast-thumbnailer" -o "$TEMP_DIR/appfast-thumbnailer" || error "Falha ao baixar thumbnailer"

success "Download concluído"

# Instalar
info "Instalando em $INSTALL_DIR..."

cp "$TEMP_DIR/appfast" "$INSTALL_DIR/appfast"
cp "$TEMP_DIR/appfast-pack" "$INSTALL_DIR/appfast-pack"
cp "$TEMP_DIR/appfast-thumbnailer" "$INSTALL_DIR/appfast-thumbnailer"

chmod +x "$INSTALL_DIR/appfast"
chmod +x "$INSTALL_DIR/appfast-pack"
chmod +x "$INSTALL_DIR/appfast-thumbnailer"

success "Binários instalados"

# Registrar tipo MIME
info "Registrando tipo de arquivo .AppFast..."

mkdir -p /usr/share/mime/packages
cat > /usr/share/mime/packages/appfast.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-appfast">
    <comment>AppFast Package</comment>
    <comment xml:lang="pt_BR">Pacote AppFast</comment>
    <glob pattern="*.AppFast"/>
    <magic priority="50">
      <match type="string" offset="0" value="#!APPFAST"/>
    </magic>
  </mime-type>
</mime-info>
EOF

if command -v update-mime-database &> /dev/null; then
    update-mime-database /usr/share/mime 2>/dev/null || true
fi

# Criar .desktop
mkdir -p /usr/share/applications
cat > /usr/share/applications/appfast.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=AppFast Runner
Comment=Execute AppFast packages
Exec=appfast %f
Icon=application-x-executable
Terminal=true
Categories=Utility;
MimeType=application/x-appfast;
NoDisplay=true
EOF

if command -v update-desktop-database &> /dev/null; then
    update-desktop-database /usr/share/applications 2>/dev/null || true
fi

# Instalar thumbnailer
mkdir -p /usr/share/thumbnailers
cat > /usr/share/thumbnailers/appfast.thumbnailer << 'EOF'
[Thumbnailer Entry]
TryExec=appfast-thumbnailer
Exec=appfast-thumbnailer %i %o %s
MimeType=application/x-appfast;
EOF

success "Sistema configurado"

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}          ${BOLD}✅ AppFast instalado com sucesso!${NC}               ${GREEN}║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}Comandos disponíveis:${NC}"
echo -e "  ${CYAN}appfast${NC}        - Executar pacotes .AppFast"
echo -e "  ${CYAN}appfast-pack${NC}   - Criar pacotes .AppFast"
echo ""
echo -e "${BOLD}Uso rápido:${NC}"
echo -e "  ${GREEN}appfast-pack meu-app/ -o meu-app.AppFast${NC}"
echo -e "  ${GREEN}appfast meu-app.AppFast${NC}"
echo ""
echo -e "📚 Documentação: ${CYAN}${REPO_URL}${NC}"
echo ""
