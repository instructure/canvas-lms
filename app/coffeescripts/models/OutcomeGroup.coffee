define [
  'Backbone'
], (Backbone) ->

  class OutcomeGroup extends Backbone.Model

    name: ->
      @get 'title'

    setUrlTo: (action) ->
      @url =
        switch action
          when 'add' then @get('parent_outcome_group').subgroups_url
          when 'edit', 'delete' then @get 'url'