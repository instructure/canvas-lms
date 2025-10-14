package main

import (
	"strings"
	"testing"

	shared "canvaslms/script/stackmanager/shared"
)

func TestIntroViewMentionsStartInstruction(t *testing.T) {
	view := introView(initialModel())
	if !strings.Contains(view, "Press Enter to start") {
		t.Fatalf("intro view should prompt user to start, got:\n%s", view)
	}
}

func TestRunningViewAppendsOutput(t *testing.T) {
	m := initialModel()
	m.state = stateRunning
	m.action = actionSetup
	m.appendOutput("hello\n")
	if !strings.Contains(m.viewport.View(), "hello") {
		t.Fatalf("viewport should contain appended output, got %q", m.viewport.View())
	}
}

func TestComposeArgsForStack(t *testing.T) {
	arch := append([]string{"compose"}, shared.ComposeArgs("arch")...)
	if strings.Join(arch, " ") != "compose -f docker-compose.arch.yml" {
		t.Fatalf("unexpected arch args: %v", arch)
	}
	alpine := append([]string{"compose"}, shared.ComposeArgs("alpine")...)
	if strings.Join(alpine, " ") != "compose -f docker-compose.alpine.yml" {
		t.Fatalf("unexpected alpine args: %v", alpine)
	}
	def := append([]string{"compose"}, shared.ComposeArgs("default")...)
	if strings.Join(def, " ") != "compose" {
		t.Fatalf("unexpected default args: %v", def)
	}
}
