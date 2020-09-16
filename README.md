## Checking domain dame expiration date and SSL validity
The standard approach assumes creating a host for each checked name, which is inconvenient and redundant, since several names can be bound to one ip address.
The concept of collecting all monitored names into one node has been implemented. LLD is used for discovery.

Name's list are in json file and it used for getting domain names for expiration check too.

Put all the files `externalscripts/*` in the path for external Zabbix scripts, make the *.sh files executable: `chmod +x zext_ssl_cert.sh list.sh whois_expire.sh`.
In the file `ssl_check.json` enter data for monitoring.

## Проверка даты регистрации доменных имен и действительности SSL сертификатов
Стандартный шаблон предполагает создание узла сети на каждое проверяемое имя, что неудобно и избыточно, так как несколько имен может быть привязано к одному ip адресу.
Реализована концепция сбора всех наблюдаемых имен в один узел. Для обнаружения используется LLD.

Список имен забирается из json файла.

Из этого же списка выделяются доменные имена при помощи предобработки.

Необходимо положить все файлы `externalscripts/*` в каталог внешних скриптов Zabbix, файлы *.sh сделать исполняемыми: `chmod +x zext_ssl_cert.sh list.sh whois_expire.sh`. 
В файл `ssl_check.json` внести данные для мониторинга по аналогии с примером. 
