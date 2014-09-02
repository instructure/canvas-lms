define [
  'jst/UserObservee'
  'Backbone'
], (template, Backbone) ->

  class UserObserveeView extends Backbone.View
    template: template
    tagName: 'li'
