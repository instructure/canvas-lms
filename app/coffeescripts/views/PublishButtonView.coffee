define [
  'i18n!publish_btn_module'
  'jquery'
  'compiled/fn/preventDefault'
  'Backbone'
], (I18n, $, preventDefault, Backbone) ->

  class PublishButton extends Backbone.View
    DISABLED  = 'disabled'
    PUBLISH   = 'btn-publish'
    PUBLISHED = 'btn-published'
    UNPUBLISH = 'btn-unpublish'

    tagName:   'button'
    className: 'btn'

    events:
      'click': 'click'
      'hover': 'hover'

    initialize: ->
      @disable() unless @model.get('publishable')

    # events

    hover: (event) ->
      return if @isPublish() or @isDisabled()

      if event.type == 'mouseenter'
        @renderUnpublish()
      else
        @renderPublished()

    click: (event) ->
      event.preventDefault()
      return if @isDisabled()

      if @isPublish()
        @publish()
      else if @isUnpublish()
        @unpublish()

    # calling publish/unpublish on the model expects a deferred object

    publish: (event) ->
      @renderPublishing()
      @model.publish().always =>
        @enable()
        @render()

    unpublish: (event) ->
      @renderUnpublishing()
      @model.unpublish().always =>
        @enable()
        @render()

    # state

    isPublish: ->
      @$el.hasClass PUBLISH

    isPublished: ->
      @$el.hasClass PUBLISHED

    isUnpublish: ->
      @$el.hasClass UNPUBLISH

    isDisabled: ->
      @$el.hasClass DISABLED

    disable: ->
      @$el.addClass DISABLED

    enable: ->
      @$el.removeClass DISABLED

    reset: ->
      @$el.removeClass "#{PUBLISH} #{PUBLISHED} #{UNPUBLISH}"

    # render

    render: ->
      if @model.get('published')
        @renderPublished()
      else
        @renderPublish()
      @

    renderPublish: ->
      @reset()
      @$el.addClass PUBLISH
      @$el.html "<i class='icon-unpublished'></i>&nbsp;#{I18n.t('buttons.publish', 'Publish')}"

    renderPublished: ->
      @reset()
      @$el.addClass PUBLISHED
      @$el.html "<i class='icon-publish'></i>&nbsp;#{I18n.t('buttons.published', 'Published')}"

    renderUnpublish: ->
      @reset()
      @$el.addClass UNPUBLISH
      @$el.html "<i class='icon-unpublish'></i>&nbsp;#{I18n.t('buttons.unpublish', 'Unpublish')}"

    renderPublishing: ->
      @disable()
      @$el.html "<i class='icon-publish'></i>&nbsp;#{I18n.t('buttons.publishing', 'Publishing...')}"

    renderUnpublishing: ->
      @disable()
      @$el.html "<i class='icon-unpublish'></i>&nbsp;#{I18n.t('buttons.unpublishing', 'Unpublishing...')}"
