define [
  'ember'
  'i18n!quiz_statistics'
], (Ember, I18n) ->

  sortQuestionsBy = (controller, properties, asc) ->
    controller.set('questionStatistics.sortProperties', properties)
    controller.set('questionStatistics.sortAscending', asc)

  # This is the top-level statistics controller. It's mainly concerned with
  # keeping a sortable set of question statistics and accepts actions that are
  # not question-type-specific (like toggling the question details).
  Ember.ObjectController.extend
    questionStatistics: Ember.ArrayProxy.createWithMixins(Ember.SortableMixin, {
      sortProperties: [ 'position' ]
      content: []
    })

    sortLabel: (->
      switch @get('questionStatistics.sortProperties')[0]
        when 'position'
          I18n.t('sort_by_position', 'Sort By Position')
        when 'discriminationIndex'
          I18n.t('sort_by_discrimination_index', 'Sort By Discrimination')
    ).property('questionStatistics.sortProperties')

    discriminationIndexHelpDialogTitle: (->
      I18n.t('discrimination_index_help_dialog_title',
        'The Discrimination Index Chart')
    ).property()

    populateQuestionStatistics: (->
      @set('questionStatistics.content', @get('model.questionStatistics'))
    ).observes('model.questionStatistics.@each')

    actions:
      showAllDetails: ->
        @toggleProperty('allDetailsVisible')
        null

      sortByDiscriminationIndex: ->
        sortQuestionsBy(this, ['discriminationIndex', 'position'], false)
        null

      sortByPosition: ->
        sortQuestionsBy(this, ['position'], true)
        null
