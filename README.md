# Packagist API Fetch

Action для скачивания ответов Packagist API и сохранения их в указанном репозитории. Этот Action необходим в качестве "проксирования" ответов API для использования в различных JAMstack приложениях, чтобы лишний раз не дёргать исходный Packagist API.

## Workflow Syntax

```yml
name: "Packagist API"

on:
  schedule:
    - cron:  '0 */6 * * *'

jobs:
  fetch:
    runs-on: ubuntu-latest
    name: "Fetch"
    steps:
      - name: "symfony"
        uses: ghastore/api-packagist@main
        with:
          git_repo: "${{ github.server_url }}/${{ github.repository }}.git"
          git_user: "${{ secrets.USER_NAME }}"
          git_email: "${{ secrets.USER_EMAIL }}"
          git_token: "${{ secrets.USER_TOKEN }}"
          api_dir: "api/packagist"
          api_vendor: "symfony"
          bot_info: "Email: mail@example.com"
```

## Legend

- `git_repo`  
  Ссылка на репозиторий, в котором необходимо хранить ответы API.
- `git_user`  
  Логин пользователя GitHub.
- `git_email`  
  Email пользователя GitHub.
- `git_token`  
  Токен пользователя GitHub.
- `api_url_main`  
  Ссылка на точку доступа API для получения общей информации о пакете. По умолчанию: `https://packagist.org`
- `api_url_repo`  
   Ссылка на точку доступа API для получения информации о пакете с конкретной версией. По умолчанию: `https://repo.packagist.org`
- `api_dir`  
  Локальная директория, в которую будут сохраняться ответы API. По умолчанию: `api/packagist`.
- `api_vendor`  
  Имя вендора предоставляемых пакетов.
- `bot_info`  
  Информация о боте, который получает ответы API. По [правилам](https://packagist.org/apidoc#best-practices) Packagist, в заголовке User-Agent необходимо указывать контактную информацию на случай, если потребуется связаться с автором бота.
