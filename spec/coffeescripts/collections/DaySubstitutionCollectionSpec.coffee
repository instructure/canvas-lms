define [
  'compiled/collections/DaySubstitutionCollection'
], (DaySubCollection) ->
  QUnit.module 'DaySubstitutionCollection'

  test 'toJSON contains nested day_substitution objects', ->
    collection = new DaySubCollection
    collection.add one: 'bar'
    collection.add two: 'baz'
    json = collection.toJSON()

    equal json.one, 'bar', 'nested one correctly'
    equal json.two, 'baz', 'nexted two correctly'
