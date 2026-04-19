# website-mirror

Простой nginx-прокси для перенаправления запросов к любому API или сайту. Полезен для обхода блокировок или создания зеркал.

## Быстрый старт

### Docker

```bash
# Сборка
docker build -t website-mirror .

# Запуск (TARGET_HOST обязателен!)
docker run -e TARGET_HOST=openrouter.ai -p 8080:80 website-mirror
```

### Docker Compose

```yaml
version: '3'
services:
  proxy:
    build: .
    ports:
      - "8080:80"
    environment:
      - TARGET_HOST=openrouter.ai
    # Опционально: health check (требуется curl в образе или отдельный контейнер)
    # healthcheck:
    #   test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:80/health"]
    #   interval: 30s
    #   timeout: 3s
    #   retries: 3
```

Запуск:
```bash
docker-compose up -d
```

## Переменные окружения

| Переменная | Описание | Обязательная |
|------------|----------|--------------|
| `TARGET_HOST` | Целевой хост для проксирования (без https://) | Да |
| `WHITELIST_IPS` | Разрешённые IP-адреса или подсети (через запятую). Если указан, доступ только для этих IP. | Нет |
| `BLACKLIST_IPS` | Заблокированные IP-адреса или подсети (через запятую). Имеет приоритет над whitelist. | Нет |

## Фильтрация по IP

Поддерживаются одиночные адреса и CIDR-подсети:

```bash
# Только белый список — доступ только для указанных IP
docker run -e TARGET_HOST=api.example.com \
  -e WHITELIST_IPS="192.168.1.100,10.0.0.0/8,172.16.0.0/12" \
  -p 8080:80 website-mirror

# Только чёрный список — доступ для всех, кроме указанных
docker run -e TARGET_HOST=api.example.com \
  -e BLACKLIST_IPS="192.168.1.200,203.0.113.0/24" \
  -p 8080:80 website-mirror

# Оба списка — whitelist разрешает, blacklist блокирует (blacklist приоритетнее)
docker run -e TARGET_HOST=api.example.com \
  -e WHITELIST_IPS="192.168.0.0/16" \
  -e BLACKLIST_IPS="192.168.1.200" \
  -p 8080:80 website-mirror
```

**Примечания:**
- Если `WHITELIST_IPS` не указан — по умолчанию разрешены все IP
- `BLACKLIST_IPS` всегда имеет приоритет: IP из чёрного списка будут заблокированы даже если есть в белом
- Можно использовать обе переменные одновременно для точного контроля доступа

## Примеры использования

**OpenRouter:**
```bash
docker run -e TARGET_HOST=openrouter.ai -p 8080:80 website-mirror
# API доступен по: http://localhost:8080/api/v1/chat/completions
```

**OpenAI:**
```bash
docker run -e TARGET_HOST=api.openai.com -p 8080:80 website-mirror
```

**Любой другой API:**
```bash
docker run -e TARGET_HOST=api.example.com -p 8080:80 website-mirror
```

## Health check

```bash
curl http://localhost:8080/health
# Ответ: OK
```

## Особенности

- Поддержка стриминга (SSE)
- Проброс всех заголовков включая Authorization
- Работа с HTTPS на порту 443
- Фильтрация по IP-адресам и подсетям

## Лицензия

MIT
