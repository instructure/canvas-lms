define [
  'jquery'
  'underscore'
  'compiled/views/outcomes/OutcomeContentBase'
  'jst/outcomes/outcomeGroup'
  'jst/outcomes/outcomeGroupForm'
], ($, _, OutcomeContentBase, outcomeGroupTemplate, outcomeGroupFormTemplate) ->

  # For outcome groups
  class OutcomeGroupView extends OutcomeContentBase

    render: ->
      data = @model.toJSON()
      switch @state
        when 'edit', 'add'
          @$el.html outcomeGroupFormTemplate data
          @readyForm()
        when 'loading'
          @$el.empty()
        else # show
          @$el.html outcomeGroupTemplate _.extend data, readOnly: @readOnly()
      @$('input:first').focus()
      this