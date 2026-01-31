#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                         APPFAST INSTALLER                                  ║
# ║           Instalador do runtime AppFast no sistema Linux                   ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
#
# Uso: sudo ./install.sh
# Desinstalar: sudo ./install.sh --uninstall

set -e

VERSION="1.0.0"
INSTALL_DIR="/usr/local/bin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ═══════════════════════════════════════════════════════════════════════════════
# Cores
# ═══════════════════════════════════════════════════════════════════════════════
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

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

# ═══════════════════════════════════════════════════════════════════════════════
# Verificações
# ═══════════════════════════════════════════════════════════════════════════════

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Este instalador precisa ser executado como root (use sudo)"
    fi
}

check_dependencies() {
    local deps=("tar" "mktemp" "grep" "tail")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Dependências faltando: ${missing[*]}"
    fi
    
    success "Todas as dependências encontradas"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Instalação
# ═══════════════════════════════════════════════════════════════════════════════

install_appfast() {
    print_banner
    
    info "Verificando dependências..."
    check_dependencies
    
    info "Instalando binários em $INSTALL_DIR..."
    
    # Copiar binários
    cp "$SCRIPT_DIR/bin/appfast" "$INSTALL_DIR/appfast"
    cp "$SCRIPT_DIR/bin/appfast-pack" "$INSTALL_DIR/appfast-pack"
    
    # Tornar executáveis
    chmod +x "$INSTALL_DIR/appfast"
    chmod +x "$INSTALL_DIR/appfast-pack"
    
    success "appfast instalado em $INSTALL_DIR/appfast"
    success "appfast-pack instalado em $INSTALL_DIR/appfast-pack"
    
    # Instalar thumbnailer para mostrar ícones no gerenciador de arquivos
    if [[ -f "$SCRIPT_DIR/bin/appfast-thumbnailer" ]]; then
        info "Instalando thumbnailer para ícones..."
        cp "$SCRIPT_DIR/bin/appfast-thumbnailer" "$INSTALL_DIR/appfast-thumbnailer"
        chmod +x "$INSTALL_DIR/appfast-thumbnailer"
        
        # Instalar arquivo de configuração do thumbnailer
        mkdir -p /usr/share/thumbnailers
        cat > /usr/share/thumbnailers/appfast.thumbnailer << 'EOF'
[Thumbnailer Entry]
TryExec=appfast-thumbnailer
Exec=appfast-thumbnailer %i %o %s
MimeType=application/x-appfast;
EOF
        success "Thumbnailer instalado (ícones visíveis no gerenciador de arquivos)"
    fi
    
    # Criar associação de tipo MIME para .AppFast
    info "Registrando tipo de arquivo .AppFast..."
    
    # Criar arquivo mime
    mkdir -p /usr/share/mime/packages
    cat > /usr/share/mime/packages/appfast.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-appfast">
    <comment>AppFast Package</comment>
    <comment xml:lang="pt_BR">Pacote AppFast</comment>
    <glob pattern="*.AppFast"/>
    <magic priority="50">
      <match type="string" offset="0" value="APPFAST"/>
    </magic>
  </mime-type>
</mime-info>
EOF
    
    # Atualizar banco de dados MIME
    if command -v update-mime-database &> /dev/null; then
        update-mime-database /usr/share/mime 2>/dev/null || true
    fi
    
    # Criar arquivo .desktop para abrir com appfast
    mkdir -p /usr/share/applications
    cat > /usr/share/applications/appfast.desktop << EOF
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
    
    # Atualizar banco de dados de aplicativos
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database /usr/share/applications 2>/dev/null || true
    fi
    
    success "Tipo de arquivo .AppFast registrado"
    
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
    echo -e "  ${GREEN}./meu-app.AppFast${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# Desinstalação
# ═══════════════════════════════════════════════════════════════════════════════

uninstall_appfast() {
    print_banner
    
    info "Removendo AppFast do sistema..."
    
    # Remover binários
    rm -f "$INSTALL_DIR/appfast"
    rm -f "$INSTALL_DIR/appfast-pack"
    success "Binários removidos"
    
    # Remover MIME type
    rm -f /usr/share/mime/packages/appfast.xml
    if command -v update-mime-database &> /dev/null; then
        update-mime-database /usr/share/mime 2>/dev/null || true
    fi
    
    # Remover .desktop
    rm -f /usr/share/applications/appfast.desktop
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database /usr/share/applications 2>/dev/null || true
    fi
    
    success "Registros de sistema removidos"
    
    echo ""
    echo -e "${GREEN}AppFast foi desinstalado com sucesso.${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    case "${1:-}" in
        --uninstall|-u)
            check_root
            uninstall_appfast
            ;;
        --help|-h)
            print_banner
            echo "Uso: sudo ./install.sh [opções]"
            echo ""
            echo "Opções:"
            echo "  --uninstall, -u   Desinstala o AppFast"
            echo "  --help, -h        Mostra esta ajuda"
            echo ""
            ;;
        *)
            check_root
            install_appfast
            ;;
    esac
}

main "$@"
