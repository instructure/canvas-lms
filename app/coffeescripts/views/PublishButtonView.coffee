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

    initialize: ->
      @disable() unless @model.get('publishable')

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
      else if @isUnpublish()
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

    # render

    render: ->
      if @model.get('published')
        @renderPublished()
      else
        @renderPublish()
      @

    renderPublish: ->
      @reset()
      @$el.addClass @publishClass
      text = I18n.t('buttons.publish', 'Publish')
      @$el.attr 'title', text
      @$el.html "<i class='icon-unpublished'></i><span class='publish-text'>&nbsp;#{text}</span>"

    renderPublished: ->
      @reset()
      text = I18n.t('buttons.published', 'Published')
      @$el.addClass @publishedClass
      @$el.attr 'title', text
      @$el.html "<i class='icon-publish'></i><span class='publish-text'>&nbsp;#{text}</span>"

    renderUnpublish: ->
      @reset()
      text = I18n.t('buttons.unpublish', 'Unpublish')
      @$el.addClass @unpublishClass
      @$el.attr 'title', text
      @$el.html "<i class='icon-unpublish'></i><span class='publish-text'>&nbsp;#{text}</span>"

    renderPublishing: ->
      @disable()
      text = I18n.t('buttons.publishing', 'Publishing...')
      @$el.attr 'title', text
      @$el.html "<i class='icon-publish'></i><span class='publish-text'>&nbsp;#{text}</span>"

    renderUnpublishing: ->
      @disable()
      text = I18n.t('buttons.unpublishing', 'Unpublishing...')
      @$el.attr 'title', text
      @$el.html "<i class='icon-unpublished'></i><span class='publish-text'>&nbsp;#{text}</span>"

