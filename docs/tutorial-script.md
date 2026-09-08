# Guião & Roteiro do Tutorial Interativo: SS - Code IDE

Este documento serve como o guião oficial e roteiro passo-a-passo para a demonstração, tutorial em vídeo e navegação assistida do **SS - Code IDE** executado nativamente em **Godot Engine 4.7.2.stable**.

---

## 🎬 Visão Geral das Cenas do Tutorial

| Cena | Tópico | Elementos & Ações em Foco | Duração Estimada |
| :--- | :--- | :--- | :--- |
| **01** | **Apresentação e Marca** | `AppBrand` (favicon.svg), Menu Sobre, Atalhos Globais | 15s |
| **02** | **Navegação & Temas** | `NavRail`, Alternador Claro/Escuro (`☀️`/`🌙`), Importação XML | 25s |
| **03** | **Explorador & Workspace** | `ExplorerPane`, Troca de Workspace, Recolher (`Ctrl+B`), Ícones `FileKind` | 20s |
| **04** | **Editor de Código Multi-Tab** | `CodeEdit`, Abas estilo JetBrains, Realce de Sintaxe, Atalhos de Linha | 30s |
| **05** | **Controlo de Versão (Git)** | Menu Git, Estado do Branch (`⎇ main`), Ficheiros Modificados, Diffs | 25s |
| **06** | **Pesquisa na Internet ao Vivo** | `/search <query>`, `/web <query>`, Extração de snippets e links web | 30s |
| **07** | **Assistente de IA & Modo Agente** | Chat Lateral, Resposta calorosa em 'Tu', Fallback de Modelos NVIDIA NIM, Edição Segura | 45s |

---

## 📋 Passo a Passo Detalhado (Roteiro de Execução)

### Cena 01: Apresentação e Boas-Vindas (`AppBrand`)
1. **Mover Cursor:** Deslocar suavemente o cursor até ao canto superior esquerdo para o ícone do **AppBrand** ([`favicon.svg`](file:///home/mcaquart/Downloads/SSCodeIDE_Godot/favicon.svg)).
2. **Clique & Menu:** Clicar no botão para abrir o menu da aplicação.
3. **Diálogo "Sobre":** Selecionar *About SSCodeIDE* para exibir a versão, arquitetura GDScript e créditos da Ser Superior (SS).
4. **Fechar Diálogo:** Premir <kbd>Esc</kbd> ou clicar no botão fechar.

### Cena 02: Barra de Navegação (`NavRail`) e Gestão de Temas
1. **Navegar pelo NavRail:** Percorrer verticalmente os ícones da barra lateral:
   - 📁 *Explorer*
   - ✏️ *Edit*
   - ⎇ *Git*
   - 🎨 *Themes*
   - 💬 *AI Chat*
2. **Alternador Rápido de Tema:**
   - Clicar no botão dinâmico **`☀️` / `🌙`** na barra para alternar instantaneamente entre o modo escuro (Dark) e o modo claro (Light).
3. **Importar tema XML:**
   - Abrir o menu **Themes** e escolher **Import XML theme…** para instalar um tema personalizado.

### Cena 03: Gestão de Workspace e Árvore de Ficheiros
1. **Explorador de Ficheiros:** Mover o cursor para a árvore de diretórios à esquerda.
2. **Ícones por Extensão (`FileKind`):** Destacar os ícones visuais diferenciados para `.gd`, `.tscn`, `.json`, `.md`, pastas abertas e fechadas.
3. **Recolher e Expandir:**
   - Premir <kbd>Ctrl</kbd>+<kbd>B</kbd> para recolher a barra lateral e dar 100% de largura ao editor.
   - Premir <kbd>Ctrl</kbd>+<kbd>B</kbd> novamente para expandir.

### Cena 04: Edição de Código Inteligente (`CodeEdit`)
1. **Abrir Ficheiro:** Dar duplo clique num ficheiro como [`scripts/file_kind.gd`](file:///home/mcaquart/Downloads/SSCodeIDE_Godot/scripts/file_kind.gd).
2. **Gestão de Abas:** Mostrar a barra de abas com indicador de destaque inferior (*accent line*) na aba ativa.
3. **Operações de Linha:**
   - Selecionar uma linha e duplicar com <kbd>Ctrl</kbd>+<kbd>D</kbd>.
   - Mover linhas com <kbd>Alt</kbd>+<kbd>↑</kbd> e <kbd>Alt</kbd>+<kbd>↓</kbd>.
   - Comentar/descomentar com <kbd>Ctrl</kbd>+<kbd>/</kbd>.
   - Abrir o painel de pesquisa com <kbd>Ctrl</kbd>+<kbd>F</kbd>.

### Cena 05: Integração com Git e GitHub (`GitService`)
1. **Barra de Estado:** Apontar para o indicador `⎇ main` no canto inferior esquerdo.
2. **Comando Slash de Git:** No painel de Chat, escrever `/git status` para demonstrar o resumo detalhado de ficheiros modificados e remotes do GitHub.
3. **Ver Histórico:** Executar `/git log` para ver os commits recentes formatados em BBCode com cores semânticas.

### Cena 06: Pesquisa na Internet em Tempo Real (`WebSearchService`)
1. **Comando de Pesquisa Web:** No chat da IA, introduzir `/search Godot 4.7 features` ou `/web Godot Engine`.
2. **Exibição dos Resultados:** Mostrar os snippets, títulos e links clicáveis extraídos da Internet em tempo real.
3. **Consulta com Contexto Temporal:** Perguntar à IA: *"Quais são as últimas novidades e características do Godot Engine?"*.
   - A IA consulta a web, obtém o contexto contemporâneo (Ano 2026) e formula uma resposta precisa.

### Cena 07: Assistente de IA & Modo Agente
1. **Interação com Tratamento por 'Tu':** Enviar uma mensagem de programação:
   - *"Olá! Podes ajudar-me a rever o código e explicar como funciona o nosso serviço de pesquisa web?"*
2. **Tom e Personalidade:** Demonstrar que o assistente responde com:
   - Tratamento caloroso e íntimo por **"tu"** (*"Olá! Claro que sim, estou aqui contigo para ajudar..."*).
   - Português Europeu de Portugal impecável.
   - Explicações claras e estruturadas em Markdown.
3. **Modo Agente:** Ativar o botão **Agent Mode** para permitir sugestões de código com `<sscode-write path="...">`.

---

## 🎯 Conclusão da Gravação
- Gravação finalizada e guardada no workspace para apresentação e documentação.
