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
