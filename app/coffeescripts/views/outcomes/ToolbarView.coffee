define [
  'i18n!outcomes'
  'jquery'
  'underscore'
  'Backbone'
  'compiled/models/Outcome'
  'compiled/models/OutcomeGroup'
], (I18n, $, _, Backbone, Outcome, OutcomeGroup) ->

  # Manage the toolbar buttons.
  class ToolbarView extends Backbone.View

    events:
      'click .go_back': 'goBack'
      'click .add_outcome_link': 'addOutcome'
      'click .add_outcome_group': 'addGroup'
      'click .find_outcome': 'findDialog'

    goBack: (e) =>
      e.preventDefault()
      @trigger 'goBack'

    addOutcome: (e) =>
      e.preventDefault()
      model = new Outcome title: I18n.t('new_outcome', 'New Outcome')
      @trigger 'add', model

    addGroup: (e) =>
      e.preventDefault()
      model = new OutcomeGroup title: I18n.t('new_outcome_group', 'New Outcome Group')
      @trigger 'add', model

    findDialog: (e) =>
      e.preventDefault()
      @trigger 'find'

    resetBackButton: (model, directories) =>
      if model || directories.length > 1
        @$('.go_back').show 200
      else
        @$('.go_back').hide 200