define [
  'ember',
  '../shared/environment',
  'i18n!quizzes',
  '../shared/search_matcher',
], (Ember, environment, I18n, searchMatcher) ->

  {compare} = Ember
  {filter, filterBy, alias, sort} = Ember.computed

  # http://emberjs.com/guides/controllers/
  # http://emberjs.com/api/classes/Ember.Controller.html
  # http://emberjs.com/api/classes/Ember.ArrayController.html
  # http://emberjs.com/api/classes/Ember.ObjectController.html

  QuizzesController = Ember.ArrayController.extend
    searchFilter: ''
    searchPlaceholder: I18n.t('search_placeholder', 'Search for Quiz')
    addQuiz: I18n.t('title_add_quiz', 'Add Quiz')
    assignmentsLabel: I18n.t('assignments_label', 'Assignment Quizzes toggle quiz visibility')
    practicesLabel: I18n.t('practices_label', 'Practice Quizzes toggle quiz visibility')
    surveysLabel: I18n.t('surveys_label', 'Surveys toggle quiz visibility')

    environment: environment

    canManage: alias 'environment.canManage'

    newQuizLink: (->
      "/courses/#{environment.get('courseId')}/quizzes/new?fresh=1"
    ).property('environment.courseId')

    questionBanksUrl: (->
      "/courses/#{environment.get('courseId')}/question_banks"
    ).property('environment.courseId')

    filtered: (->
      @get('arrangedContent').filter (quiz) =>
        searchMatcher quiz.get('title'), @get('searchFilter')
    ).property('arrangedContent.[]', 'searchFilter')

    # Seems weird, but things won't disappear from the list when 
    # undestroyedContent: filterBy 'arrangedContent', 'isDestroyed', false

    assignments: filterBy 'filtered', 'isAssignment'

    practices: filterBy 'filtered', 'isPracticeQuiz'

    surveys: filterBy 'filtered', 'isSurvey'

    rawAssignments: filterBy 'model', 'isAssignment'

    rawPractices: filterBy 'model', 'isPracticeQuiz'

    rawSurveys: filterBy 'model', 'isSurvey'

    sortProperties: [ 'sortSlug' ]

    sortAscending: true

    disabledMessage: I18n.t('cant_unpublish_when_students_submit', "Can't unpublish if there are student submissions")
    actions:
      editBanks: ->
        window.location = @get('questionBanksUrl')

      delete: ->
        @get('model')

