define [
  'ember'
], (Em) ->

  INITIAL_REFRESH_MS = 60000
  LATER_REFRESH_MS = 180000

  QuizModerateController = Em.ArrayController.extend

    headerChecked: false
    reloading: false
    okayToReload: true

    setupAutoReload: (->
      Ember.run.later this, @triggerReload, INITIAL_REFRESH_MS
    ).on('init')

    triggerReload: ->
      @send('refreshData')
      Ember.run.later this, @triggerReload, LATER_REFRESH_MS

    actions:
      editSubmissionUser: (su) ->
        Em.K # noop for now

      refreshData: ->
        @set('reloading', true)
        true

  QuizModerateController
