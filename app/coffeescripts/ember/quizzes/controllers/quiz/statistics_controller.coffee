define [
  'ember'
  'i18n!quiz_statistics'
], (Ember, I18n) ->
  # This is the top-level statistics controller. It's mainly concerned with
  # keeping a sortable set of question statistics and accepts actions that are
  # not question-type-specific (like toggling the question details).
  Ember.ObjectController.extend
    questionStatistics: Ember.ArrayProxy.createWithMixins(Ember.SortableMixin, {
      sortProperties: [ 'position' ]
      content: []
    })

    populateQuestionStatistics: (->
      @get('questionStatistics').set 'content', @get('model.questionStatistics')
    ).observes('model.questionStatistics.@each')

    sortLabel: (->
      switch @get('questionStatistics.sortProperties')[0]
        when 'position'
          I18n.t('sort_by_position', 'Sort By Position')
        when 'discriminationIndex'
          I18n.t('sort_by_discrimination_index', 'Sort By Discrimination')
    ).property('questionStatistics.sortProperties')

    sortQuestionsBy: (properties, asc) ->
      @set('questionStatistics.sortProperties', properties)
      @set('questionStatistics.sortAscending', asc)

    actions:
      showAllDetails: ->
        @set('allDetailsVisible', !@get('allDetailsVisible'))

      sortByDiscriminationIndex: ->
        @sortQuestionsBy ['discriminationIndex', 'position'], false

      sortByPosition: ->
        @sortQuestionsBy ['position'], true