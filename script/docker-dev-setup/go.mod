module canvaslms/script/dockerdevsetup

go 1.21

require (
    canvaslms/script/stackmanager v0.0.0
    github.com/charmbracelet/bubbles v0.16.1
    github.com/charmbracelet/bubbletea v0.26.6
    github.com/charmbracelet/lipgloss v0.7.1
)

replace canvaslms/script/stackmanager => ../stack-manager
