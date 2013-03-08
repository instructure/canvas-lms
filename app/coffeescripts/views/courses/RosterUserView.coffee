define [
  'Backbone'
  'jst/courses/rosterUserView'
], (Backbone, template) ->

  class UserView extends Backbone.View

    tagName: 'tr'

    className: 'rosterUser'

    template: template

