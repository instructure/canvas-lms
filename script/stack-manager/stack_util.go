package main

import shared "canvaslms/script/stackmanager/shared"

var stackOptions = shared.Options()

func indexOfStack(stack string) int {
	return shared.IndexOf(stack)
}

func sanitizeStack(stack string) string {
	return shared.Normalize(stack)
}

func fallbackValue(value string) string {
	return shared.Fallback(value)
}
