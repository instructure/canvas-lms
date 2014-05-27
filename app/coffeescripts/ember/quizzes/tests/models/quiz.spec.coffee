define [
  'ember'
  '../start_app'
  'i18n!quizzes'
], (Em, startApp, I18n) ->

  {run} = Em
  App = null
  quiz = null

  module "Quiz",

    setup: ->
      App = startApp()
      container = App.__container__
      store = container.lookup 'store:main'
      run -> quiz = store.createRecord 'quiz', id: '1'

    teardown: ->
      run App, 'destroy'

  test "isSurvey", ->

    run -> quiz.set 'quizType', 'assignment'
    ok !quiz.get('isSurvey')

    run -> quiz.set 'quizType', 'survey'
    ok quiz.get('isSurvey'), 'reports correctly for "survey"'

    run -> quiz.set 'quizType', 'graded_survey'
    ok quiz.get('isSurvey'), 'reports correctly for "graded_survey"'

  test "isPracticeQuiz", ->

    run -> quiz.set 'quizType', 'assignment'
    ok !quiz.get('isPracticeQuiz')

    run -> quiz.set 'quizType', 'practice_quiz'
    ok quiz.get('isPracticeQuiz')

  test "isAssignment", ->

    run -> quiz.set 'quizType', 'practice_quiz'
    ok !quiz.get('isAssignment')

    run -> quiz.set 'quizType', 'assignment'
    ok quiz.get('isAssignment')

  test "tScoringPolicy", ->

    run -> quiz.set 'scoringPolicy', 'keep_highest'
    equal quiz.get('tScoringPolicy'), I18n.t('highest', 'highest')

    run -> quiz.set 'scoringPolicy', 'keep_latest'
    equal quiz.get('tScoringPolicy'), I18n.t('latest', 'latest')

  test "tQuizType", ->

    setQuizType = (type) ->
      run -> quiz.set 'quizType', type

    assertTQuizType = (tQuizType) ->
      equal quiz.get('tQuizType'), tQuizType

    setQuizType 'assignment'
    assertTQuizType I18n.t('assignment', 'Assignment')

    setQuizType 'survey'
    assertTQuizType I18n.t('survey', 'Survey')

    setQuizType 'graded_survey'
    assertTQuizType I18n.t('graded_survey', 'Graded Survey')

    setQuizType 'practice_quiz'
    assertTQuizType I18n.t('practice_quiz', 'Practice Quiz')

  test "unlimitedAllowedAttempts", ->

    run -> quiz.set "allowedAttempts", 1
    ok !quiz.get "unlimitedAllowedAttempts"

    run -> quiz.set "allowedAttempts", -1
    ok quiz.get "unlimitedAllowedAttempts"

  test "multipleAttemptsAllowed", ->

    run -> quiz.set "allowedAttempts", 1
    ok !quiz.get "multipleAttemptsAllowed"

    run -> quiz.set "allowedAttempts", -1
    ok quiz.get "multipleAttemptsAllowed"

    run -> quiz.set "allowedAttempts", 2
    ok quiz.get "multipleAttemptsAllowed"

  test "alwaysShowResults", ->

    run -> quiz.set "hideResults", null
    ok quiz.get("alwaysShowResults")

    run -> quiz.set "hideResults", 'always'
    ok !quiz.get("alwaysShowResults")

  test "showResultsAfterLastAttempt", ->

    run -> quiz.set "hideResults", false
    ok !quiz.get("showResultsAfterLastAttempt")

    run -> quiz.set "hideResults", 'until_after_last_attempt'
    ok quiz.get("showResultsAfterLastAttempt")

  test "sortSlug", ->
    date = new Date()
    run ->
      quiz.set 'quizType', 'assignment'
      quiz.set 'dueAt', date
      quiz.set 'title', 'ohi'
    equal quiz.get('sortSlug'), date.toISOString() + 'ohi', 'uses dueAt when isAssignment'

    date = new Date()
    run ->
      quiz.set 'lockAt', date
      quiz.set 'quizType', 'graded_survey'

    equal quiz.get('sortSlug'), date.toISOString() + 'ohi', 'uses lockAt when not isAssignment'

    run -> quiz.set 'lockAt', null

    equal quiz.get('sortSlug'), App.Quiz.SORT_LAST + 'ohi', 'uses a sort_last token when no date'

