define [
  'compiled/handlebars_helpers'
  'underscore'
], ({helpers}, _) ->

  module 'handlebars_helpers'

  module 'checkbox'

  context =
    likes:
      tacos: true
    human: true
    alien: false

  testCheckbox = (context, prop, hash={}) ->
    $input = $("<span>#{helpers.checkbox.call(context, prop, {hash: hash}).string}</span>").find('input').eq(1)

    checks = _.defaults hash,
      value: 1
      tagName: 'INPUT'
      type: 'checkbox'
      name: prop
      checked: context[prop]
      id: prop

    for key, val of checks
      equal $input.prop(key), val

  test 'simple case', ->
    testCheckbox context, 'human'

  test 'custom hash attributes', ->
    hash =
      class: 'foo bar baz'
      id: 'custom_id'
    testCheckbox context, 'human', hash, hash

  test 'nested property', ->
    testCheckbox context, 'likes.tacos',
      id: 'likes_tacos'
      name: 'likes[tacos]'
      checked: context.likes.tacos

  test 'titleize', ->
    equal helpers.titleize('test_string'), 'Test String'
    equal helpers.titleize(null), ''
    equal helpers.titleize('test_ _string'), 'Test String'

  test 'toPrecision', ->
    equal helpers.toPrecision(3.6666666, 2), '3.7'

  module 'truncate'
  test 'default truncates 30 characters', ->
    text = "asdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdf"
    truncText = helpers.truncate text
    equal truncText.length, 30, "Truncates down to 30 letters"

  test 'expects options for max (length)', ->
    text = "asdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdf"
    truncText = helpers.truncate text, 10
    equal truncText.length, 10, "Truncates down to 10 letters"

  test 'supports truncation left', ->
    text = "going to the store"
    truncText = helpers.truncate_left text, 15
    equal truncText, "...to the store", "Reverse truncates"
