# Datos personales — Acortador de enlaces (Shlink)

Contrato del kit `hefesto-enlaces-shlink-supabase` bajo la **Ley 21.719** (Proteccion de Datos
Personales, Chile). Este documento es normativo para el kit: el despliegue no
se considera completo sin el.

## 1. Inventario de datos

Shlink registra **visitas**: direccion IP, user-agent, referrer, pais, navegador, sistema operativo, fecha y hora, y la URL de destino visitada. La combinacion de IP, fecha y URL identifica a una persona. El kit administra ademas las **campanas**, que son segmentaciones de publico.

## 2. Control de acceso y roles

El rol de base `POSTGRES_USERNAME` (`shlink_app`) es de aplicacion. El panel de Shlink se publica por el proxy del orquestador; el kit no expone la API sin autenticacion.

## 3. Minimizacion

Un acortador existe para medir. Si el negocio no usa la URL de origen completa, no se necesita: la recoleccion de estadisticas puede desactivarse y el kit lo documenta. `TRUSTED_PROXIES` debe listar solo los proxies reales: una lista incorrecta resuelve mal la IP del visitante.

## 4. Retencion

Shlink retiene las visitas por defecto **12 meses**. El kit propone **6 meses** para el historico agregado y **7 dias** para el respaldo verificado. El borrado de visitas es una operacion sobre la base y la documenta el cliente.

## 5. Supresion, rectificacion y acceso del titular

Una peticion de supresion se resuelve eliminando o anonimizando las visitas de esa persona y, si corresponde, las campanas que la segmentaron. Cada campana debe tener un proposito documentado: una campana sin proposito no debe existir. El kit no borra datos por su cuenta; deja el procedimiento.

## 6. Acceso al respaldo, auditoria y transito

El respaldo sale cifrado cuando hay receptor age. `backups/` en 0700 y auditoria de restauracion en `logs/restore-audit.log`.

### Acceso al respaldo y transito

`DB_SSLMODE` por defecto `verify-full` con CA de Supabase. TLS de la publicacion, en Coolify/Traefik.

## 7. Que NO decide el kit

Los plazos definitivos, la base legal y la incorporacion de los titulares al
registro de actividades de tratamiento son decisiones **del cliente**, no del
kit. Este documento deja la propuesta escrita y verificable; su validacion es
una tarea pendiente de coordinacion.

## 8. Verificacion

```bash
bats tests/                              # ciclo de respaldo con datos sinteticos
python3 scripts/check-env.py --modo real # contrato del .env, sin imprimir valores
python3 scripts/check_backup.py <respaldo>
```
