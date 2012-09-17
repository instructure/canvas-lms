define [
  'jquery'
  'underscore'
  'str/htmlEscape'
  'compiled/views/outcomes/OutcomeIconBase'
], ($, _, h, OutcomeIconBase) ->

  class OutcomeGroupIconView extends OutcomeIconBase

    className: 'outcome-group'

    initDroppable: ->
      @$el.droppable
        scope: 'outcomes'
        hoverClass: 'droppable'
        greedy: true
        drop: (e, ui) =>
          model = ui.draggable.data('view').model
          # don't re-add to group
          return if model.outcomeGroup.id is @model.id
          @triggerSelect()
          @dir.sidebar.dirForGroup(@model).promise().done (dir) ->
            dir.moveModelHere model

    render: ->
      @$el.attr 'data-id', @model.get 'id'
      @$el.html """
          <a href="#" class="ellipsis" title="#{h @model.get('title')}">
            <i class="icon-folder"></i>
            <span>#{h @model.get('title')}</span>
          </a>
        """
      @initDroppable()
      super