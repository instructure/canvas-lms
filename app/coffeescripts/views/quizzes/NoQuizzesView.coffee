define [
  'jquery'
  'underscore'
  'jst/quizzes/NoQuizzesView'
], ($, _, template) ->

  class ItemGroupView extends Backbone.View
    template: template

    tagName:   'div'
    className: 'item-group-condensed'
