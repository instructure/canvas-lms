package main

type stackContext struct {
	defaultStack   string
	stackValue     string
	historyPath    string
	historyValue   string
	persistedPath  string
	persistedValue string
	workingDir     string
	repoRoot       string
	goVersion      string
}

func (ctx stackContext) defaultIndex() int {
	return indexOfStack(ctx.defaultStack)
}
