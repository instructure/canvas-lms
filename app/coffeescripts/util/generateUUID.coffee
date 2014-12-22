define [], ->
  () ->
    now = Date.now()
    'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, (char) ->
      r = (now + Math.random() * 16) % 16 | 0
      now = Math.floor(now/16)
      newChar = if char == 'x' then r else (r&0x7|0x8)
      newChar.toString(16)