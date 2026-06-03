# Premier Logistics — Plataforma de Gestão Integrada

Uma plataforma web premium de monitoramento, roteirização e gestão de atividades operacionais desenvolvida para a **Premier Logistics**. A aplicação possui uma interface moderna, rica em micro-animações, suporte completo a temas claro/escuro e controle de acesso baseado em perfis (**RBAC**).

---

## 🚀 Funcionalidades Principais

*   **Painel de Controle Multiperfil (RBAC):**
    *   **Visão Gestor (Diretor de Operações):** Gráficos e tabelas gerais de todas as equipes, KPIs de desempenho (Taxa de entrega, andamento, atrasados) e monitoramento de alertas.
    *   **Visão Colaborador (Faturamento, Logística, Vendas, RH):** Fila de tarefas do dia e progresso detalhado do roteiro mensal individual do seu setor.
*   **Quadro Kanban Interativo:**
    *   Acompanhe e movimente tarefas ativas com suporte a **Drag-and-Drop** (Arrastar e Soltar) nativo.
    *   Acessibilidade por clique rápido para mudança de status.
    *   Filtros inteligentes por equipe e prioridade.
*   **Roteiros Mensais (Roadmaps):**
    *   Checklists e fluxos obrigatórios por equipe de forma sequencial.
    *   Geração e acompanhamento de sub-etapas com prazos e responsáveis diretos.
*   **Iniciativas e Projetos Estratégicos:**
    *   Módulo de controle de iniciativas de médio e longo prazo com painel lateral deslizante (*Slide-over Drawer*) para detalhamento rápido de escopo e tarefas vinculadas.
*   **Calendário de Entrega Integrado:**
    *   Calendário mensal dinâmico com identificação visual dos prazos de todas as tarefas da equipe em formato de dots coloridos.
*   **Central de Mensagens e Alertas:**
    *   Notificações em tempo real sobre prazos expirados, novas tarefas atribuídas e conquistas operacionais.
*   **Design Premium & Responsivo:**
    *   Visual elegante com Glassmorphism, paleta HSL Slate, efeitos dinâmicos de hover e suporte nativo a temas **Light** e **Dark**.

---

## 🔐 Logins Padrão para Testes (Simulados)

A aplicação conta com um banco de dados local simulado com as seguintes credenciais:

| Nome | E-mail corporativo | Senha | Equipe | Cargo | Perfil |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Ronaldo Brito** | `ggu@premierlog.com.br` | `Premier!2026` | Gestão | Gerente Geral | **Gestor** (Acesso geral) |

> 💡 **Nota:** A plataforma também suporta o registro de novas contas diretamente através do formulário **"Criar um Novo Login"** presente na tela inicial. Todo o estado, dados e novos usuários são armazenados dinamicamente na memória cache (`localStorage`) do navegador.

---

## 🛠️ Tecnologias Utilizadas

*   **HTML5** estrutural e semântico.
*   **JavaScript (Vanilla ES6+)** para lógica de estado, ordenamento de dados e interações dinâmicas.
*   **CSS3 moderno** contendo variáveis dinâmicas (Tokens), Flexbox, CSS Grid e animações customizadas.
*   **Lucide Icons** para ícones vetoriais modernos.
*   **Google Fonts** (Fonte *Plus Jakarta Sans*).

---

## 💻 Como Rodar o Projeto Localmente

1.  Baixe ou clone a pasta do projeto.
2.  Dê um duplo clique no arquivo `index.html` (ou `premier_logistics_platform.html`) ou abra-o em um servidor local de desenvolvimento (ex: *Live Server* do VS Code).
3.  Utilize uma das credenciais da tabela de testes para explorar os recursos da plataforma!

---

## 🌐 Como Publicar e Hospedar Gratuitamente (GitHub Pages)

Como este é um projeto front-end estático (HTML, CSS e JS puros), você pode hospedá-lo gratuitamente no **GitHub Pages** em poucos segundos:

1.  Faça o push do seu código para o seu repositório no GitHub (veja as instruções de comandos no chat).
2.  No GitHub, acesse a aba **Settings** (Configurações) do seu repositório.
3.  No menu lateral esquerdo, clique em **Pages**.
4.  Em **Build and deployment** -> **Source**, selecione **Deploy from a branch**.
5.  Em **Branch**, selecione `main` e a pasta `/ (root)`. Clique em **Save**.
6.  Aguarde cerca de 1 a 2 minutos e o GitHub fornecerá um link público (ex: `https://seu-usuario.github.io/Control_PremierLog/`) para que qualquer pessoa possa acessar a sua plataforma online!

