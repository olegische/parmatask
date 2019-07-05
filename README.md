# Тестовое задание от PARMA Technologies Group

## Задание

Создать 3 vm (любой гипервизор, можно VirtualBox)
- Jenkins (centos7/ubuntu)
- gitlab (centos7/ubuntu)
- testbox (centos7)

Jenkins: Создать job, которая бы запустила ansible playbook
Gitlab: в единственный репозиторий положить:
- ansible playbook
- любое тестовое вебприложение класса "Hello, world" на любом языке/стеке
- заполнить readme.md
Ansible playbook: На узел testbox устанавливает любой вебсервер (nginx, apache, lighttpd, tomcat) + деплоит на него вебприложение 'hello,world'

Описать кратко решение задачи и инструкции для проверки.

## Решение