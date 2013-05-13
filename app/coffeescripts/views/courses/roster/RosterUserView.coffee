define [
  'Backbone'
  'jst/courses/roster/rosterUser'
], (Backbone, template) ->

  class UserView extends Backbone.View

    tagName: 'tr'

    className: 'rosterUser'

    template: template

