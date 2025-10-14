package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"strings"
)

type appMode string

const (
	modeStack   appMode = "stack"
	modeToolbox appMode = "toolbox"
)

func main() {
	modeFlag := flag.String("mode", string(modeStack), "run mode: stack (default) or toolbox")
	defaultStack := flag.String("default", "default", "default stack to use when no choice is made")
	prompt := flag.String("prompt", "Select docker stack", "prompt message")
	historyPath := flag.String("history-path", "", "path to the history file (for debug display)")
	historyValue := flag.String("history-value", "", "last recorded stack selection (for debug display)")
	persistedPath := flag.String("persisted-path", "", "path to the persisted stack file (for debug display)")
	persistedValue := flag.String("persisted-value", "", "persisted stack value (for debug display)")
	stackValue := flag.String("stack-value", "", "raw stack value passed in from the caller (for debug display)")
	repoRootFlag := flag.String("repo-root", "", "override repository root used for helper commands")
	flag.Parse()

	mode := appMode(strings.ToLower(strings.TrimSpace(*modeFlag)))
	if mode != modeStack && mode != modeToolbox {
		fmt.Fprintf(os.Stderr, "unknown mode %q (expected stack or toolbox)\n", *modeFlag)
		os.Exit(1)
	}

	workingDir, err := os.Getwd()
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to determine working directory: %v\n", err)
		os.Exit(1)
	}

	repoRoot := strings.TrimSpace(*repoRootFlag)
	if repoRoot == "" {
		repoRoot = defaultRepoRoot(workingDir)
	}

	ctx := stackContext{
		defaultStack:   strings.TrimSpace(*defaultStack),
		stackValue:     strings.TrimSpace(*stackValue),
		historyPath:    strings.TrimSpace(*historyPath),
		historyValue:   strings.TrimSpace(*historyValue),
		persistedPath:  strings.TrimSpace(*persistedPath),
		persistedValue: strings.TrimSpace(*persistedValue),
		workingDir:     workingDir,
		repoRoot:       repoRoot,
		goVersion:      runtime.Version(),
	}

	switch mode {
	case modeStack:
		if err := runStackCLI(ctx, strings.TrimSpace(*prompt)); err != nil {
			fmt.Fprintf(os.Stderr, "failed to render stack selector: %v\n", err)
			os.Exit(1)
		}
	case modeToolbox:
		if err := runToolbox(ctx); err != nil {
			fmt.Fprintf(os.Stderr, "developer toolbox failed: %v\n", err)
			os.Exit(1)
		}
	}
}

func defaultRepoRoot(current string) string {
	dir := current
	for {
		if hasRepoMarker(dir) {
			return dir
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			break
		}
		dir = parent
	}
	return current
}

func hasRepoMarker(dir string) bool {
	markers := []string{
		filepath.Join(dir, ".git"),
		filepath.Join(dir, "docker-compose.yml"),
		filepath.Join(dir, "docker-compose.arch.yml"),
		filepath.Join(dir, "docker-compose.alpine.yml"),
	}
	for _, marker := range markers {
		if _, err := os.Stat(marker); err == nil {
			return true
		}
	}
	return false
}
