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

    imageAltLabel: (->
      I18n.t('stats_error.image_alt', 'Quiz statistics not available yet.')
    ).property()

    discriminationIndexHelpDialogTitle: (->
      I18n.t('discrimination_index_help_dialog_title',
        'The Discrimination Index Chart')
    ).property()

    hasError: (->
      !!@get('error')
    ).property('error')

    errorHeaderLabel: (->
      switch @get('error')
        when 'stats_empty'
          I18n.t('errors.stats_empty.header', 'Nothing to see here folks.')
        when 'stats_too_large'
          I18n.t('errors.stats_too_large.header', 'Too much going on here folks.')
        else
          I18n.t('unknown.header', 'Something went wrong.')
    ).property('error')

    errorInfoLabel: (->
      switch @get('error')
        when 'stats_empty'
          I18n.t('errors.stats_empty.info',
            'None of your students have taken this quiz yet.')
        when 'stats_too_large'
          I18n.t('errors.stats_too_large.info',
            'This quiz is too large to display.')
        else
          I18n.t('unknown.info', 'An unexpected error has occurred.')
    ).property('error')

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
