## Checking domain name expiration date (with RDAP support) and SSL validity
The standard approach assumes creating a host for each checked name, which is inconvenient and redundant, since several names can be bound to one ip address.
The concept of collecting all monitored names into one node has been implemented. LLD is used for discovery.

Now the general template has been divided into several, so you can only import the templates you need.

### Checking domain name expiration date

For this task you can use one of two template: 
* `Template Domain check via file` - it used for getting domain names from file
* `Template Domain check via url` - it used for getting domain names from url

### Checking SSL validity and certificate changes (fingerprint)

For this task you can use one of two template: 
* `Template SSL check via file` - it used for getting domain names from file
* `Template SSL check via url` - it used for getting domain names from url


Name's list are in json and it used to get domain names both the expiration check and SSL validity.
Example of domain names list:
```json
[
  {"url": "mail.ru", "port": "443"},
  {"url": "yandex.ru", "port": "443"}
]
```

If you use url for getting domain names you have to put the files `externalscripts/whois_expire.sh` and `externalscripts/zext_ssl_cert.sh` in the path for external Zabbix scripts and make its executable: `chmod +x zext_ssl_cert.sh whois_expire.sh`.

If you want to use file to getting domain names you have to put all the files `externalscripts/*` in the path for external Zabbix scripts, make the *.sh files executable: `chmod +x zext_ssl_cert.sh list.sh whois_expire.sh`.
In the file `ssl_check.json` enter data for monitoring.

## Проверка даты регистрации доменных имен (с поддержкой RDAP) и действительности SSL сертификатов
Стандартный шаблон предполагает создание узла сети на каждое проверяемое имя, что неудобно и избыточно, так как несколько имен может быть привязано к одному ip адресу.
Реализована концепция сбора всех наблюдаемых имен в один узел. Для обнаружения используется LLD.

Шаблон был разделен на несколько отдельных, теперь вы можете импортировать только то что вам необходимо.

### Проверка даты регистрации доменных имен

Для этой задачи используется один из двух шаблонов: 
* `Template Domain check via file` - для получения списка доменных имен из файла
* `Template Domain check via url` - для получения списка доменных имен из url

### Проверка действительности SSL и изменений сертификатов (отпечаток)

Для этой задачи используется один из двух шаблонов:
* `Template SSL check via file` - для получения списка доменных имен из файла
* `Template SSL check via url` - для получения списка доменных имен из url


Список имен сохраняется в json, и он используется для получения доменных имен и для проверки даты регистрации доменных имен и для проверки действительности SSL сертификатов.
Example of domain names list:
```json
[
  {"url": "mail.ru", "port": "443"},
  {"url": "yandex.ru", "port": "443"}
]
```

Если вы используете url для получения доенных имен необходимо положить файлы `externalscripts/whois_expire.sh` и `externalscripts/zext_ssl_cert.sh` в каталог внешних скриптов Zabbix исделать их исполняемыми: `chmod +x zext_ssl_cert.sh whois_expire.sh`.

Если вы используете файл для получения доменных имен - необходимо положить положить все файлы `externalscripts/*` в каталог внешних скриптов Zabbix, файлы *.sh сделать исполняемыми: `chmod +x zext_ssl_cert.sh list.sh whois_expire.sh`. 
В файл `ssl_check.json` внести данные для мониторинга по аналогии с примером.
