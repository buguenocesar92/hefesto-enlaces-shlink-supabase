#!/usr/bin/env python3
import os,re,secrets,sys,uuid
from pathlib import Path
host=r'(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}'
if len(sys.argv)!=4 or not re.fullmatch(r'[a-z][a-z0-9-]{2,39}',sys.argv[1]) or not all(re.fullmatch(host,x) for x in sys.argv[2:]) or sys.argv[2]==sys.argv[3]:
    raise SystemExit('Uso: python3 scripts/configure.py cliente-demo go.tudominio.cl enlaces.tudominio.cl')
r=Path(__file__).resolve().parents[1]
v={'COMPOSE_PROJECT_NAME':'hefesto-enlaces-'+sys.argv[1],'LINKS_HOST':sys.argv[2],'PANEL_HOST':sys.argv[3],
'POSTGRES_HOST':'CAMBIAR_HOST_SUPABASE','POSTGRES_USERNAME':'shlink_app','POSTGRES_PASSWORD':secrets.token_hex(32),
'INITIAL_API_KEY':str(uuid.uuid4()),'SUPABASE_DEDICATED_CONFIRMED':'false','SUPABASE_DATA_API_DISABLED':'false','TRUSTED_PROXIES':'127.0.0.1'}
try:fd=os.open(r/'.env',os.O_CREAT|os.O_EXCL|os.O_WRONLY,0o600)
except FileExistsError:raise SystemExit('.env ya existe; no se modificó')
with os.fdopen(fd,'w') as f:
    for k,value in v.items():f.write(k+"='"+value+"'\n")
print('.env creado. Preparar rol DB, host y certificado según docs/supabase.md. No se conecta automáticamente.')
