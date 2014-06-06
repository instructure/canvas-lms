define [
  'i18n!outcomes'
  'Backbone'
  'underscore'
  'compiled/views/CollectionView'
  'compiled/views/grade_summary/OutcomeView'
  'jst/grade_summary/group'
], (I18n, {View, Collection}, _, CollectionView, OutcomeView, template) ->

  class GroupView extends View
    tagName: 'li'
    className: 'group'

    els:
      '.outcomes': '$outcomes'

    events:
      'click .group-description': 'expand'

    template: template

    render: ->
      super
      outcomesView = new CollectionView
        el: @$outcomes
        collection: @model.get('outcomes')
        itemView: OutcomeView
      outcomesView.render()

    expand: -> @$el.toggleClass('expanded')

    statusTooltip: ->
      switch @model.status()
        when 'undefined' then I18n.t 'undefined', 'Unstarted'
        when 'remedial' then I18n.t 'remedial', 'Remedial'
        when 'near' then I18n.t 'near', 'Near mastery'
        when 'mastery' then I18n.t 'mastery', 'Mastery'

    toJSON: ->
      json = super
      _.extend json,
        statusTooltip: @statusTooltip()
