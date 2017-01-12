define [
  'jquery'
  'Backbone'
  'underscore'
  'jst/quizzes/NoQuizzesView'
], ($, Backbone, _, template) ->

  class ItemGroupView extends Backbone.View
    template: template

    tagName:   'div'
    className: 'item-group-condensed'
