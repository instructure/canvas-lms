package main

import (
	"fmt"
	"strconv"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
)

type stackModel struct {
	prompt     string
	cursor     int
	defaultIdx int
	confirm    bool
	choice     string
	showHelp   bool
	showDebug  bool
	status     string
	info       stackContext
	tips       []string
	cancelled  bool
}

func newStackModel(prompt string, defaultIdx int, info stackContext) stackModel {
	if defaultIdx < 0 || defaultIdx >= len(stackOptions) {
		defaultIdx = 0
	}

	tips := []string{
		"Run make set-stack to persist your preferred default.",
		"Prefix commands with STACK=arch (or alpine) to skip the selector in scripts.",
		"Use make dev-logs SERVICE=web to quickly tail container logs.",
	}

	return stackModel{
		prompt:     prompt,
		cursor:     defaultIdx,
		defaultIdx: defaultIdx,
		showHelp:   true,
		status:     fmt.Sprintf("Current choice: %s", stackOptions[defaultIdx]),
		info:       info,
		tips:       tips,
	}
}

func (m stackModel) Init() tea.Cmd {
	return nil
}

func (m stackModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "esc", "q":
			m.choice = stackOptions[m.defaultIdx]
			m.confirm = true
			m.cancelled = true
			m.status = "Cancelled – default stack selected."
			return m, tea.Quit
		case "enter":
			m.choice = stackOptions[m.cursor]
			m.confirm = true
			m.cancelled = false
			m.status = fmt.Sprintf("Using %s stack.", m.choice)
			return m, tea.Quit
		case "up", "k":
			if m.cursor > 0 {
				m.cursor--
			} else {
				m.cursor = len(stackOptions) - 1
			}
			m.status = fmt.Sprintf("Current choice: %s", stackOptions[m.cursor])
		case "down", "j":
			if m.cursor < len(stackOptions)-1 {
				m.cursor++
			} else {
				m.cursor = 0
			}
			m.status = fmt.Sprintf("Current choice: %s", stackOptions[m.cursor])
		case "h", "?":
			m.showHelp = !m.showHelp
			if m.showHelp {
				m.status = "Help panel enabled."
			} else {
				m.status = "Help panel hidden."
			}
		case "d":
			m.showDebug = !m.showDebug
			if m.showDebug {
				m.status = "Debug panel enabled."
			} else {
				m.status = "Debug panel hidden."
			}
		case "ctrl+r":
			m.cursor = m.defaultIdx
			m.status = fmt.Sprintf("Reset to default: %s", stackOptions[m.cursor])
		case "ctrl+l":
			m.status = ""
		default:
			if idx, ok := parseNumberSelection(msg.String(), len(stackOptions)); ok {
				m.cursor = idx
				m.status = fmt.Sprintf("Current choice: %s", stackOptions[m.cursor])
			}
		}
	}

	return m, nil
}

func (m stackModel) View() string {
	if m.confirm {
		return ""
	}

	var b strings.Builder
	b.WriteString("\n")
	b.WriteString(m.prompt)
	b.WriteString("\n\n")

	for i, opt := range stackOptions {
		cursor := " "
		if i == m.cursor {
			cursor = "▶"
		}

		defaultTag := ""
		if i == m.defaultIdx {
			defaultTag = " (default)"
		}

		fmt.Fprintf(&b, "  %s %d) %s%s\n", cursor, i+1, opt, defaultTag)
	}

	if m.status != "" {
		fmt.Fprintf(&b, "\n→ %s\n", m.status)
	}

	if m.showHelp {
		b.WriteString("\nControls:\n")
		b.WriteString("  ↑/↓ or j/k  Move selection\n")
		b.WriteString("  1-3         Jump directly to a stack\n")
		b.WriteString("  Enter       Confirm selection\n")
		b.WriteString("  d           Toggle debug panel\n")
		b.WriteString("  h / ?       Toggle this help\n")
		b.WriteString("  Ctrl+R      Reset to default\n")
		b.WriteString("  Ctrl+L      Clear status message\n")
		b.WriteString("  Ctrl+C / q  Cancel and use default\n")

		if len(m.tips) > 0 {
			b.WriteString("\nTips:\n")
			for _, tip := range m.tips {
				fmt.Fprintf(&b, "  - %s\n", tip)
			}
		}
	}

	if m.showDebug {
		b.WriteString("\nDebug info:\n")
		fmt.Fprintf(&b, "  Provided default  : %s\n", fallbackValue(m.info.defaultStack))
		fmt.Fprintf(&b, "  Current selection : %s\n", stackOptions[m.cursor])
		fmt.Fprintf(&b, "  Last history pick : %s\n", fallbackValue(m.info.historyValue))
		fmt.Fprintf(&b, "  History file      : %s\n", fallbackValue(m.info.historyPath))
		fmt.Fprintf(&b, "  Persisted default : %s\n", fallbackValue(m.info.persistedValue))
		fmt.Fprintf(&b, "  Persisted file    : %s\n", fallbackValue(m.info.persistedPath))
		fmt.Fprintf(&b, "  STACK override    : %s\n", fallbackValue(m.info.stackValue))
		fmt.Fprintf(&b, "  Working directory : %s\n", fallbackValue(m.info.workingDir))
		fmt.Fprintf(&b, "  Go runtime        : %s\n", fallbackValue(m.info.goVersion))
	}

	return b.String()
}

func runStackCLI(ctx stackContext, prompt string) error {
	defaultIdx := ctx.defaultIndex()
	model := newStackModel(prompt, defaultIdx, ctx)
	finalModel, err := tea.NewProgram(model).Run()
	if err != nil {
		return err
	}
	result := finalModel.(stackModel)
	selection := result.choice
	if selection == "" {
		selection = stackOptions[result.cursor]
	}

	fmt.Println(selection)
	return nil
}

func parseNumberSelection(input string, max int) (int, bool) {
	if len(input) != 1 {
		return 0, false
	}

	num, err := strconv.Atoi(input)
	if err != nil || num <= 0 || num > max {
		return 0, false
	}

	return num - 1, true
}
