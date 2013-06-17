define [
  'Backbone'
  'jst/wiki/WikiPageIndexItem'
], (Backbone, template) ->

  class WikiPageIndexItemView extends Backbone.View
    template: template
    tagName: 'tr'
