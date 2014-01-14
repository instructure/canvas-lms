define [
  'ember',
  '../shared/environment',
  'i18n!quizzes',
  '../shared/search_matcher'
], (Ember, environment, I18n, searchMatcher) ->

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


    newQuizLink: ( ->
      "/courses/#{environment.get('courseId')}/quizzes/new?fresh=1"
    ).property('environment.courseId')

    questionBanksUrl: ( ->
      "/courses/#{environment.get('courseId')}/question_banks"
    ).property('environment.courseId')

    surveyTypes: ['survey', 'graded_survey']

    filtered: (->
      @get('model').filter ({title}) => searchMatcher(title, @get('searchFilter'))
    ).property('model.@each', 'searchFilter')

    assignments: (->
      @get('filtered').filterBy('quiz_type', 'assignment')
    ).property('filtered.@each')

    practices: (->
      @get('filtered').filterBy('quiz_type', 'practice_quiz')
    ).property('filtered.@each')

    surveys: (->
      surveyTypes = this.get('surveyTypes')
      @get('filtered').filter ({quiz_type, title}) =>
        quiz_type in surveyTypes
    ).property('filtered.@each')

    rawAssignments: (->
      @get('model').filterBy('quiz_type', 'assignment')
    ).property('model.@each')

    rawPractices: (->
      @get('model').filterBy('quiz_type', 'practice_quiz')
    ).property('model.@each')

    rawSurveys: (->
      surveyTypes = this.get('surveyTypes')
      @get('model').filter ({quiz_type, title}) =>
        quiz_type in surveyTypes
    ).property('model.@each')


