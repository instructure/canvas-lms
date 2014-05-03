define [
  'Backbone'
], ({View}) ->

  ##
  # Generic form element View that manages the inputs data and the model
  # or collection it belongs to.

  class InputView extends View

    tagName: 'input'

    defaults:
      modelAttribute: 'unnamed'

    initialize: ->
      super
      @setupElement()

    ##
    # When setElement is called, need to setupElement again

    setElement: ->
      super
      @setupElement()

    setupElement: ->
      @lastValue = @el?.value
      @modelAttribute = @$el.attr('name') or @options?.modelAttribute

    attach: ->
      return unless @collection
      @collection.on 'beforeFetch', => @$el.addClass 'loading'
      @collection.on 'fetch', => @$el.removeClass 'loading'
      @collection.on 'fetch:fail', => @$el.removeClass 'loading'

    updateModel: ->
      {value} = @el
      # TODO this needs to be refactored out into some validation
      # rules or something
      if value and value.length < @options.minLength and !(@options.allowSmallerNumbers && value > 0)
        return unless @options.setParamOnInvalid
        value = false
      @setParam value

    setParam: (value) ->
      @model?.set @modelAttribute, value
      if value is ''
        @collection?.deleteParam @modelAttribute
      else
        @collection?.setParam @modelAttribute, value


