package main

import (
	"strings"
	"testing"
)

func TestIndexOfStack(t *testing.T) {
	t.Parallel()

	tests := []struct {
		in   string
		want int
	}{
		{"default", 0},
		{" DEFAULT ", 0},
		{"arch", 1},
		{"AlPiNe", 2},
		{"unknown", 0},
		{"", 0},
	}

	for _, tc := range tests {
		if got := indexOfStack(tc.in); got != tc.want {
			t.Fatalf("indexOfStack(%q) = %d, want %d", tc.in, got, tc.want)
		}
	}
}

func TestSanitizeStack(t *testing.T) {
	t.Parallel()

	tests := []struct {
		in   string
		want string
	}{
		{"arch", "arch"},
		{"ALPINE", "alpine"},
		{" default ", "default"},
		{"", "default"},
		{"unknown", "default"},
	}

	for _, tc := range tests {
		if got := sanitizeStack(tc.in); got != tc.want {
			t.Fatalf("sanitizeStack(%q) = %q, want %q", tc.in, got, tc.want)
		}
	}
}

func TestFallbackValue(t *testing.T) {
	t.Parallel()

	if got := fallbackValue("hello"); got != "hello" {
		t.Fatalf("fallbackValue(\"hello\") = %q, want %q", got, "hello")
	}

	if got := fallbackValue("   "); got != "<none>" {
		t.Fatalf("fallbackValue(\"   \") = %q, want <none>", got)
	}

	if got := fallbackValue(""); got != "<none>" {
		t.Fatalf("fallbackValue(\"\") = %q, want <none>", got)
	}
}

func TestStackComposeArgs(t *testing.T) {
	t.Parallel()

	tests := []struct {
		stack string
		want  []string
	}{
		{"default", nil},
		{"arch", []string{"-f", "docker-compose.arch.yml"}},
		{"alpine", []string{"-f", "docker-compose.alpine.yml"}},
		{"ArCh", []string{"-f", "docker-compose.arch.yml"}},
		{"unknown", nil},
	}

	for _, tc := range tests {
		got := stackComposeArgs(tc.stack)
		if len(got) != len(tc.want) {
			t.Fatalf("stackComposeArgs(%q) length = %d, want %d", tc.stack, len(got), len(tc.want))
		}
		for i := range got {
			if got[i] != tc.want[i] {
				t.Fatalf("stackComposeArgs(%q)[%d] = %q, want %q", tc.stack, i, got[i], tc.want[i])
			}
		}
	}
}

func TestNewComposeRunnerDefault(t *testing.T) {
	t.Parallel()

	runner := newComposeRunnerFromValues("docker", "")
	cmd := runner.command("arch", "ps")

	if len(cmd.Args) == 0 {
		t.Fatalf("command args empty")
	}

	wantArgs := []string{"docker", "compose", "-f", "docker-compose.arch.yml", "ps"}
	if diff := compareArgs(cmd.Args, wantArgs); diff != "" {
		t.Fatalf("command args diff:\n%s", diff)
	}
}

func TestNewComposeRunnerFromComposeEnv(t *testing.T) {
	t.Parallel()

	runner := newComposeRunnerFromValues("docker-custom", "podman compose --ansi never")
	cmd := runner.command("default", "up", "-d")

	if len(cmd.Args) == 0 {
		t.Fatalf("command args empty")
	}

	wantArgs := []string{"podman", "compose", "--ansi", "never", "up", "-d"}
	if diff := compareArgs(cmd.Args, wantArgs); diff != "" {
		t.Fatalf("command args diff:\n%s", diff)
	}
}

func TestCompactRubyStripsWhitespace(t *testing.T) {
	t.Parallel()

	input := `
puts "hello"

if true
  puts "inner"
end
`
	output := compactRuby(input)
	if output == input {
		t.Fatalf("compactRuby did not modify the input")
	}
	if len(output) == 0 {
		t.Fatalf("compactRuby returned empty string")
	}
	if strings.Contains(output, "\n") {
		t.Fatalf("compactRuby output still contains newline: %q", output)
	}
}

func compareArgs(got, want []string) string {
	if len(got) != len(want) {
		return formatArgsDiff(got, want)
	}
	for i := range got {
		if got[i] != want[i] {
			return formatArgsDiff(got, want)
		}
	}
	return ""
}

func formatArgsDiff(got, want []string) string {
	return "got: " + strings.Join(got, " ") + "\nwant: " + strings.Join(want, " ")
}
