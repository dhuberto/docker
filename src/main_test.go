// =============================================================================
// main_test.go — testes unitários
// =============================================================================
// Roda com: go test ./...
// Não precisa de banco — só verifica comportamento dos handlers.
// =============================================================================

package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// TestExcluirIDInvalido testa que ID não numérico retorna 400.
func TestExcluirIDInvalido(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/excluir/abc", nil)
	rec := httptest.NewRecorder()

	excluir(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("esperado 400, recebeu %d", rec.Code)
	}
	if !strings.Contains(rec.Body.String(), "ID inválido") {
		t.Errorf("esperado mensagem 'ID inválido', recebeu: %s", rec.Body.String())
	}
}

// TestCadastrarMetodoErrado testa que GET em /cadastrar retorna 405.
func TestCadastrarMetodoErrado(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/cadastrar", nil)
	rec := httptest.NewRecorder()

	cadastrar(rec, req)

	if rec.Code != http.StatusMethodNotAllowed {
		t.Errorf("esperado 405, recebeu %d", rec.Code)
	}
}

// TestIndexRotaInexistente testa que path diferente de / retorna 404.
func TestIndexRotaInexistente(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/qualquer-coisa", nil)
	rec := httptest.NewRecorder()

	index(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Errorf("esperado 404, recebeu %d", rec.Code)
	}
}

// TestTemplateCompila garante que o template HTML não tem erro de sintaxe.
func TestTemplateCompila(t *testing.T) {
	if _, err := parseTemplate(); err != nil {
		t.Errorf("template não compila: %v", err)
	}
}
