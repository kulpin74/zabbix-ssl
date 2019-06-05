#!/usr/bin/python3.5
import json

ib_list = []
ib_list.append({"{#NAME}": "mail.ru", "{#ADDRESS}": "mail.ru", "{#SSL_PORT}": "443"})
ib_list.append({"{#NAME}": "ya.ru", "{#ADDRESS}": "ya.ru", "{#SSL_PORT}": "443"})
print(json.dumps({'data': ib_list}))
