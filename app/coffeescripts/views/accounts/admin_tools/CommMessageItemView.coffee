define [
  'Backbone'
  'jst/accounts/admin_tools/commMessageItem'
], (Backbone, template) ->

  class CommMessageItemView extends Backbone.View

    tagName: 'li'

    className: 'message'

    template: template
