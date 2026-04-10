# Telegram Proxy

Простой nginx-прокси для перенаправления запросов к любому API или сайту. Полезен для обхода блокировок или создания зеркал.

## Быстрый старт

### Docker

```bash
# Сборка
docker build -t telegram-proxy .

# Запуск (TARGET_HOST обязателен!)
docker run -e TARGET_HOST=openrouter.ai -p 8080:80 telegram-proxy
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
```

Запуск:
```bash
docker-compose up -d
```

## Переменные окружения

| Переменная | Описание | Обязательная |
|------------|----------|--------------|
| `TARGET_HOST` | Целевой хост для проксирования (без https://) | Да |

## Примеры использования

**OpenRouter:**
```bash
docker run -e TARGET_HOST=openrouter.ai -p 8080:80 telegram-proxy
# API доступен по: http://localhost:8080/api/v1/chat/completions
```

**OpenAI:**
```bash
docker run -e TARGET_HOST=api.openai.com -p 8080:80 telegram-proxy
```

**Любой другой API:**
```bash
docker run -e TARGET_HOST=api.example.com -p 8080:80 telegram-proxy
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
