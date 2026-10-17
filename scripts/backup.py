#!/usr/bin/env python3
import os,datetime,subprocess,hashlib,json
from pathlib import Path
p=Path(__file__).resolve().parents[1];os.chdir(p);os.umask(0o077)
def dc(*args,**kw):return subprocess.run(['docker','compose',*args],check=True,**kw)
if not (p/'.env').is_file():raise SystemExit('Falta .env')
if not dc('ps','--status','running','-q','app',capture_output=True,text=True).stdout.strip():raise SystemExit('Shlink no esta activo en este contexto')
b=p/'backups'/datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ');b.mkdir(parents=True)
try:
 dc('stop','app')
 with (b/'public.dump').open('wb') as out:
  dc('run','--rm','--no-deps','-T','--entrypoint','pg_dump','dbtools','--format=custom','--schema=public','--no-owner','--no-acl',stdout=out)
 for n in ['.env','compose.yaml']:(b/n).write_bytes((p/n).read_bytes())
 hashes={}
 for n in ['public.dump','.env','compose.yaml']:
  with (b/n).open('rb') as f:hashes[n]=hashlib.file_digest(f,'sha256').hexdigest()
 (b/'manifest.json').write_text(json.dumps({'version':'5.1.7','status':'completed','sha256':hashes},indent=2))
finally:dc('start','app')
print(f'Respaldo de enlaces y visitas: {b}. Guardar también este kit y la CA; cifrar y copiar fuera del VPS.')
