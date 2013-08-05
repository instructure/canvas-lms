define [
  'Backbone'
  'jst/wiki/WikiPageIndexItem'
], (Backbone, template) ->

  class WikiPageIndexItemView extends Backbone.View
    template: template
    tagName: 'a'
    className: 'linkrow'

    initialize: ->
      super
      @$el.attr('href': @model.get('html_url'))
      @$el.attr('role', 'row')
      @$el.css({'display': 'table-row'})
