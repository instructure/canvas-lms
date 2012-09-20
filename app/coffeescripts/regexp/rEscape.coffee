define ->
  rEscape = (string) ->
    string.replace(/[\\\^\$\*\+\?\.\(\)\|\{\}\[\]]/g, "\\$&")
