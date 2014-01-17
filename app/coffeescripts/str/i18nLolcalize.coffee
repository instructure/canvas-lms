define [], ->

  formatter =
    0: 'toUpperCase'
    1: 'toLowerCase'

  # see also lib/i18n/lolcalize.rb
  letThereBeLols = (str) ->
    # don't want to mangle placeholders, wrappers, etc.
    pattern = /(\s*%h?\{[^\}]+\}\s*|\s*[\n\\`\*_\{\}\[\]\(\)\#\+\-!]+\s*|^\s+)/
    result = for token in str.split(pattern)
      if token.match(pattern)
        token
      else
        s = ''
        for i in [0...token.length]
          s += token[i][formatter[i % 2]]()
        s = s.replace(/\.( |$)/, '!!?! ')
        s = s.replace(/^(\w+)$/, '$1!')
        s += " LOL!" if s.length > 2
        s
    result.join('')

  i18nLolcalize = (strOrObj) ->
    if typeof strOrObj is 'string'
      letThereBeLols strOrObj
    else
      result = {}
      for key, value of strOrObj
        result[key] = letThereBeLols(value)
      result

