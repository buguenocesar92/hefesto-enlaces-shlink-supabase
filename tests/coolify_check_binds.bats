#!/usr/bin/env bats
# La regla de binds de scripts/coolify-check.sh queda cubierta por la suite.
# El script original se conserva; aqui se ejecuta como prueba.

load ayudante

@test "la regla de binds acepta binds dentro del repo y rechaza los externos" {
  run bash "$RAIZ/scripts/test-coolify-check-binds.sh"
  [ "$status" -eq 0 ]
}
