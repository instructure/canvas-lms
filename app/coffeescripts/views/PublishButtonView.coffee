define [
  'i18n!publish_btn_module'
  'jquery'
  'compiled/fn/preventDefault'
  'Backbone'
  'jquery.instructure_forms'
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

    initialize: ->
      super
      @model?.on 'change:unpublishable', =>
        @disable() if !@model.get('unpublishable')

    setElement: ->
      super
      @$el.attr 'data-tooltip', ''
      @disable() if !@model.get('unpublishable')

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
      event.stopPropagation()
      return if @isDisabled()
      @keepState = true
      if @isPublish()
        @publish()
      else if @isUnpublish() or @isPublished()
        @unpublish()

    addAriaLabel: (label) ->
      $('<span class="screenreader-only accessible_label"></span>').text(label).appendTo @$el
      @$el.attr 'aria-label', label

    # calling publish/unpublish on the model expects a deferred object

    publish: (event) ->
      @renderPublishing()
      @model.publish().always =>
        @trigger("publish")
        @enable()
        @render()

    unpublish: (event) ->
      @renderUnpublishing()
      @model.unpublish()
      .done =>
        @trigger("unpublish")
        @disable()
        @render()
      .fail (error) =>
        errors = JSON.parse(error.responseText)['errors']
        $.flashError errors.published[0].message
        @model.set 'unpublishable', true
        @disable()
        @renderPublished()

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
      @$el.removeAttr 'aria-label'

    # render

    render: ->
      @$el.attr 'role', 'button'
      @$el.attr 'tabindex', '0'
      @$el.html '<i></i><span class="publish-text"></span>'
      @cacheEls()

      # don't read text of button with screenreader
      @$text.attr 'tabindex', '-1'

      if @model.get('published')
        @renderPublished()
      else
        @renderPublish()
      @

    renderPublish: ->
      @renderState
        text:        I18n.t 'buttons.publish', 'Publish'
        label:       I18n.t 'buttons.publish_desc', 'Unpublished. Click to publish.'
        buttonClass: @publishClass
        iconClass:   'icon-unpublished'

    renderPublished: ->
      @renderState
        text:        I18n.t 'buttons.published', 'Published'
        label:       I18n.t 'buttons.published_desc', 'Published. Click to unpublish.'
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

      # unpublishable
      if !@model.get('unpublishable')? or @model.get('unpublishable')
        @enable()
        @$el.attr 'title', options.text

        # label for screen readers
        if options.label
          @addAriaLabel(options.label)

      # disabled
      else
        @disable()
        @$el.attr 'aria-disabled', true
        @$el.attr 'title', @model.disabledMessage()
        @addAriaLabel(@model.disabledMessage())
