define [
  'jquery'
  'underscore'
  'str/htmlEscape'
  'compiled/views/outcomes/OutcomeIconBase'
], ($, _, h, OutcomeIconBase) ->

  class OutcomeIconView extends OutcomeIconBase

    className: 'outcome-link'

    render: ->
      @$el.attr 'data-id', @model.get 'id'
      @$el.html """
          <a href="#" class="ellipsis" title="#{h @model.get('title')}">
            <i class="icon-note-light"></i>
            <span>#{h @model.get('title')}</span>
          </a>
        """
      super