define ->
  # erase `victim` from `array`
  (array, victim) ->
    for suspect, index in array when suspect is victim
      array.splice index, 1
      break
    array

