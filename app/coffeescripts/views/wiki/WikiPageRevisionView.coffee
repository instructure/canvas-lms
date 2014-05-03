define [
  'jquery'
  'underscore'
  'Backbone'
  'jst/wiki/WikiPageRevision'
], ($, _, Backbone, template) ->

  class WikiPageRevisionView extends Backbone.View
    tagName: 'li'
    className: 'revision clearfix'
    template: template

    events:
      'click .restore-link': 'restore'

    initialize: ->
      super
      @model.on 'change', => @render()

    afterRender: ->
      super
      @$el.toggleClass('selected', !!@model.get('selected'))
      @$el.toggleClass('latest', !!@model.get('latest'))

    toJSON: ->
      latest = @model.collection?.latest
      json = _.extend {}, super,
        IS:
          LATEST: !!@model.get('latest')
          SELECTED: !!@model.get('selected')
          LOADED: !!@model.get('title') && !!@model.get('body')
      json.IS.SAME_AS_LATEST = json.IS.LOADED && (@model.get('title') == latest?.get('title')) && (@model.get('body') == latest?.get('body'))
      json.updated_at = $.datetimeString(json.updated_at)
      json.edited_by = json.edited_by?.display_name
      json

    restore: (ev) ->
      ev?.preventDefault()
      @model.restore().done =>
        window.location.reload()
