define [
  '../../shared/title_builder'
], (titleBuilder) ->

  module 'title_builder - Unit - '

  test 'uses default separator', ->
    result = titleBuilder(['foo', 'bar'])
    equal result, 'foo: bar'

  test 'uses separator from arguments', ->
    result = titleBuilder(['foo', 'bar'], ' - ')
    equal result, 'foo - bar'

  test 'concats tokens in order given', ->
    result = titleBuilder(['foo', 'bar', 'baz'], ' ')
    equal result, 'foo bar baz'

  test 'handles empty tokens', ->
    result = titleBuilder([], '!')
    equal result, ''

  test 'handles no arguments', ->
    result = titleBuilder()
    equal result, ''

  test 'handles first argument as a string', ->
    result = titleBuilder('baz')
    equal result, 'baz'
