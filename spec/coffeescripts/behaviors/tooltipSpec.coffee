define [
  'compiled/behaviors/tooltip'
], (tooltip) ->

  module 'tooltip position selection',
    setup: ->
    teardown: ->

  test "provides a position hash for a cardinal direction", ->
    opts = { position: 'bottom' }
    tooltip.setPosition(opts)
    expected = {
      my: "center top",
      at: "center bottom+5",
      collision: "flipfit"
    }
    equal(opts.position.my, expected.my)
    equal(opts.position.at, expected.at)
    equal(opts.position.collision, expected.collision)

  test "can be compelled to abandon collision detection", ->
    opts = { position: 'bottom', force_position: "true" }
    tooltip.setPosition(opts)
    equal(opts.position.collision, "none")

