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
Ansible playbook: На узел testbox устанавливает любой вебсервер (nginx, apache, lighttpd, tomcat) + 
деплоит на него вебприложение 'hello,world'

Описать кратко решение задачи и инструкции для проверки.

## Решение

Для решения задания были созданы следующие скрипты:
- create-servers.sh (Создает ВМ серверы из готового исходника с использованием libvirt)
- config-servers.sh (Производит первоначальную конфигурацию серверов и создает Ansible сервер)
- start-servers.sh (Запускает настроенные ВМ серверы)
- start-ansible.sh (Запускает Ansible playbooks для конфигурации серверов)

### Требования к программному обеспечению. 
На выполняющей скрипт машине должны быть установлены пакеты libvirtd, expect, rsync, sshpass.

### Требования к исходнику для клонирования ВМ:
- установлен sshd сервис
- swap раздел на отдельном lvm логическом томе.
- swap раздел должен присутствовать и быть задействован.

Для подключения к созданным ВМ по ssh должен быть указан пароль root исходника в файле .passwd/root.<source_type_name>

Все скрипты поддерживают команду <script-name>.sh --help

Конфигурация скриптов производится в файлах каталога conf.d



С помощью create-servers.sh были созданы серверы ansibletest, jenkinstest, gitlabtest, testbox. 
Это единственный скрипт принимающий аргументы (см. create-servers.sh --help)

config-servers.sh увеличивает ОЗУ gitlabtest до 4ГиБ, увеличивает gitlabtest swap до 4ГиБ, 
устанавливает и настраивает Ansible на ansibletest.

start-servers.sh pапускает все созданные серверы, после чего start-ansible.sh eстанавливает на серверы 
Jenkins и GitLab все необходимые пакеты, testbox не подвергается конфигурации, т.к. им управлять будет job на Jenkins.

На Jenkins создается job (см ./test-ansible/test-ansible-jenkins-job-config), которая при коммите 
в репозиторий проекта на GitLab запускает билд, в процессе которого плагин Jenkins Ansible 
выполняет testbox-playbook.yml на testbox.

В результате чего по адресу http://testbox/hello в браузере можно наблюдать сообщение "Hello World!"