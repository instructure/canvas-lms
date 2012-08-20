# analogous to ruby's Hash#invert, namely it takes an object and inverts
# the keys/values of its properties. takes an optional formatter for the
# key->value translation (otherwise they will just default to strings).
# in the event of duplicates, the last one wins.
#
# examples:
# 
#  > invert {a: 'A', b: 'B', c: 'C', dup: 'A'}
# => {A: 'dup', B: 'b', C: 'c'}
#
#  > invert ['a', 'b', 'c'], parseInt
# => {a: 0, b: 1, c: 2}
#

define ->

  invert = (object, formatter) ->
    result = {}
    for own key, value of object
      result[value] = if formatter then formatter(key) else key
    result