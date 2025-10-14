package main

import (
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"

	shared "canvaslms/script/stackmanager/shared"
	"github.com/charmbracelet/bubbles/viewport"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type runState int

type actionType string

const (
	stateIntro runState = iota
	stateRunning
	stateFinished
)

const (
	actionSetup       actionType = "setup"
	actionComposeUp   actionType = "compose_up"
	actionComposeDown actionType = "compose_down"
)

type processStartedMsg struct {
	action actionType
	cmd    *exec.Cmd
	stdin  io.WriteCloser
	stdout io.ReadCloser
	stderr io.ReadCloser
	err    error
}

type readerMsg struct {
	data   string
	reader io.ReadCloser
}

type readerErrMsg struct {
	err    error
	reader io.ReadCloser
}

type exitMsg struct {
	err error
}

type model struct {
	state    runState
	action   actionType
	viewport viewport.Model
	width    int
	height   int

	logBuffer strings.Builder
	input     []rune

	cmd    *exec.Cmd
	stdin  io.WriteCloser
	stdout io.ReadCloser
	stderr io.ReadCloser
	exit   error
}

func initialModel() model {
	vp := viewport.New(80, 20)
	vp.SetContent("")
	return model{
		state:    stateIntro,
		action:   actionSetup,
		viewport: vp,
	}
}

func (m model) Init() tea.Cmd {
	return nil
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		vh := msg.Height - 6
		if vh < 5 {
			vh = 5
		}
		m.viewport.Width = msg.Width - 4
		if m.viewport.Width < 20 {
			m.viewport.Width = msg.Width
		}
		m.viewport.Height = vh
		return m, nil
	case tea.KeyMsg:
		switch m.state {
		case stateIntro:
			return m.handleIntroKeys(msg)
		case stateRunning:
			return m.handleRunningKeys(msg)
		case stateFinished:
			return m.handleFinishedKeys(msg)
		}
	case processStartedMsg:
		if msg.err != nil {
			m.exit = msg.err
			m.state = stateFinished
			m.action = msg.action
			m.appendOutput(fmt.Sprintf("\n✖ failed to start command: %v\n", msg.err))
			return m, nil
		}
		m.action = msg.action
		m.cmd = msg.cmd
		m.stdin = msg.stdin
		m.stdout = msg.stdout
		m.stderr = msg.stderr
		m.state = stateRunning
		return m, tea.Batch(
			streamReaderCmd(m.stdout),
			streamReaderCmd(m.stderr),
			waitForExitCmd(m.cmd),
		)
	case readerMsg:
		m.appendOutput(msg.data)
		return m, streamReaderCmd(msg.reader)
	case readerErrMsg:
		if !errors.Is(msg.err, io.EOF) {
			m.appendOutput(fmt.Sprintf("\n[error reading output: %v]\n", msg.err))
		}
		return m, nil
	case exitMsg:
		if m.stdin != nil {
			_ = m.stdin.Close()
		}
		if m.stdout != nil {
			_ = m.stdout.Close()
		}
		if m.stderr != nil {
			_ = m.stderr.Close()
		}
		m.cmd = nil
		m.stdin = nil
		m.stdout = nil
		m.stderr = nil
		m.exit = msg.err
		m.state = stateFinished
		switch m.action {
		case actionSetup:
			if msg.err == nil {
				m.appendOutput("\n✔ docker_dev_setup.sh completed successfully.\n")
			} else {
				m.appendOutput(fmt.Sprintf("\n✖ docker_dev_setup.sh exited with error: %v\n", msg.err))
			}
		case actionComposeUp:
			if msg.err == nil {
				m.appendOutput("\n✔ Docker services started (docker compose up -d).\n")
			} else {
				m.appendOutput(fmt.Sprintf("\n✖ docker compose up failed: %v\n", msg.err))
			}
		case actionComposeDown:
			if msg.err == nil {
				m.appendOutput("\n✔ Docker services stopped (docker compose down).\n")
			} else {
				m.appendOutput(fmt.Sprintf("\n✖ docker compose down failed: %v\n", msg.err))
			}
		}
		return m, nil
	}
	return m, nil
}

func (m model) handleIntroKeys(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "ctrl+c", "q", "esc":
		return m, tea.Quit
	case "enter", "s":
		m.appendOutput("\nStarting docker_dev_setup.sh …\n\n")
		return m, startSetupCmd()
	}
	return m, nil
}

func (m model) handleRunningKeys(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	if msg.Type == tea.KeyCtrlC {
		m.appendOutput("\nUser requested cancel.\n")
		if m.cmd != nil && m.cmd.Process != nil {
			_ = m.cmd.Process.Signal(os.Interrupt)
		}
		return m, nil
	}

	if m.action != actionSetup {
		var cmd tea.Cmd
		m.viewport, cmd = m.viewport.Update(msg)
		return m, cmd
	}

	if msg.Type == tea.KeyBackspace || msg.String() == "backspace2" {
		if len(m.input) > 0 {
			m.input = m.input[:len(m.input)-1]
		}
		return m, nil
	}

	switch msg.Type {
	case tea.KeyCtrlL:
		m.viewport.GotoBottom()
		return m, nil
	case tea.KeyEnter:
		if m.stdin != nil {
			_, _ = m.stdin.Write([]byte(string(m.input) + "\n"))
		}
		m.input = m.input[:0]
		return m, nil
	}

	if len(msg.Runes) == 1 && !msg.Alt {
		r := msg.Runes[0]
		if r != 0 && r != '\r' && r != '\n' {
			m.input = append(m.input, r)
			return m, nil
		}
	}

	var cmd tea.Cmd
	m.viewport, cmd = m.viewport.Update(msg)
	return m, cmd
}

func (m model) handleFinishedKeys(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "ctrl+c", "q", "esc":
		return m, tea.Quit
	case "r":
		m.resetForSetup()
		m.appendOutput("\nRestarting docker_dev_setup.sh …\n\n")
		return m, startSetupCmd()
	case "u":
		return m.startComposeAction(actionComposeUp)
	case "d":
		return m.startComposeAction(actionComposeDown)
	}
	return m, nil
}

func (m *model) resetForSetup() {
	m.state = stateIntro
	m.action = actionSetup
	m.input = nil
	m.exit = nil
}

func (m model) startComposeAction(action actionType) (tea.Model, tea.Cmd) {
	dockerCmd, args, stack := composeCommand(action)
	display := fmt.Sprintf("%s %s (stack: %s)", dockerCmd, strings.Join(args, " "), stack)
	switch action {
	case actionComposeUp:
		m.appendOutput("\nRunning docker compose up -d …\n" + display + "\n\n")
	case actionComposeDown:
		m.appendOutput("\nRunning docker compose down …\n" + display + "\n\n")
	}
	m.state = stateRunning
	m.action = action
	m.input = nil
	return m, startProcessCmd(action, dockerCmd, args, nil, false)
}

func (m *model) appendOutput(text string) {
	m.logBuffer.WriteString(text)
	m.viewport.SetContent(m.logBuffer.String())
	m.viewport.GotoBottom()
}

func (m model) View() string {
	switch m.state {
	case stateIntro:
		return introView(m)
	case stateRunning:
		return runningView(m)
	case stateFinished:
		return finishedView(m)
	default:
		return ""
	}
}

func introView(m model) string {
	title := lipgloss.NewStyle().Bold(true).Render("Canvas Docker Setup (TUI)")
	body := "This walkthrough wraps script/docker_dev_setup.sh with a terminal UI.\n\n" +
		"Press Enter to start the setup.\n" +
		"Press q to exit.\n"
	return lipgloss.JoinVertical(lipgloss.Left, title, "", body)
}

func runningView(m model) string {
	title := lipgloss.NewStyle().Bold(true).Render(actionTitle(m.action))
	var b strings.Builder
	b.WriteString(title)
	b.WriteString("\n\n")
	b.WriteString(m.viewport.View())
	b.WriteString("\n")
	if m.action == actionSetup {
		prompt := lipgloss.NewStyle().Foreground(lipgloss.Color("241")).Render("> " + string(m.input))
		b.WriteString(prompt)
		b.WriteString("\n")
		help := lipgloss.NewStyle().Foreground(lipgloss.Color("241")).Render("Enter: send input  •  Ctrl+C: cancel  •  q: quit")
		b.WriteString(help)
	} else {
		help := lipgloss.NewStyle().Foreground(lipgloss.Color("241")).Render("Ctrl+C: cancel  •  q: quit")
		b.WriteString(help)
	}
	return b.String()
}

func finishedView(m model) string {
	title := lipgloss.NewStyle().Bold(true).Render("docker_dev_setup.sh finished")
	status := "Success!"
	if m.exit != nil {
		status = fmt.Sprintf("Exited with error: %v", m.exit)
	}
	options := []string{
		"u – docker compose up -d",
		"d – docker compose down",
		"r – rerun setup",
		"q – quit",
	}
	body := lipgloss.JoinVertical(
		lipgloss.Left,
		title,
		"",
		status,
		"",
		m.viewport.View(),
		"",
		strings.Join(options, "\n"),
	)
	return body
}

func actionTitle(action actionType) string {
	switch action {
	case actionSetup:
		return "Running docker_dev_setup.sh"
	case actionComposeUp:
		return "Running docker compose up"
	case actionComposeDown:
		return "Running docker compose down"
	default:
		return "Running command"
	}
}

func startSetupCmd() tea.Cmd {
	extraEnv := []string{"CANVAS_DOCKER_SETUP_TUI=1"}
	return startProcessCmd(actionSetup, "bash", []string{"script/docker_dev_setup.sh"}, extraEnv, true)
}

func startProcessCmd(action actionType, name string, args []string, extraEnv []string, attachInput bool) tea.Cmd {
	return func() tea.Msg {
		cmd := exec.Command(name, args...)
		env := append(os.Environ(), extraEnv...)
		cmd.Env = env
		var stdin io.WriteCloser
		var err error
		if attachInput {
			stdin, err = cmd.StdinPipe()
			if err != nil {
				return processStartedMsg{action: action, err: err}
			}
		}
		stdout, err := cmd.StdoutPipe()
		if err != nil {
			return processStartedMsg{action: action, err: err}
		}
		stderr, err := cmd.StderrPipe()
		if err != nil {
			return processStartedMsg{action: action, err: err}
		}
		if err := cmd.Start(); err != nil {
			return processStartedMsg{action: action, err: err}
		}
		return processStartedMsg{
			action: action,
			cmd:    cmd,
			stdin:  stdin,
			stdout: stdout,
			stderr: stderr,
		}
	}
}

func streamReaderCmd(r io.ReadCloser) tea.Cmd {
	return func() tea.Msg {
		buf := make([]byte, 4096)
		n, err := r.Read(buf)
		if n > 0 {
			return readerMsg{data: string(buf[:n]), reader: r}
		}
		if err != nil {
			return readerErrMsg{err: err, reader: r}
		}
		return nil
	}
}

func waitForExitCmd(cmd *exec.Cmd) tea.Cmd {
	return func() tea.Msg {
		err := cmd.Wait()
		return exitMsg{err: err}
	}
}

func composeCommand(action actionType) (string, []string, string) {
	stack := shared.DetectStack(".")
	dockerCmd := dockerBinary()
	args := []string{"compose"}
	if extra := shared.ComposeArgs(stack); len(extra) > 0 {
		args = append(args, extra...)
	}
	switch action {
	case actionComposeUp:
		args = append(args, "up", "-d")
	case actionComposeDown:
		args = append(args, "down")
	}
	return dockerCmd, args, stack
}

func dockerBinary() string {
	if val := strings.TrimSpace(os.Getenv("DOCKER")); val != "" {
		return val
	}
	return "docker"
}

func main() {
	if _, err := os.Stat("script/docker_dev_setup.sh"); err != nil {
		fmt.Fprintf(os.Stderr, "docker_dev_setup.sh not found: %v\n", err)
		os.Exit(1)
	}

	p := tea.NewProgram(initialModel(), tea.WithAltScreen())
	if err := p.Start(); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}
