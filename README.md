# Cadastro de Nomes com Go & PostgreSQL em Docker

Aplicação web monolítica simplificada, desenvolvida para demonstrar na
prática como construir, estruturar e containerizar um ecossistema focado
em **Go** e banco de dados **Postgres** utilizando as melhores práticas
de Docker.

---

## O que o projeto faz

- **Cadastro Simples:** Permite o envio de nomes através de um formulário web dinâmico.
- **Renderização no Servidor (SSR):** Lista em tempo real os nomes salvos no banco de dados, ordenados pelos mais recentes.
- **Monitoramento:** Exibe o status da conexão com o banco de dados diretamente na tela.

---

## Arquitetura do Sistema

A aplicação adota o padrão de **Arquitetura Monolítica com Renderização
no Servidor (SSR)**.

- **Fluxo de Dados:** O navegador faz uma requisição HTTP para o servidor
  Go. O servidor se comunica com o PostgreSQL via `database/sql` + driver
  `lib/pq`, processa as informações, monta o HTML com CSS embutido e
  entrega a página pronta.
- **Vantagem:** Reduz a complexidade operacional, eliminando a necessidade
  de gerenciar repositórios e deploys separados para Frontend e Backend.

---

## Justificativas Técnicas de Infraestrutura (DevOps)

O projeto foi estruturado com foco em performance, portabilidade e segurança:

### Dockerfile (Build Otimizado)

- **Imagem Base Alpine (`alpine:3.21`):** A imagem final tem cerca de
  **~20 MB**, uma fração do tamanho de uma base Debian/Ubuntu tradicional
  (~80 MB) ou de uma imagem Node.js completa (~180 MB). Isso reduz o tempo
  de pull no deploy e diminui a superfície de ataque.
- **Multi-stage Build:** Divide o processo em duas etapas (`builder` e
  produção). O compilador Go e o cache de módulos ficam isolados no
  primeiro estágio, gerando uma imagem final enxuta.
- **Binário Estático (`CGO_ENABLED=0`):** O binário Go não depende de
  bibliotecas compartilhadas do sistema. O driver Postgres é compilado
  dentro do binário — **zero dependências em runtime**.
- **Usuário Não-Root:** A aplicação roda como `appuser` (UID 1001),
  seguindo o princípio do menor privilégio.
- **Cache de Camadas:** `go.mod` e `go.sum` são copiados antes do
  código-fonte. Se apenas o código mudar, o Docker reaproveita o cache
  das dependências.

### Docker Compose (`compose.yml`)

- **Isolamento de Credenciais:** O Compose consome variáveis de ambiente
  através de um arquivo `.env` local (não versionado), impedindo a
  exposição de senhas no GitHub.
- **Persistência com Volumes:** Utiliza um volume nomeado
  (`postgres_data`) atrelado ao diretório `/var/lib/postgresql/data` do
  container, garantindo que os dados persistam mesmo se o container for
  reiniciado.
- **Orquestração Inteligente (`depends_on` + `healthcheck`):** O serviço
  do app aguarda o banco reportar `healthy` antes de iniciar, evitando
  falhas de inicialização por perda de conectividade.

---

## Estrutura do Projeto

```
docker/
├── src/
│   ├── main.go           # Servidor HTTP, conexão com Postgres e Views (SSR)
│   └── main_test.go      # Testes unitários dos handlers
├── go.mod                # Declaração do módulo Go e dependências
├── go.sum                # Checksums das dependências (gerado por go mod tidy)
├── .dockerignore         # Remove arquivos locais do build do Docker
├── .env.example          # Modelo de configuração para o ambiente
├── .gitignore            # Impede o envio de pastas locais e credenciais
├── compose.yml           # Orquestrador de serviços (Aplicação + Banco)
├── Dockerfile            # Configuração do build multi-stage da imagem
└── README.md             # Documentação oficial
```

---

## Pré-requisitos

Você precisará do **Docker** e do **Docker Compose** instalados.

### Linux (Ubuntu/Debian)

Se não tiver o Docker instalado:

```bash
# Atualiza o índice de pacotes
sudo apt update

# Instala o motor do Docker e o plugin nativo do Docker Compose
sudo apt install docker.io docker-compose-v2 -y

# Adiciona seu usuário ao grupo docker (evita 'sudo' em cada comando)
sudo usermod -aG docker $USER
```

> **Nota:** após o `usermod`, encerre a sessão do terminal e abra de novo
> (ou faça logoff) para que o novo grupo seja carregado.

### Validando a instalação

```bash
docker --version
docker compose version
```

---

## Passo a Passo para Execução

### Passo 1 — Clonar o Repositório

```bash
git clone https://github.com/dhuberto/docker.git
```

### Passo 2 — Acessar o Diretório do Projeto

```bash
cd ~/docker
```

### Passo 3 — Configurar as Variáveis de Ambiente

A aplicação precisa das variáveis de conexão com o banco. Copie o arquivo
de exemplo:

```bash
cp .env.example .env
```

**Dica:** se quiser alterar o nome do banco, usuário ou senha, abra o
`.env` com seu editor preferido (`nano .env`) e ajuste antes de subir.

### Passo 4 — Inicializar o Ambiente

Execute o Compose para construir a imagem Go, baixar o Postgres oficial e
conectá-los na mesma rede virtual interna:

```bash
docker compose up -d --build
```

**O que a flag `-d` (detached) faz?** Executa os containers em segundo
plano, liberando o prompt imediatamente.

### Passo 5 — Verificar se subiu

```bash
# Status dos containers
docker compose ps

# Logs da aplicação
docker compose logs go-app --tail=20
```

**Saída esperada nos logs:**

```
Tentativa 1 de conexão...
✅ Conectado ao PostgreSQL
✅ Tabelas sincronizadas
🚀 Servidor em http://localhost:3000
```

---

## Acesso à Aplicação

Abra o navegador em:

```
http://localhost:3000/
```

Na interface, digite um nome e clique em **Cadastrar**. As informações
são gravadas na tabela do PostgreSQL e a listagem SSR atualiza na hora.

**Health check:**

```bash
curl http://localhost:3000/healthz
# → ok
```

---

## Desenvolvimento Local (sem Docker)

Se quiser rodar a aplicação direto na máquina (para debug ou testes):

### Pré-requisitos

- **Go 1.22+** instalado (`go version`)
- Um **Postgres** acessível (local ou via `docker run`)

### Preparar dependências

```bash
go mod tidy
```

### Rodar os testes

```bash
go test ./...
go vet ./...
```

### Rodar a aplicação

```bash
export DB_HOST=localhost
export DB_PORT=5432
export DB_USER=appuser
export DB_PASSWORD=mudar123
export DB_NAME=appdb
export PORT=3000

go run ./src
```

### Build do binário

```bash
go build -ldflags="-s -w" -o /tmp/go-app ./src
/tmp/go-app
```

---

## Como Encerrar o Ambiente

### Parar os containers (mantém os dados)

```bash
docker compose down
```

### Reset total (apaga os dados)

```bash
docker compose down -v --remove-orphans
docker compose up -d --build
```

### Ver logs

```bash
docker compose logs go-app       --tail=20
docker compose logs postgres-go  --tail=20
docker compose logs -f            # acompanha em tempo real
```

---

## Sequência Completa de Limpeza

Para deixar a máquina **exatamente como estava antes de clonar**:

```bash
# 1. Derruba containers e apaga os dados do banco
cd ~/docker
docker compose down -v --remove-orphans

# 2. Remove a imagem da aplicação
docker rmi go-app-go-app 2>/dev/null || true

# 3. (Opcional) Remove a imagem do Postgres se não for usar em outros projetos
docker rmi postgres:alpine 2>/dev/null || true

# 4. Remove o clone local
cd ~
rm -rf docker
```

### Verificação final

```bash
docker ps -a     | grep -E "go-app|postgres-go"   # → vazio
docker volume ls | grep go-app                    # → vazio
docker images    | grep go-app                    # → vazio
```

---

## Resolução de Problemas Comuns

### 1. `Port 3000 (ou 5432) is already in use`

**Causa:** outro serviço local já está escutando na mesma porta.

**Solução:** encerre o processo conflitante, ou edite o `compose.yml` e
ajuste a porta exposta do host (ex.: `"3001:3000"`). Reinicie:

```bash
docker compose down
docker compose up -d --build
```

### 2. `Conflict. The container name ... is already in use`

**Causa:** container antigo com o mesmo nome ainda existe.

**Solução:**

```bash
docker compose down
docker rm -f go-app-1 go-app-postgres-go-1 2>/dev/null
docker compose up -d --build
```

### 3. Interface mostra "Banco OFFLINE"

**Causa:** o app subiu, mas a conexão com o Postgres falhou.

**Solução:** verifique se o container do banco está `healthy`:

```bash
docker compose ps
docker compose logs postgres-go --tail=20
```

Se o banco não subiu, cheque o `.env` (usuário, senha, nome do banco).

### 4. Erro de permissão em `docker` (sem `sudo`)

**Causa:** o usuário não está no grupo `docker`.

**Solução:**

```bash
sudo usermod -aG docker $USER
# encerre a sessão e abra de novo
```

---

## Referências

- [`src/main.go`](src/main.go) — código da aplicação (Go)
- [`src/main_test.go`](src/main_test.go) — testes unitários
- [`compose.yml`](compose.yml) — orquestração dos serviços
- [`Dockerfile`](Dockerfile) — build multi-stage da imagem
