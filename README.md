# SSCodeIDE

<p align="center">
  <strong>Um ambiente de desenvolvimento integrado (IDE) leve, moderno e construído 100% em GDScript nativo no Godot 4.</strong>
</p>

<p align="center">
  <img src="icon.svg" alt="SSCodeIDE Logo" width="128" height="128">
</p>

---

## 🚀 Sobre o Projecto

O **SSCodeIDE** é um editor de código e IDE desenvolvido inteiramente com **Godot Engine 4.x** e **GDScript**. Inspirado em editores modernos, ele combina um tema visual elegante (*Monokai Pro*), suporte a fontes tipográficas com símbolos (*FiraCode Nerd Font*), um explorador de ficheiros inteligente e um assistente de IA integrado com múltiplos modelos e fallback automático.

---

## ✨ Funcionalidades Principais

- **Editor de Código Completo (`CodeEdit`)**:
  - Múltiplos separadores de ficheiros com controlo de estado e histórico de alterações.
  - Numeração de linhas, realce de sintaxe e indentação automática.
  - Painel integrado de pesquisa e substituição (`Find & Replace`).
  - Manipulação rápida de linhas (duplicar, mover para cima/baixo, comentar/descomentar).
  
- **Explorador de Ficheiros (`FileTree`)**:
  - Deteção automática do tipo de ficheiro (*scripts, cenas, configurações, imagens, áudios, vídeos, documentos e arquivos compactados*).
  - Ícones visuais dedicados através do addon `@icons`.

- **Assistente de Inteligência Artificial Integrado**:
  - Painel de chat lateral para assistência de código e conversação.
  - Suporte a múltiplos modelos de ponta via **NVIDIA NIM API**:
    - `NVIDIA Nemotron` (Reasoning & Lightning)
    - `Moonshot Kimi K3`
    - `DeepSeek V4`
    - `Laguna Code`
  - Sistema inteligente de fallback e notificações *Toast* em tempo real.

- **Autenticação & Suporte Web**:
  - Fluxo de autenticação Google / OAuth via WebView modal integrado.

- **Testes Automatizados**:
  - Suíte de testes unitários integrada via **GUT (Godot Unit Test)**.

---

## ⌨️ Atalhos de Teclado

### Ficheiro
| Atalho | Ação |
| :--- | :--- |
| <kbd>Ctrl</kbd> + <kbd>N</kbd> | Novo ficheiro |
| <kbd>Ctrl</kbd> + <kbd>O</kbd> | Abrir ficheiro |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>O</kbd> | Abrir directório / workspace |
| <kbd>Ctrl</kbd> + <kbd>S</kbd> | Gravar ficheiro |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd> | Gravar como... |
| <kbd>Ctrl</kbd> + <kbd>W</kbd> | Fechar separador actual |
| <kbd>Ctrl</kbd> + <kbd>Tab</kbd> | Próximo separador |
| <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Tab</kbd> | Separador anterior |
| <kbd>Ctrl</kbd> + <kbd>Q</kbd> | Sair da aplicação |

### Edição
| Atalho | Ação |
| :--- | :--- |
| <kbd>Ctrl</kbd> + <kbd>Z</kbd> / <kbd>Ctrl</kbd> + <kbd>Y</kbd> | Desfazer / Refazer |
| <kbd>Ctrl</kbd> + <kbd>X</kbd> / <kbd>C</kbd> / <kbd>V</kbd> | Cortar / Copiar / Colar |
| <kbd>Ctrl</kbd> + <kbd>A</kbd> | Seleccionar tudo |
| <kbd>Ctrl</kbd> + <kbd>F</kbd> | Abrir pesquisa |
| <kbd>Ctrl</kbd> + <kbd>G</kbd> | Ir para linha |
| <kbd>Ctrl</kbd> + <kbd>/</kbd> | Alternar comentário de linha |
| <kbd>Ctrl</kbd> + <kbd>D</kbd> | Duplicar linha actual |
| <kbd>Alt</kbd> + <kbd>↑</kbd> / <kbd>Alt</kbd> + <kbd>↓</kbd> | Mover linha para cima / baixo |

### IDE & Navegação
| Atalho | Ação |
| :--- | :--- |
| <kbd>F1</kbd> | Visualizar ajuda e lista de atalhos |
| <kbd>Ctrl</kbd> + <kbd>,</kbd> | Abrir configurações |
| <kbd>Ctrl</kbd> + <kbd>L</kbd> | Iniciar sessão IA |
| <kbd>Ctrl</kbd> + <kbd>P</kbd> | Focar no explorador de ficheiros |

---

## 📁 Estrutura do Projecto

```text
.
├── addons/             # Addons Godot (at-icons, gut, etc.)
├── fonts/              # Fontes tipográficas (FiraCode Nerd Font)
├── scene/              # Cenas Godot (.tscn)
│   └── ui_editor.tscn  # Interface principal do IDE
├── scripts/            # Scripts GDScript (.gd)
│   ├── ai_service.gd   # Serviço de integração de IA
│   ├── file_kind.gd    # Mapeamento de tipos e extensões de ficheiro
│   ├── google_auth.gd  # Fluxo de autenticação OAuth
│   ├── oauth_url.gd    # Gestor de URLs OAuth
│   ├── ui_editor.gd    # Controlador principal da interface
│   └── web_view.gd     # Componente WebView / navegação web
├── test/               # Testes unitários (GUT)
│   └── unit/
├── project.godot       # Ficheiro de configuração do motor Godot
├── .gutconfig.json     # Configuração dos testes GUT
├── LICENSE             # Licença do projecto (MIT)
└── README.md           # Documentação do projecto
```

---

## 🛠️ Como Executar

### Pré-requisitos
- **[Godot Engine 4.x](https://godotengine.org/)** (Recomendado 4.3 ou superior).

### Passos
1. Clone o repositório:
   ```bash
   git clone https://github.com/marcioeduine/ss_code_ide_godot.git
   cd ss_code_ide_godot
   ```

2. Abra o Godot Engine, clique em **Import** e selecione o ficheiro `project.godot`.

3. Execute o projecto pressionando <kbd>F5</kbd> (ou clique no botão **Play** no topo direito do Godot).

---

## 🧪 Executar Testes Unitários

Para correr os testes automatizados utilizando o GUT via terminal:

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json
```

---

## 📄 Licença

Este projecto está licenciado sob os termos da licença **MIT**. Consulte o ficheiro [LICENSE](LICENSE) para mais detalhes.

---

<p align="center">Desenvolvido por <strong>Márcio (SSDevTools)</strong></p>
