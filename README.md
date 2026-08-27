

# Aplicação simples conteinerizada em Docker de Cadastro de Nomes com Node.js & PostgreSQL

![Node.js](https://img.shields.io/badge/Node.js-v18-339933?logo=node.js&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-v15-4169E1?logo=postgresql&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-v20+-2496ED?logo=docker&logoColor=white)
![Express](https://img.shields.io/badge/Express-v4-000000?logo=express&logoColor=white)

Aplicação web monolítica simplificada, desenvolvida para demonstrar na prática como construir, estruturar e containerizar um ecossistema focado em **Node.js** e banco de dados **Postgres** utilizando as melhores práticas de Docker.

---

## O que o projeto faz

* **Cadastro Simples:** Permite o envio de nomes através de um formulário web dinâmico.
* **Renderização no Servidor (SSR):** Lista em tempo real os nomes salvos no banco de dados, ordenados pelos mais recentes.
* **Monitoramento:** Exibe o status da conexão com o banco de dados diretamente na tela.

---

## Arquitetura do Sistema

A aplicação adota o padrão de **Arquitetura Monolítica com Renderização no Servidor (Server-Side Rendering - SSR)**.

* **Fluxo de Dados:** O navegador (cliente) faz uma requisição HTTP para o servidor Node.js. O Node se comunica com o banco de dados PostgreSQL através do Sequelize (ORM), processa as informações, monta dinamicamente o HTML com CSS embutido e entrega a página pronta para o cliente.
* **Vantagem:** Reduz a complexidade operacional, eliminando a necessidade de gerenciar repositórios e deploys separados para o Frontend e para o Backend.

---

## Justificativas Técnicas de Infraestrutura (DevOps)

O projeto foi estruturado com foco em performance, portabilidade e segurança:

### Dockerfile (Build Otimizado)
* **Imagem Base Alpine (`node:18-alpine`):** Reduz o tamanho final da imagem de ~1GB para cerca de **~180MB**, diminuindo o tempo de deploy e a superfície de ataque para vulnerabilidades.
* **Multi-stage Build:** Divide o processo em duas etapas (`builder` e produção). As ferramentas de instalação e caches do NPM ficam isolados no primeiro estágio, gerando uma imagem final limpa e leve.
* **Cache de Camadas:** A cópia dos arquivos `package*.json` é feita antes do código-fonte. Desse modo, se o código for alterado, o Docker aproveita o cache das dependências instaladas sem precisar baixar tudo do NPM novamente.

### Docker Compose (`compose.yml`)
* **Isolamento de Credenciais:** O Compose consome variáveis de ambiente através de um arquivo `.env` local (não versionado), impedindo a exposição de senhas no GitHub.
* **Persistência com Volumes:** Utiliza um volume nomeado (`postgres_data`) atrelado ao diretório `/var/lib/postgresql/data` do container, garantindo que os dados salvos persistam mesmo se o container for reiniciado ou destruído.
* **Orquestração Inteligente (`depends_on`):** O serviço do app aguarda o banco de dados estar ativo antes de iniciar sua própria execução, evitando falhas de inicialização por perda de conectividade (`ECONNREFUSED`).

---

## Estrutura do Projeto
```text
docker/
├── src/
│   └── index.js          # Servidor Express, conexão com Sequelize e Views (SSR)
├── .dockerignore         # Remove arquivos locais (como node_modules) do build do Docker
├── .env.example          # Modelo de configuração para o ambiente
├── .gitignore            # Impede o envio de pastas locais e credenciais para o Git
├── compose.yml           # Orquestrador de serviços (Aplicação + Banco)
├── Dockerfile            # Configuração do build multi-stage da imagem
├── package.json          # Dependências do projeto e scripts de execução
└── README.md             # Documentação oficial
```
----
## Pré-requisitos

Você precisará do Docker e do Docker Compose instalados.

**No Linux (Ubuntu/Debian)**
Se não tiver o Docker instalado, execute os comandos abaixo no seu terminal:

 - Atualize o índice de pacotes da distribuição
 
> `sudo apt update`
- Instale o motor do Docker e o plugin nativo do Docker Compose

> `sudo apt install docker.io docker-compose-v2 -y`

- Adicione seu usuário ao grupo do sistema docker para evitar a obrigatoriedade do 'sudo'

> `sudo usermod -aG docker $USER`

**Nota Importante:** Após rodar o comando `usermod`, encerre sua sessão atual no terminal e abra-o novamente (ou faça logoff do sistema) para que o novo grupo de permissões seja carregado com sucesso.

Para validar se as instalações foram concluídas com êxito, execute:
___

## Passo a Passo para Execução

Siga rigorosamente as etapas estruturadas abaixo para clonar, configurar e rodar o projeto localmente:

### Passo 1: Clonar o Repositório

Baixe os arquivos fontes do projeto diretamente do GitHub para a sua máquina local:


> `git clone https://github.com/dhuberto/docker.git`

### Passo 2: Acessar o Diretório do Projeto

Navegue até a pasta raiz criada pelo Git:


> `cd docker`

### Passo 3: Configurar as Variáveis de Ambiente

A aplicação necessita das variáveis de conexão do banco de dados para operar de forma segura. Copie o arquivo de exemplo para inicializar o arquivo de ambiente oficial:

> `cp .env.example .env`

**Dica de Customização:** Se desejar alterar o nome do banco de dados, o usuário ou as senhas administrativas padrões, abra o arquivo `.env` gerado utilizando o editor de texto de sua preferência (ex: `nano .env`) e altere os valores antes de subir os containers.

### Passo 4: Inicializar o Ecossistema de Containers

Execute o comando de orquestração para construir a imagem customizada do Node.js, realizar o pull da imagem oficial do PostgreSQL e conectá-los na mesma rede virtual interna:

> `docker compose up -d`

-   **O que a flag `-d` (detached) faz?** Executa os containers em segundo plano, liberando o prompt do seu terminal imediatamente para que você possa continuar trabalhando.
    

## Acesso à Aplicação

Assim que o processo do Docker Compose finalizar a inicialização de todos os serviços com sucesso, abra o navegador web e acesse o endereço abaixo:

Na interface do **docker**, basta digitar um nome no campo do formulário e clicar em **Cadastrar**. As informações serão processadas pelo servidor Node.js e salvas na tabela do PostgreSQL instantaneamente, atualizando a listagem SSR abaixo.

## Resolução de Problemas Comuns (Troubleshooting)

### 1. Erro: `"Port 3000 (ou 5432) is already in use"`

-   **Causa:** Este comportamento ocorre quando outro serviço local no seu sistema operacional já está alocado e escutando na mesma porta de rede que o container tenta mapear.
    
-   **Solução:** Encerre o processo local que está utilizando a porta conflitante ou abra o arquivo `.env` e ajuste a variável correspondente à porta mapeada (ex: modificar a porta exposta do host para `3001` no `compose.yml`).
    

### 2. O site não carrega ou apresenta erro de conexão com o Banco de Dados

-   **Causa:** Eventualmente, o container do Node.js pode finalizar seu carregamento de scripts milissegundos antes do PostgreSQL concluir seu processo interno de inicialização e criação do cluster de dados.
    
-   **Solução:** Aguarde cerca de 10 segundos e atualize a página no navegador (`F5`). Se o erro persistir, inspecione as saídas de logs do ecossistema executando:


> `docker compose logs -f`

## Como Encerrar o Ambiente

### Desativar os Serviços (Mantendo os dados salvos)

Para desligar e interromper a execução dos containers temporariamente sem perder os dados cadastrados, utilize:

> `docker compose down`

### Reset Total do Ambiente (Apagando todos os registros)

Caso necessite expurgar completamente o ambiente, removendo inclusive os volumes persistidos no disco e limpando todos os nomes inseridos no banco de dados, execute a remoção incluindo a flag de volumes e recriar novamente:

> `docker compose down -v` #(-v remove volumes)
> 
> `docker compose up -d --build` #(caso queira recriar atualizando)

### Verifica Logs
>`docker compose logs app --tail=20`

### Removendo o Projeto.

> `docker compose down -v` #(-v remove volumes)
> 
> `docker rmi docker-app`
> 
> `docker rmi postgres:15-alpine`
> 
> `cd ..`
> 
> `rm -rf docker`
