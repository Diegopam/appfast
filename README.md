# 🚀 AppFast

**Formato de pacote executável leve para Linux, focado em shell scripts.**

Inspirado no AppImage, o AppFast permite empacotar seus scripts e aplicativos em um único arquivo executável `.AppFast`.

---

## ⚡ Instalação Rápida

```bash
curl -sSL https://raw.githubusercontent.com/SEU_USUARIO/appfast/main/get-appfast.sh | sudo bash
```

> Substitua `SEU_USUARIO` pelo seu nome de usuário do GitHub.

### Instalação Manual

```bash
git clone https://github.com/SEU_USUARIO/appfast.git
cd appfast
sudo ./install.sh
```

---

## 📦 Uso

### Criar um Pacote

1. Crie uma pasta com seu app:
```
meu-app/
├── prime          # Script principal (obrigatório)
└── assets/
    └── icon.png   # Ícone do app (obrigatório)
```

2. Empacote:
```bash
appfast-pack meu-app/ -o meu-app.AppFast
```

### Executar um Pacote

```bash
appfast meu-app.AppFast
```

Ou simplesmente (se o MIME type estiver registrado):
```bash
./meu-app.AppFast
```

---

## 🔧 Variáveis de Ambiente

Dentro do seu script `prime`, você tem acesso a:

| Variável | Descrição |
|----------|-----------|
| `$APPDIR` | Diretório temporário de execução |
| `$APPFAST_NAME` | Nome do arquivo .AppFast |
| `$APPFAST_PATH` | Caminho completo do .AppFast |
| `$APPFAST_ASSETS` | Atalho para `$APPDIR/assets/` |

### Exemplo de prime:
```bash
#!/bin/bash
echo "Executando de: $APPDIR"
echo "Meu ícone está em: $APPFAST_ASSETS/icon.png"
```

---

## 🎨 Ícones no Gerenciador de Arquivos

O AppFast inclui um thumbnailer que exibe o ícone de cada `.AppFast` no gerenciador de arquivos!

---

## 📋 Comandos

### appfast
```bash
appfast arquivo.AppFast          # Executar
appfast --info arquivo.AppFast   # Ver metadados
appfast --extract arquivo.AppFast # Extrair conteúdo
appfast --keep arquivo.AppFast   # Executar sem limpar temp
```

### appfast-pack
```bash
appfast-pack pasta/ -o saida.AppFast
appfast-pack pasta/ -n "meu-app" --app-version "2.0.0"
```

---

## 📂 Estrutura do Projeto

```
appfast/
├── bin/
│   ├── appfast              # Runtime
│   ├── appfast-pack         # Empacotador
│   └── appfast-thumbnailer  # Gerador de thumbnails
├── examples/
│   └── hello-world/         # Exemplo básico
├── get-appfast.sh           # Instalador via curl
├── install.sh               # Instalador local
└── README.md
```

---

## 🧪 Testar

```bash
./test.sh
```

---

## 📄 Licença

MIT License - Use como quiser! 🎉
