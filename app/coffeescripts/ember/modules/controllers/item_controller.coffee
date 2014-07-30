define [
  'ember'
  'i18n!modules_item_controller'
  '../lib/store'
], (Ember, I18n, store) ->


  ItemController = Ember.ObjectController.extend

    isDeleting: false

    actions:

      increaseIndent: ->
        @incrementProperty('model.indent')
        store.syncItemById(@get('model.id'))

      decreaseIndent: ->
        @decrementProperty('model.indent')
        store.syncItemById(@get('model.id'))

      remove: ->
        @set 'isDeleting', yes #ma'am
        Ember.run.later =>
          store.removeItemById(@get('model.id'))
        , 351

    indentClassName: (->
      "indent-#{@get('indent')}"
    ).property('indent')

    showIncreaseIndent: (->
      @get('indent') < 5
    ).property('indent')

    showDecreaseIndent: (->
      @get('indent') > 0
    ).property('indent')

    completionRequirement: (->
      return '' unless @get('completion_requirement')
      type = @get('completion_requirement.type')
      status = if @get('completion_requirement.completed') then 'complete' else 'incomplete'
      message = @get('requirementMessages')[type][status]
      if 'function' is typeof message
        message.call(this)
      else
        message
    ).property('completion_requirement')

    requirementMessages:
      min_score:
        incomplete: ->
          I18n.t('min_score_incomplete', "must score at least a *score*", score: 'TODO')
        complete: ->
          I18n.t('min_score_complete', "scored at least a *score*", score: 'TODO')
      max_score:
        incomplete: ->
          I18n.t('max_score_incomplete', "must score no more than a *score*", score: 'TODO')
        complete: ->
          I18n.t('max_score_complete', "scored no more than a *score*", score: 'TODO')
      must_view:
        incomplete: I18n.t('must_view_incomplete', 'must view the page')
        complete: I18n.t('must_view_complete', 'viewed the page')
      must_contribute:
        incomplete: I18n.t('must_contribute_incomplete', 'must contribute to the content of the page')
        complete: I18n.t('must_contribute_complete', 'contributed to the content of the page')
      must_submit:
        incomplete: I18n.t('must_submit_incomplete', 'must submit the assignment')
        complete: I18n.t('must_submit_complete', 'submitted the assignment')

