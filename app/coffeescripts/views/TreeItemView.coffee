define [
  'Backbone'
  'underscore'
  'compiled/fn/preventDefault'
  'jst/TreeItem'
], (Backbone, _, preventDefault, template) ->

  class TreeItemView extends Backbone.View
    tagName: 'li'
    template: template
    @optionProperty 'nestingLevel'
    attributes: ->
      role: 'treeitem'
      id: _.uniqueId 'treenode-'

    afterRender: ->
      # We have to do this here, because @nestingLevel isn't available when attributes is run.
      @$el.attr 'aria-level', @nestingLevel
