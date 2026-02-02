//go:build !cgo
// +build !cgo

package sql

import (
	"database/sql"
	"fmt"
	"log/slog"

	"github.com/dexidp/dex/storage"
)

// SQLite3 options for creating an SQL db.
type SQLite3 struct {
	// File to
	File string `json:"file"`
}

// Open creates a new storage implementation backed by SQLite3
func (s *SQLite3) Open(logger *slog.Logger) (storage.Storage, error) {
	conn, err := s.open(logger)
	if err != nil {
		return nil, err
	}
	return conn, nil
}

func (s *SQLite3) open(logger *slog.Logger) (*conn, error) {
	db, err := sql.Open("sqlite3", s.File)
	if err != nil {
		return nil, err
	}

	// always allow only one connection to sqlite3, any other thread/go-routine
	// attempting concurrent access will have to wait
	db.SetMaxOpenConns(1)
	errCheck := func(err error) bool {
		return true
	}

	c := &conn{db, &flavorSQLite3, logger, errCheck}
	if _, err := c.migrate(); err != nil {
		return nil, fmt.Errorf("failed to perform migrations: %v", err)
	}
	return c, nil
}