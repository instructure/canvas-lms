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

    els:
      'i':             '$icon'
      '.publish-text': '$text'
      '.desc':         '$desc'

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
      @$el.html '<i></i><span class="publish-text"></span><span class="desc"></span>'
      @cacheEls()

      # don't read text of button with screenreader
      @$text.attr 'role', 'presentation'
      @$text.attr 'tabindex', '-1'

      if @model.get('published')
        @renderPublished()
      else
        @renderPublish()
      @

    renderPublish: ->
      @renderState
        text:        I18n.t 'buttons.publish', 'Publish'
        description: I18n.t 'buttons.publish_desc', 'Unpublished. Click to publish'
        buttonClass: @publishClass
        iconClass:   'icon-unpublished'

    renderPublished: ->
      @renderState
        text:        I18n.t 'buttons.published', 'Published'
        description: I18n.t 'buttons.published_desc', 'Published. Click to unpublish'
        buttonClass: @publishedClass
        iconClass:   'icon-publish'

    renderUnpublish: ->
      text = I18n.t 'buttons.unpublish', 'Unpublish'
      @renderState
        text:        text
        buttonClass: @unpublishClass
        iconClass:   'icon-unpublish'

    renderPublishing: ->
      @disable()
      text = I18n.t 'buttons.publishing', 'Publishing...'
      @renderState
        text:        text
        buttonClass: @publishClass
        iconClass:   'icon-publish'

    renderUnpublishing: ->
      @disable()
      text = I18n.t 'buttons.unpublishing', 'Unpublishing...'
      @renderState
        text:        text
        buttonClass: @unpublishClass
        iconClass:   'icon-unpublished'

    renderState: (options) ->
      @reset()
      @$el.addClass options.buttonClass
      @$el.attr 'aria-pressed', options.buttonClass is @publishedClass

      @$icon.addClass options.iconClass
      @$text.html "&nbsp;#{options.text}"

      descId = "button-desc-#{@model.id}"
      @$desc.attr 'id', descId
      @$desc.addClass 'screenreader-only'
      @$el.attr 'aria-describedby', descId

      # publishable
      if @model.get 'publishable'
        @$el.attr 'title', options.text

        # description for screen readers
        if options.description
          @$desc.html options.description
        else
          @$el.removeAttr 'aria-describedby'

      # disabled
      else
        @$el.attr 'aria-disabled', true
        @$el.attr 'title', @model.disabledMessage()
        @$desc.html  @model.disabledMessage()
