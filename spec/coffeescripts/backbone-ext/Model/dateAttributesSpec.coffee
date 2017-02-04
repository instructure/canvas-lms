define ['compiled/backbone-ext/Model'], (Model) ->

  QUnit.module 'dateAttributes'

  test 'converts date strings to date objects', ->

    class TestModel extends Model
      dateAttributes: ['foo', 'bar']

    stringDate = "2012-04-10T17:21:09-06:00"
    parsedDate = Date.parse stringDate

    res = TestModel::parse
      foo: stringDate
      bar: null
      baz: stringDate

    expected =
      foo: parsedDate
      bar: null
      baz: stringDate

    deepEqual res, expected
