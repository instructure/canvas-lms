define [
  'Backbone'
  'underscore'
  'compiled/views/CollectionView'
  'compiled/views/grade_summary/OutcomeView'
  'jst/grade_summary/group'
], ({View, Collection}, _, CollectionView, OutcomeView, template) ->

  class GroupView extends View
    tagName: 'li'
    className: 'group'

    els:
      '.outcomes': '$outcomes'

    template: template

    render: ->
      super
      outcomesView = new CollectionView
        el: @$outcomes
        collection: @model.get('outcomes')
        itemView: OutcomeView
      outcomesView.render()
