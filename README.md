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
### Описание скриптов
Для решения задания были созданы следующие скрипты:
1. create-servers.sh -- Запускается первым. Создает ВМ серверы из готового исходника с использованием libvirt.
    1. Принимает обязательные аргументы --os centos7.0 и имена создаваемых серверов.
    2. Объем необходимой памяти на диске для хранения ВМ = (( 4 * размер образа исходной ВМ) + 4 ГиБ для swap ).
2. config-servers.sh -- Запускается после выполнения create-servers.sh. Производит первоначальную конфигурацию серверов.
    1. Обновляет пакеты на установленных серверах.
    2. Проверяет выполнение требований к объему оперативной памяти для GitLab сервера.
    3. Устанавливает все необходимые пакеты на Ansible сервер.
    4. Создает SSH ключи для пользователя root на Ansible сервере и регистрирует их на управляемых серверах.
3. start-servers.sh -- Запускается после выполнения config-servers.sh. Запускает настроенные ВМ серверы.
4. start-ansible.sh -- Запускается после выполнения start-ansible.sh. Запускает Ansible playbooks для конфигурации серверов. Плейбуки находятся в каталоге ./ansible-srv-data

### Требования к программному обеспечению. 
На выполняющей скрипты машине должны быть установлены пакеты libvirtd, expect, rsync, sshpass.

### Требования к исходнику для клонирования ВМ:
- Версия ОС -- centos7.0.
- Файл образа в формате img. 
- Установлен и запущен sshd сервис
- ВМ содержит одно блочное устройство /dev/vdb
- swap раздел на отдельном lvm логическом томе.
- swap раздел должен присутствовать и быть задействован.

### Требование к наименованию ВМ.
Скрипты взаимодействуют с четырьмя ВМ с именами ansible*, gutlab*, jenkins*, testbox*.

### Дополнительная информация.
- Для подключения к созданным ВМ по ssh должен быть указан пароль root исходника в файле .passwd/root.<source_type_name>.
- Все скрипты поддерживают команду --help.
- Конфигурация скриптов производится в файлах каталога conf.d.
- На машину разработчика склонировать репозиторий https://github.com/olegische/parmatask.git.
- Изменить файл .test-ansible/hosts в соответствии с настройкой на сервере Ansible (/etc/ansible/hosts).

### Ручная настройка Jenkins и GitLab для взаимной интеграции.
1. На настроенных серверах GitLab и Jenkins нужно создать пользователя проекта.
2. GitLab: под пользователем root включить опцию Admin Area --> Settings --> Network --> Outbound requests -->
Allow requests to the local network from hooks and services.
3. GitLab: авторизоваться под созданным пользователем и создать проект parmatask без создания readme.md.
4. GitLab: Добавить пользователю SSH ключ, для подключения с машины разработчика.
5. GitLab: Отключить Auto DevOps.
6. GitLab: Операцией push добавить файлы проекта с машины разработчика в проект parmatask на GitLab.
7. GitLab: Получить Access API Token для доступа к репозиторию пользователя: Profile Settings -- Access Token.
8. Jenkins: Создать credentials для пользователя проекта на GitLab. Можно по логину и паролю.
8. Jenkins: Создать credentials для пользователя root на Jenkins c добавлением приватного ключа SSH. Проконтролировать возможность подключения по этому ключу на ВМ testbox.
9. Jenkins: Устанавливаем плагины Jenkins Ansible, Git, GitLab Hook, GitLab. Плагин GitLab не установится (ошибка java.net.SocketTimeoutException: connect timed out), необходимо скачать плагин на диск и установить через Manage Jenkins --> Plugin manager --> advanced --> upload plugin.
10: Jenkins: Настраиваем плагин GitLab в Manage Jenkins -> Configure System. Используем Access API Token. Для теста можно отключить опцию "Enable authentication for '/project' end-point".
11. Jenkins: Настраиваем плагин Ansible в Manage Jenkins --> Global Tool Configuration.
12. Jenkins: Создаем новую job типа freestyle job. Файл конфигурации ./test-ansible/test-ansible-jenkins-job-config.
    1. Настраиваем доступ к репозиторию на GitLab с использованием credentials разработчика. 
    2. GitLab: Добавляем к проекту webhook (Settings --> Integration).
    3. Добавить build step Ansible с настройками path: ${WORKSPACE}/test-playbook.yml, host list: ${WORKSPACE}/hosts, для доступа к testbox указать credentials пользователя root на jenkins сервере.
13. Запустить новый build. 
14. Проверить тестовое приложение на testbox по адресу http://testbox/hello.