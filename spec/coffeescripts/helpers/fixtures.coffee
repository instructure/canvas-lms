define ['jquery'], ($) ->

  $fixtures = $('#fixtures')

  return {
    setup: (innerHTML='') ->
      $fixtures.innerHTML = innerHTML

    create: (source) ->
      $fixture = $(source)
      $fixtures.append($fixture)
      return $fixture

    find: (selector) ->
      return $(selector, $fixtures)

    teardown: () ->
      $fixtures.empty()
  }
