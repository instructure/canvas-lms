package main

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"strings"

	shared "canvaslms/script/stackmanager/shared"
	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
)

type toolboxViewState int

const (
	stateMainMenu toolboxViewState = iota
	stateAdminMenu
	stateDockerMenu
	stateForm
	stateCommandOutput
	stateStackInfo
	stateStackSelect
)

type toolboxFormAction int

const (
	formNone toolboxFormAction = iota
	formEnsureAdmin
	formRemoveAdmin
	formTailLogs
)

const fallbackAdminPassword = "CanvasAdmin#2025"

type commandMsg struct {
	title  string
	output string
	err    error
}

type composeRunner struct {
	binary     string
	args       []string
	dockerPath string
}

type toolboxModel struct {
	ctx          stackContext
	compose      composeRunner
	stack        string
	state        toolboxViewState
	returnState  toolboxViewState
	menuCursor   int
	adminCursor  int
	dockerCursor int
	status       string
	output       string
	outputTitle  string
	outputErr    error
	busy         bool

	formAction toolboxFormAction
	formInputs []textinput.Model
	formLabels []string
	formIndex  int

	stackSelector *stackModel
}

func runToolbox(ctx stackContext) error {
	stack := ctx.defaultStack
	if stack == "" {
		stack = stackOptions[0]
	}
	stack = sanitizeStack(stack)

	model := toolboxModel{
		ctx:     ctx,
		compose: newComposeRunner(),
		stack:   stack,
		state:   stateMainMenu,
		status:  "Select an option. Press s at any time to change the stack.",
	}

	program := tea.NewProgram(model)
	_, err := program.Run()
	return err
}

func (m toolboxModel) Init() tea.Cmd {
	return nil
}

func (m toolboxModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch m.state {
		case stateMainMenu:
			return m.updateMainMenu(msg)
		case stateAdminMenu:
			return m.updateAdminMenu(msg)
		case stateDockerMenu:
			return m.updateDockerMenu(msg)
		case stateForm:
			return m.updateForm(msg)
		case stateCommandOutput:
			return m.updateCommandOutput(msg)
		case stateStackInfo:
			return m.updateStackInfo(msg)
		case stateStackSelect:
			return m.updateStackSelect(msg)
		}
	case commandMsg:
		m.busy = false
		m.output = msg.output
		m.outputTitle = msg.title
		m.outputErr = msg.err
		if msg.err != nil {
			m.status = fmt.Sprintf("%s failed: %v", msg.title, msg.err)
		} else {
			m.status = fmt.Sprintf("%s completed.", msg.title)
		}
		return m, nil
	}

	return m, nil
}

func (m toolboxModel) View() string {
	var b strings.Builder

	switch m.state {
	case stateMainMenu:
		b.WriteString("\nCanvas Dev Toolbox\n")
		b.WriteString("------------------\n")
		b.WriteString(fmt.Sprintf("Current stack: %s\n\n", m.stack))
		menu := []string{
			"Admin tools",
			"Docker diagnostics",
			"Stack & history",
			"Quit",
		}
		for i, item := range menu {
			cursor := " "
			if i == m.menuCursor {
				cursor = "▶"
			}
			fmt.Fprintf(&b, "  %s %s\n", cursor, item)
		}
	case stateAdminMenu:
		b.WriteString("\nAdmin Tools\n")
		b.WriteString("-----------\n")
		b.WriteString(fmt.Sprintf("Stack: %s\n\n", m.stack))
		options := []string{
			"Ensure admin (create/update)",
			"List admin users",
			"Remove admin user",
			"Back",
		}
		for i, item := range options {
			cursor := " "
			if i == m.adminCursor {
				cursor = "▶"
			}
			fmt.Fprintf(&b, "  %s %s\n", cursor, item)
		}
	case stateDockerMenu:
		b.WriteString("\nDocker Diagnostics\n")
		b.WriteString("------------------\n")
		b.WriteString(fmt.Sprintf("Stack: %s\n\n", m.stack))
		options := []string{
			"Check docker daemon",
			"Show compose services",
			"Tail service logs (last 100 lines)",
			"Back",
		}
		for i, item := range options {
			cursor := " "
			if i == m.dockerCursor {
				cursor = "▶"
			}
			fmt.Fprintf(&b, "  %s %s\n", cursor, item)
		}
	case stateStackInfo:
		b.WriteString("\nStack Information\n")
		b.WriteString("-----------------\n")
		fmt.Fprintf(&b, "Active stack         : %s\n", m.stack)
		fmt.Fprintf(&b, "Default stack        : %s\n", fallbackValue(m.ctx.defaultStack))
		fmt.Fprintf(&b, "STACK env override   : %s\n", fallbackValue(m.ctx.stackValue))
		fmt.Fprintf(&b, "Persisted stack file : %s\n", fallbackValue(m.ctx.persistedPath))
		fmt.Fprintf(&b, "Persisted value      : %s\n", fallbackValue(m.ctx.persistedValue))
		fmt.Fprintf(&b, "History file         : %s\n", fallbackValue(m.ctx.historyPath))
		fmt.Fprintf(&b, "Last history value   : %s\n", fallbackValue(m.ctx.historyValue))
		fmt.Fprintf(&b, "Repo root            : %s\n", fallbackValue(m.ctx.repoRoot))
		fmt.Fprintf(&b, "Working directory    : %s\n", fallbackValue(m.ctx.workingDir))
		fmt.Fprintf(&b, "Go runtime           : %s\n", fallbackValue(m.ctx.goVersion))
		b.WriteString("\nPress enter/esc to go back.")
	case stateForm:
		b.WriteString("\n")
		for i, input := range m.formInputs {
			label := m.formLabels[i]
			fmt.Fprintf(&b, "%s\n%s\n\n", label, input.View())
		}
		b.WriteString("Press enter to continue, tab to switch fields, esc to cancel.\n")
	case stateCommandOutput:
		b.WriteString("\n")
		if m.outputTitle != "" {
			fmt.Fprintf(&b, "%s\n", m.outputTitle)
			b.WriteString(strings.Repeat("-", len(m.outputTitle)))
			b.WriteString("\n")
		}
		if m.busy {
			b.WriteString("\nRunning command...\n")
		} else {
			if m.outputErr != nil {
				fmt.Fprintf(&b, "\nError: %v\n\n", m.outputErr)
			}
			if strings.TrimSpace(m.output) != "" {
				b.WriteString("\n")
				b.WriteString(m.output)
				b.WriteString("\n")
			} else if m.outputErr == nil {
				b.WriteString("\n(no output)\n")
			}
			b.WriteString("\nPress enter/esc to go back.\n")
		}
	case stateStackSelect:
		if m.stackSelector != nil {
			return m.stackSelector.View()
		}
	}

	if m.status != "" && m.state != stateCommandOutput {
		b.WriteString("\n→ ")
		b.WriteString(m.status)
		b.WriteString("\n")
	}

	return b.String()
}

func (m toolboxModel) updateMainMenu(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "ctrl+c", "q":
		return m, tea.Quit
	case "down", "j":
		if m.menuCursor < 3 {
			m.menuCursor++
		} else {
			m.menuCursor = 0
		}
	case "up", "k":
		if m.menuCursor > 0 {
			m.menuCursor--
		} else {
			m.menuCursor = 3
		}
	case "enter":
		switch m.menuCursor {
		case 0:
			m.state = stateAdminMenu
			m.status = "Admin helpers ready."
		case 1:
			m.state = stateDockerMenu
			m.status = "Docker diagnostics ready."
		case 2:
			m.state = stateStackInfo
		case 3:
			return m, tea.Quit
		}
	case "s", "S":
		return m.beginStackSelection(stateMainMenu)
	}
	return m, nil
}

func (m toolboxModel) updateAdminMenu(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "ctrl+c":
		return m, tea.Quit
	case "escape":
		m.state = stateMainMenu
	case "down", "j":
		if m.adminCursor < 3 {
			m.adminCursor++
		} else {
			m.adminCursor = 0
		}
	case "up", "k":
		if m.adminCursor > 0 {
			m.adminCursor--
		} else {
			m.adminCursor = 3
		}
	case "enter":
		switch m.adminCursor {
		case 0:
			return m.prepareEnsureAdminForm()
		case 1:
			return m.runListAdmins()
		case 2:
			return m.prepareRemoveAdminForm()
		case 3:
			m.state = stateMainMenu
		}
	case "s", "S":
		return m.beginStackSelection(stateAdminMenu)
	}
	return m, nil
}

func (m toolboxModel) updateDockerMenu(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "ctrl+c":
		return m, tea.Quit
	case "escape":
		m.state = stateMainMenu
	case "down", "j":
		if m.dockerCursor < 3 {
			m.dockerCursor++
		} else {
			m.dockerCursor = 0
		}
	case "up", "k":
		if m.dockerCursor > 0 {
			m.dockerCursor--
		} else {
			m.dockerCursor = 3
		}
	case "enter":
		switch m.dockerCursor {
		case 0:
			return m.runDockerInfo()
		case 1:
			return m.runComposeServices()
		case 2:
			return m.prepareTailLogsForm()
		case 3:
			m.state = stateMainMenu
		}
	case "s", "S":
		return m.beginStackSelection(stateDockerMenu)
	}
	return m, nil
}

func (m toolboxModel) updateStackInfo(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "ctrl+c":
		return m, tea.Quit
	case "enter", "escape":
		m.state = stateMainMenu
	case "s", "S":
		return m.beginStackSelection(stateStackInfo)
	}
	return m, nil
}

func (m toolboxModel) updateForm(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "ctrl+c":
		return m, tea.Quit
	case "escape":
		return m.cancelForm()
	case "tab", "shift+tab":
		return m.shiftFormFocus(msg.String() == "shift+tab")
	case "enter":
		if m.formIndex == len(m.formInputs)-1 {
			return m.submitForm()
		}
		return m.shiftFormFocus(false)
	}

	cmds := make([]tea.Cmd, len(m.formInputs))
	for i := range m.formInputs {
		if i == m.formIndex {
			var cmd tea.Cmd
			m.formInputs[i], cmd = m.formInputs[i].Update(msg)
			cmds[i] = cmd
		}
	}
	return m, tea.Batch(cmds...)
}

func (m toolboxModel) updateCommandOutput(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	if m.busy {
		return m, nil
	}

	switch msg.String() {
	case "ctrl+c":
		return m, tea.Quit
	case "enter", "escape":
		m.state = m.returnState
		m.output = ""
		m.outputTitle = ""
		m.outputErr = nil
		m.status = ""
		return m, nil
	}
	return m, nil
}

func (m toolboxModel) updateStackSelect(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	if m.stackSelector == nil {
		return m, nil
	}

	next, cmd := m.stackSelector.Update(msg)
	selector, ok := next.(stackModel)
	if !ok {
		return m, cmd
	}
	m.stackSelector = &selector
	if selector.confirm {
		m.state = m.returnState
		if !selector.cancelled {
			choice := selector.choice
			if choice == "" {
				choice = stackOptions[selector.cursor]
			}
			m.stack = choice
			m.status = fmt.Sprintf("Stack switched to %s.", choice)
		} else {
			m.status = "Stack change cancelled."
		}
		m.stackSelector = nil
	}
	return m, cmd
}

func (m toolboxModel) shiftFormFocus(reverse bool) (tea.Model, tea.Cmd) {
	if len(m.formInputs) == 0 {
		return m, nil
	}
	m.formInputs[m.formIndex].Blur()

	if reverse {
		if m.formIndex == 0 {
			m.formIndex = len(m.formInputs) - 1
		} else {
			m.formIndex--
		}
	} else {
		if m.formIndex == len(m.formInputs)-1 {
			m.formIndex = 0
		} else {
			m.formIndex++
		}
	}

	m.formInputs[m.formIndex].Focus()
	return m, nil
}

func (m toolboxModel) cancelForm() (tea.Model, tea.Cmd) {
	m.formInputs = nil
	m.formLabels = nil
	m.formAction = formNone
	m.formIndex = 0
	m.state = m.returnState
	m.status = "Cancelled."
	return m, nil
}

func (m toolboxModel) submitForm() (tea.Model, tea.Cmd) {
	values := make([]string, len(m.formInputs))
	for i, input := range m.formInputs {
		values[i] = strings.TrimSpace(input.Value())
	}

	switch m.formAction {
	case formEnsureAdmin:
		email := values[0]
		password := values[1]
		if email == "" {
			m.status = "Email is required."
			return m, nil
		}
		if password == "" {
			password = fallbackAdminPassword
		}
		cmd := m.compose.command(m.stack,
			"run", "--rm",
			"-e", fmt.Sprintf("CANVAS_LMS_ADMIN_EMAIL=%s", email),
			"-e", fmt.Sprintf("CANVAS_LMS_ADMIN_PASSWORD=%s", password),
			"web", "bundle", "exec", "rake", "db:configure_admin",
		)
		title := fmt.Sprintf("Ensuring admin %s", email)
		return m.runCommand(title, cmd, stateAdminMenu)
	case formRemoveAdmin:
		target := values[0]
		if target == "" {
			m.status = "Email or login is required."
			return m, nil
		}
		cmd := m.compose.command(m.stack,
			"exec", "-T",
			"-e", fmt.Sprintf("TUI_ADMIN_TARGET=%s", target),
			"web", "bundle", "exec", "rails", "runner", removeAdminScript(),
		)
		title := fmt.Sprintf("Removing admin %s", target)
		return m.runCommand(title, cmd, stateAdminMenu)
	case formTailLogs:
		service := values[0]
		if service == "" {
			m.status = "Service name is required."
			return m, nil
		}
		cmd := m.compose.command(m.stack,
			"logs", "--tail", "100", service,
		)
		title := fmt.Sprintf("Logs for %s", service)
		return m.runCommand(title, cmd, stateDockerMenu)
	default:
		return m, nil
	}
}

func (m toolboxModel) runListAdmins() (tea.Model, tea.Cmd) {
	cmd := m.compose.command(m.stack,
		"exec", "-T",
		"web", "bundle", "exec", "rails", "runner", listAdminsScript(),
	)
	return m.runCommand("Listing admin users", cmd, stateAdminMenu)
}

func (m toolboxModel) runDockerInfo() (tea.Model, tea.Cmd) {
	cmd := exec.Command(m.compose.dockerPath, "info")
	cmd.Env = os.Environ()
	cmd.Dir = m.ctx.repoRoot
	return m.runCommand("docker info", cmd, stateDockerMenu)
}

func (m toolboxModel) runComposeServices() (tea.Model, tea.Cmd) {
	cmd := m.compose.command(m.stack, "ps")
	return m.runCommand("docker compose ps", cmd, stateDockerMenu)
}

func (m toolboxModel) prepareEnsureAdminForm() (tea.Model, tea.Cmd) {
	email := textinput.New()
	email.Placeholder = "admin@example.com"
	email.Prompt = "Email: "
	email.Focus()

	password := textinput.New()
	password.Placeholder = "(blank uses default CanvasAdmin#2025)"
	password.Prompt = "Password: "

	m.formInputs = []textinput.Model{email, password}
	m.formLabels = []string{"Admin email", "Admin password"}
	m.formAction = formEnsureAdmin
	m.formIndex = 0
	m.state = stateForm
	m.returnState = stateAdminMenu
	m.status = "Provide the admin email and optionally a password."
	return m, nil
}

func (m toolboxModel) prepareRemoveAdminForm() (tea.Model, tea.Cmd) {
	target := textinput.New()
	target.Placeholder = "user@school.edu"
	target.Prompt = "Email or login: "
	target.Focus()

	m.formInputs = []textinput.Model{target}
	m.formLabels = []string{"Remove admin"}
	m.formAction = formRemoveAdmin
	m.formIndex = 0
	m.state = stateForm
	m.returnState = stateAdminMenu
	m.status = "Enter the admin's email or login to remove."
	return m, nil
}

func (m toolboxModel) prepareTailLogsForm() (tea.Model, tea.Cmd) {
	service := textinput.New()
	service.Placeholder = "web"
	service.Prompt = "Service name: "
	service.Focus()

	m.formInputs = []textinput.Model{service}
	m.formLabels = []string{"Tail logs"}
	m.formAction = formTailLogs
	m.formIndex = 0
	m.state = stateForm
	m.returnState = stateDockerMenu
	m.status = "Enter the service name to tail the last 100 lines."
	return m, nil
}

func (m toolboxModel) runCommand(title string, cmd *exec.Cmd, returnState toolboxViewState) (tea.Model, tea.Cmd) {
	cmd.Dir = m.ctx.repoRoot
	cmd.Env = os.Environ()

	m.output = ""
	m.outputTitle = title
	m.outputErr = nil
	m.busy = true
	m.state = stateCommandOutput
	m.returnState = returnState

	return m, executeCommand(title, cmd)
}

func executeCommand(title string, cmd *exec.Cmd) tea.Cmd {
	return func() tea.Msg {
		var stdout bytes.Buffer
		var stderr bytes.Buffer
		cmd.Stdout = &stdout
		cmd.Stderr = &stderr
		err := cmd.Run()

		output := strings.TrimSpace(strings.Join([]string{
			strings.TrimSpace(stdout.String()),
			strings.TrimSpace(stderr.String()),
		}, "\n"))
		output = strings.Trim(output, "\n")

		return commandMsg{
			title:  title,
			output: output,
			err:    err,
		}
	}
}

func (m toolboxModel) beginStackSelection(returnState toolboxViewState) (tea.Model, tea.Cmd) {
	ctx := m.ctx
	ctx.defaultStack = m.stack
	selector := newStackModel("Select stack for helper commands", indexOfStack(m.stack), ctx)
	m.stackSelector = &selector
	m.state = stateStackSelect
	m.returnState = returnState
	return m, nil
}

func newComposeRunner() composeRunner {
	dockerPath := strings.TrimSpace(os.Getenv("DOCKER"))
	composeEnv := strings.TrimSpace(os.Getenv("COMPOSE"))
	return newComposeRunnerFromValues(dockerPath, composeEnv)
}

func newComposeRunnerFromValues(dockerPath, composeEnv string) composeRunner {
	if strings.TrimSpace(dockerPath) == "" {
		dockerPath = "docker"
	}

	if composeEnv != "" {
		parts := strings.Fields(composeEnv)
		if len(parts) == 1 {
			return composeRunner{
				binary:     parts[0],
				args:       []string{},
				dockerPath: dockerPath,
			}
		}
		return composeRunner{
			binary:     parts[0],
			args:       parts[1:],
			dockerPath: dockerPath,
		}
	}

	return composeRunner{
		binary:     dockerPath,
		args:       []string{"compose"},
		dockerPath: dockerPath,
	}
}

func (r composeRunner) command(stack string, extra ...string) *exec.Cmd {
	args := append([]string{}, r.args...)
	args = append(args, stackComposeArgs(stack)...)
	args = append(args, extra...)
	return exec.Command(r.binary, args...)
}

func stackComposeArgs(stack string) []string {
	return shared.ComposeArgs(stack)
}

func listAdminsScript() string {
	script := `
admins = Account.default.account_users.includes(user: :pseudonyms).where.not(workflow_state: 'deleted')
puts "ID\tLogin\tEmail"
admins.each do |account_user|
  user = account_user.user
  login = user&.pseudonyms&.first&.unique_id
  email = user&.email
  puts "#{user&.id}\t#{login || '-'}\t#{email || '-'}"
end
`
	return compactRuby(script)
}

func removeAdminScript() string {
	script := `
target = ENV['TUI_ADMIN_TARGET']
if target.nil? || target.strip.empty?
  puts "TUI_ADMIN_TARGET is required"
  exit 1
end
user = User.find_by(email: target)
if user.nil?
  pseudonym = Pseudonym.active.find_by(unique_id: target)
  user = pseudonym&.user
end
if user.nil?
  puts "No user found for #{target}"
  exit 1
end
account_users = Account.default.account_users.where(user: user)
if account_users.empty?
  puts "User #{target} is not an admin on the default account."
  exit 1
end
account_users.destroy_all
puts "Removed #{account_users.size} admin assignment(s) for #{target}"
`
	return compactRuby(script)
}

func compactRuby(script string) string {
	lines := strings.Split(script, "\n")
	out := make([]string, 0, len(lines))
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line != "" {
			out = append(out, line)
		}
	}
	return strings.Join(out, "; ")
}
