# Custom jQuery element event 'outerclick'
#
# Usage:
#   $el = $ '#el'
#   $el.on 'outerclick', (event) ->
#     doStuff()
#
#   class SomeView extends Backbone.View
#     events:
#       'outerclick': 'handler'
#     handler: (event) ->
#       @hide()
define ['jquery'], ($) ->

  $els = $()
  $doc = $ document
  outerClick = 'outerclick'
  eventName = "click.#{outerClick}-special"

  $.event.special[outerClick] =
    setup: ->
      $els = $els.add this
      if $els.length is 1
        $doc.on eventName, handleEvent

    teardown: ->
      $els = $els.not this
      $doc.off eventName if $els.length is 0

    add: (handleObj) ->
      oldHandler = handleObj.handler
      handleObj.handler = (event, el) ->
        event.target = el
        oldHandler.apply this, arguments

  handleEvent = (event) ->
    $els.each ->
      $el = $ this
      if this isnt event.target and $el.has(event.target).length is 0
        $el.triggerHandler outerClick, [event.target]

