#!/usr/bin/env python3
import argparse
from urllib.parse import urlsplit,urlunsplit,parse_qsl,urlencode
p=argparse.ArgumentParser(description='Añade UTM sin llamar a servicios externos')
p.add_argument('url');p.add_argument('--source',required=True);p.add_argument('--medium',required=True);p.add_argument('--campaign',required=True)
a=p.parse_args();u=urlsplit(a.url)
if u.scheme not in ['https','http'] or not u.netloc or u.username or u.password:raise SystemExit('Usar URL HTTP(S) sin credenciales')
q=dict(parse_qsl(u.query,keep_blank_values=True));q.update(utm_source=a.source,utm_medium=a.medium,utm_campaign=a.campaign)
print(urlunsplit((u.scheme,u.netloc,u.path,urlencode(q),u.fragment)))
