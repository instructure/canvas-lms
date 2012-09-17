define [
  'Backbone'
], (Backbone) ->

  class Outcome extends Backbone.Model

    name: ->
      @get 'title'

    # overriding to work with both outcome and outcome link responses
    parse: (resp, xhr) ->
      if resp.outcome # it's an outcome link
        @outcomeLink = resp
        @outcomeGroup = resp.outcome_group
        resp.outcome
      else
        resp

    setUrlTo: (action) ->
      @url =
        switch action
          when 'add'    then @outcomeGroup.outcomes_url
          when 'edit'   then @get 'url'
          when 'delete' then @outcomeLink.url