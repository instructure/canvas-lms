package shared

import (
	"os"
	"path/filepath"
	"strings"
)

var options = []string{"default", "arch", "alpine"}

// Options returns the supported stack identifiers.
func Options() []string {
	out := make([]string, len(options))
	copy(out, options)
	return out
}

// IndexOf returns the index of the stack in Options (default=0 when unknown).
func IndexOf(stack string) int {
	normalized := Normalize(stack)
	for i, opt := range options {
		if opt == normalized {
			return i
		}
	}
	return 0
}

// Normalize trims and lowercases the input stack, defaulting to "default" if unknown.
func Normalize(stack string) string {
	stack = strings.ToLower(strings.TrimSpace(stack))
	for _, opt := range options {
		if opt == stack {
			return opt
		}
	}
	return options[0]
}

// Fallback renders a human-friendly placeholder for empty strings.
func Fallback(value string) string {
	value = strings.TrimSpace(value)
	if value == "" {
		return "<none>"
	}
	return value
}

// ComposeArgs returns additional docker compose CLI arguments for a stack.
func ComposeArgs(stack string) []string {
	switch Normalize(stack) {
	case "arch":
		return []string{"-f", "docker-compose.arch.yml"}
	case "alpine":
		return []string{"-f", "docker-compose.alpine.yml"}
	default:
		return nil
	}
}

// DetectStack resolves the current stack preference from repository files.
func DetectStack(repoRoot string) string {
	if repoRoot == "" {
		repoRoot = "."
	}
	paths := []string{
		filepath.Join(repoRoot, ".canvas-stack"),
		filepath.Join(repoRoot, ".canvas-stack.last"),
	}
	for _, path := range paths {
		data, err := os.ReadFile(path)
		if err != nil {
			continue
		}
		trimmed := strings.TrimSpace(string(data))
		if trimmed == "" {
			continue
		}
		return Normalize(trimmed)
	}
	return options[0]
}
