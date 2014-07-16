define [
  'Backbone'
  'underscore'
  'compiled/views/CollectionView'
  'compiled/views/grade_summary/GroupView'
  'jst/grade_summary/section'
], ({View, Collection}, _, CollectionView, GroupView, template) ->

  class SectionView extends View
    tagName: 'li'
    className: 'section'

    els:
      '.groups': '$groups'

    template: template

    render: ->
      super
      groupsView = new CollectionView
        el: @$groups
        collection: @model.get('groups')
        itemView: GroupView
      groupsView.render()
