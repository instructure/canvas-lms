package shared

import (
	"os"
	"path/filepath"
	"testing"
)

func TestNormalize(t *testing.T) {
	if got := Normalize(" ARCH \n"); got != "arch" {
		t.Fatalf("Normalize returned %q, want arch", got)
	}
	if got := Normalize("unknown"); got != "default" {
		t.Fatalf("Normalize returned %q, want default", got)
	}
}

func TestComposeArgs(t *testing.T) {
	if args := ComposeArgs("arch"); len(args) != 2 || args[1] != "docker-compose.arch.yml" {
		t.Fatalf("unexpected compose args: %v", args)
	}
	if args := ComposeArgs("default"); len(args) != 0 {
		t.Fatalf("expected no args for default, got %v", args)
	}
}

func TestDetectStackRespectsFiles(t *testing.T) {
	dir := t.TempDir()
	if got := DetectStack(dir); got != "default" {
		t.Fatalf("expected default, got %q", got)
	}
	if err := os.WriteFile(filepath.Join(dir, ".canvas-stack"), []byte("arch\n"), 0o644); err != nil {
		t.Fatalf("write stack file: %v", err)
	}
	if got := DetectStack(dir); got != "arch" {
		t.Fatalf("expected arch, got %q", got)
	}
}
