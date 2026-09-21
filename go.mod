// =============================================================================
// go.mod — módulo Go
// =============================================================================
// Única dependência: lib/pq (driver PostgreSQL puro em Go).
// O driver é compilado dentro do binário — zero deps em runtime.
// =============================================================================
module theed

go 1.22

require github.com/lib/pq v1.10.9
