define [
  'i18n!publish_btn_module'
  'jquery'
  'compiled/fn/preventDefault'
  'Backbone'
], (I18n, $, preventDefault, Backbone) ->

  class PublishButton extends Backbone.View
    disabledClass: 'disabled'
    publishClass: 'btn-publish'
    publishedClass: 'btn-published'
    unpublishClass: 'btn-unpublish'

    tagName:   'button'
    className: 'btn'

    events: {'click', 'hover'}

    setElement: ->
      super
      @disable() unless @model.get 'publishable'

    # events

    hover: ({type}) ->
      if type is 'mouseenter'
        return if @keepState or @isPublish() or @isDisabled()
        @renderUnpublish()
        @keepState = true
      else
        @keepState = false
        @renderPublished() unless @isPublish() or @isDisabled()

    click: (event) ->
      event.preventDefault()
      return if @isDisabled()
      @keepState = true
      if @isPublish()
        @publish()
      else if @isUnpublish() or @isPublished()
        @unpublish()

    # calling publish/unpublish on the model expects a deferred object

    publish: (event) ->
      @renderPublishing()
      @model.publish().always =>
        @trigger("publish")
        @enable()
        @render()

    unpublish: (event) ->
      @renderUnpublishing()
      @model.unpublish().always =>
        @trigger("unpublish")
        @enable()
        @render()

    # state

    isPublish: ->
      @$el.hasClass @publishClass

    isPublished: ->
      @$el.hasClass @publishedClass

    isUnpublish: ->
      @$el.hasClass @unpublishClass

    isDisabled: ->
      @$el.hasClass @disabledClass

    disable: ->
      @$el.addClass @disabledClass

    enable: ->
      @$el.removeClass @disabledClass

    reset: ->
      @$el.removeClass "#{@publishClass} #{@publishedClass} #{@unpublishClass}"
      @$icon.removeClass 'icon-publish icon-unpublish icon-unpublished'

    # render

    render: ->
      @$el.attr 'role', 'button'
      @$el.html '<i></i><span class="publish-text"></span>'
      @$icon = @$ 'i'
      @$span = @$ 'span'

      if @model.get('published')
        @renderPublished()
      else
        @renderPublish()
      @

    renderPublish: ->
      text = I18n.t 'buttons.publish', 'Publish'
      @renderState(text, @publishClass, 'icon-unpublished')

    renderPublished: ->
      text = I18n.t 'buttons.published', 'Published'
      @renderState(text, @publishedClass, 'icon-publish')

    renderUnpublish: ->
      text = I18n.t 'buttons.unpublish', 'Unpublish'
      @renderState(text, @unpublishClass, 'icon-unpublish')

    renderPublishing: ->
      @disable()
      text = I18n.t 'buttons.publishing', 'Publishing...'
      @renderState(text, @publishClass, 'icon-publish')

    renderUnpublishing: ->
      @disable()
      text = I18n.t 'buttons.unpublishing', 'Unpublishing...'
      @renderState(text, @unpublishClass, 'icon-unpublished')

    renderState: (text, buttonClass, iconClass) ->
      @reset()
      @$el.addClass buttonClass

      title = if @isDisabled() then @model.disabledMessage() else text
      @$el.attr 'title', title
      @$el.attr 'aria-pressed', buttonClass is @publishedClass

      @$icon.addClass iconClass
      @$span.html "&nbsp;#{text}"
