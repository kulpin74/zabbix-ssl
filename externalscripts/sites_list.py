#!/usr/bin/python3.5
import json

ib_list = []
ib_list.append({"{#NAME}": "api.sealine.ru", "{#ADDRESS}": "api.sealine.ru", "{#SSL_PORT}": "443"})
ib_list.append({"{#NAME}": "api.infratek.org", "{#ADDRESS}": "api.infratek.org", "{#SSL_PORT}": "443"})
ib_list.append({"{#NAME}": "dev.sealine.ru", "{#ADDRESS}": "dev.sealine.ru", "{#SSL_PORT}": "443"})
ib_list.append({"{#NAME}": "instore.family", "{#ADDRESS}": "instore.family", "{#SSL_PORT}": "443"})
ib_list.append({"{#NAME}": "instore.online", "{#ADDRESS}": "instore.online", "{#SSL_PORT}": "443"})
ib_list.append({"{#NAME}": "instore.travel", "{#ADDRESS}": "instore.travel", "{#SSL_PORT}": "443"})
ib_list.append({"{#NAME}": "insuri.ru", "{#ADDRESS}": "insuri.ru", "{#SSL_PORT}": "443"})
ib_list.append({"{#NAME}": "lifeguide.su", "{#ADDRESS}": "lifeguide.su", "{#SSL_PORT}": "443"})
ib_list.append({"{#NAME}": "sealine.ru", "{#ADDRESS}": "sealine.ru", "{#SSL_PORT}": "443"})
ib_list.append({"{#NAME}": "sl-tech.ru", "{#ADDRESS}": "sl-tech.ru", "{#SSL_PORT}": "443"})
ib_list.append({"{#NAME}": "mail.sl-tech.ru", "{#ADDRESS}": "mail.sl-tech.ru", "{#SSL_PORT}": "443"})
ib_list.append({"{#NAME}": "mail.sealine.ru", "{#ADDRESS}": "mail.sealine.ru", "{#SSL_PORT}": "443"})
ib_list.append({"{#NAME}": "mail.sealine.su", "{#ADDRESS}": "mail.sealine.su", "{#SSL_PORT}": "443"})
print(json.dumps({'data': ib_list}))
