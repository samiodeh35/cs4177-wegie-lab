#!/usr/bin/env bash
# Import WeGIA schema + seed data into the MariaDB service from docker-compose.yml.
# Run from the repo root (directory that contains docker-compose.yml).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
echo "Importing WeGIA/BD/wegia001.sql ..."
docker compose exec -T db mysql -uwegia -pwegia < WeGIA/BD/wegia001.sql
echo "Importing WeGIA/BD/wegia002.sql ..."
docker compose exec -T db mysql -uwegia -pwegia < WeGIA/BD/wegia002.sql
echo "Done."
