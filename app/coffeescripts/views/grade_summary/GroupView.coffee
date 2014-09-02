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
      'keyclick .group-description': 'expand'

    template: template

    render: ->
      super
      outcomesView = new CollectionView
        el: @$outcomes
        collection: @model.get('outcomes')
        itemView: OutcomeView
      outcomesView.render()

    expand: ->
      @$el.toggleClass('expanded')
      if @$el.hasClass("expanded")
        @$el.children("div.group-description").attr("aria-expanded", "true")
      else
        @$el.children("div.group-description").attr("aria-expanded", "false")

      $collapseToggle = $('div.outcome-toggles a.icon-collapse')
      if $('li.group.expanded').length == 0
        $collapseToggle.attr('disabled', 'disabled')
        $collapseToggle.attr('aria-disabled', 'true')
      else
        $collapseToggle.removeAttr('disabled')
        $collapseToggle.attr('aria-disabled', 'false')

      $expandToggle = $('div.outcome-toggles a.icon-expand')
      if $('li.group:not(.expanded)').length == 0
        $expandToggle.attr('disabled', 'disabled')
        $expandToggle.attr('aria-disabled', 'true')
      else
        $expandToggle.removeAttr('disabled')
        $expandToggle.attr('aria-disabled', 'false')

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
