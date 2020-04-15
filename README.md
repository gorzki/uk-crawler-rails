# README

1. Install `docker` and `docker-compose` on your computer.
2. Do `cp .env.sample .env`.
3. Do `docker-compose up -d` with `--build` if you first time start app or change something in `Dockerfile`.
> If app container didint up try up all again. If something went wrong contact with admin.

> Run `docker-compose exec app bash` and then `rails db:migrate` if migrations needed.