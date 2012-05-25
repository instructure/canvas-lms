define [
  'underscore'
  'compiled/views/KollectionItems/KollectionItemSaveView'
  'compiled/home/views/quickStartBar/BaseItemView'
  'compiled/home/models/quickStartBar/Pin'
  'jst/quickStartBar/pin'
  'compiled/models/KollectionItem'
  'jquery.instructure_date_and_time'
  'jquery.rails_flash_notifications'
], (_, KollectionItemSaveView, BaseItemView, Pin, template, KollectionItem) ->

  class QuickStartKollectionItemSaveView extends KollectionItemSaveView

    render: =>
      super
      @$('.toolbar').removeClass('toolbar')
      @$('.triangle-box-header').removeClass('triangle-box-header')
      @$('.triangle-box-content').removeClass('triangle-box-content').addClass('v-gutter')
      @$('.button').addClass('small-button')
      @$('[autoFocus]').removeAttr('autoFocus')

  class PinView extends BaseItemView

    events: _.extend
      'keyup [name=title]': 'onUrlKeyUp'
    , BaseItemView::events

    template: template

    urlRegEx: /^(http(s?))?:\/\/(\w+:{0,1}\w*)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/i

    render: ->
      super
      @createKollectionItemSaveView()

    save: ->
      @kollectionItemSaveView.model.save().done ->
        $.flashMessage 'TODO: Add collection items to the stream >:O'

    createKollectionItemSaveView: ->
      @model = new KollectionItem
      @kollectionItemSaveView = new QuickStartKollectionItemSaveView
        model: @model
        el: @$('.kollectionItemSaveView')[0]

    onUrlKeyUp: _.throttle (event) ->
      $el = $ event.target
      val = $el.val()
      url = @addHTTP val
      @updateLinkData url
    , 1000

    addHTTP: (url) ->
      if /^http(s)?:\/\//.test url
        url
      else
        "http://#{url}"

    updateLinkData: (url) ->
      return if url is @url
      @model.set 'title', null
      @url = url
      if @urlRegEx.test url
        @model.set 'image_url', null, silent: true
        @model.set 'link_url', url, silent: true
        @model.fetchLinkData()

