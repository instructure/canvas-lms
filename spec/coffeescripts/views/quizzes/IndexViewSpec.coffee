define [
  'Backbone'
  'compiled/models/Quiz'
  'compiled/collections/QuizCollection'
  'compiled/views/quizzes/IndexView'
  'compiled/views/quizzes/QuizItemGroupView'
  'compiled/views/quizzes/NoQuizzesView'
  'jquery'
  'helpers/fakeENV'
  'helpers/jquery.simulate'
], (Backbone, Quiz, QuizCollection, IndexView, QuizItemGroupView, NoQuizzesView, $, fakeENV) ->

  fixtures = null

  indexView = (assignments, open, surveys) ->
    $('<div id="content"></div>').appendTo fixtures

    assignments ?= new QuizCollection([])
    open        ?= new QuizCollection([])
    surveys     ?= new QuizCollection([])

    assignmentView = new QuizItemGroupView(
      collection: assignments,
      title: 'Assignment Quizzes',
      listId: 'assignment-quizzes',
      isSurvey: false)

    openView = new QuizItemGroupView(
      collection: open,
      title: 'Practice Quizzes',
      listId: 'open-quizzes',
      isSurvey: false)

    surveyView = new QuizItemGroupView(
      collection: surveys,
      title: 'Surveys',
      listId: 'surveys-quizzes',
      isSurvey: true)

    noQuizzesView = new NoQuizzesView

    permissions = create: true, manage: true
    flags = question_banks: true
    urls =
      new_quiz_url:        '/courses/1/quizzes/new?fresh=1',
      question_banks_url:  '/courses/1/question_banks'

    view = new IndexView
      assignmentView:  assignmentView
      openView:        openView
      surveyView:      surveyView
      noQuizzesView:   noQuizzesView
      permissions:     permissions
      flags:           flags
      urls:            urls
    view.$el.appendTo fixtures
    view.render()

  module 'IndexView',
    setup: ->
      fixtures = $("#fixtures")
      fakeENV.setup()
    teardown: ->
      fakeENV.teardown()
      fixtures.empty()

  # hasNoQuizzes
  test '#hasNoQuizzes if assignment and open quizzes are empty', ->
    assignments = new QuizCollection([])
    open        = new QuizCollection([])

    view = indexView(assignments, open)
    ok view.options.hasNoQuizzes

  test '#hasNoQuizzes to false if has assignement quizzes', ->
    assignments = new QuizCollection([{id: 1}])
    open        = new QuizCollection([])

    view = indexView(assignments, open)
    ok !view.options.hasNoQuizzes

  test '#hasNoQuizzes to false if has open quizzes', ->
    assignments = new QuizCollection([])
    open        = new QuizCollection([{id: 1}])

    view = indexView(assignments, open)
    ok !view.options.hasNoQuizzes


  # has*
  test '#hasAssignmentQuizzes if has assignment quizzes', ->
    assignments = new QuizCollection([{id: 1}])

    view = indexView(assignments, null, null)
    ok view.options.hasAssignmentQuizzes

  test '#hasOpenQuizzes if has open quizzes', ->
    open = new QuizCollection([{id: 1}])

    view = indexView(null, open, null)
    ok view.options.hasOpenQuizzes

  test '#hasSurveys if has surveys', ->
    surveys = new QuizCollection([{id: 1}])

    view = indexView(null, null, surveys)
    ok view.options.hasSurveys


  # search filter
  test 'should render the view', ->
    assignments = new QuizCollection([{id: 1, title: 'Foo Title'}, {id: 2, title: 'Bar Title'}])
    open        = new QuizCollection([{id: 3, title: 'Foo Title'}, {id: 4, title: 'Bar Title'}])
    view = indexView(assignments, open)

    equal view.$el.find('.collectionViewItems li').length, 4

  test 'should filter by search term', ->
    assignments = new QuizCollection([{id: 1, title: 'Foo Name'}, {id: 2, title: 'Bar Title'}])
    open        = new QuizCollection([{id: 3, title: 'Baz Title'}, {id: 4, title: 'Qux Name'}])

    view = indexView(assignments, open)
    $('#searchTerm').val('foo')
    view.filterResults()
    equal view.$el.find('.collectionViewItems li').length, 1

    view = indexView(assignments, open)
    $('#searchTerm').val('name')
    view.filterResults()
    equal view.$el.find('.collectionViewItems li').length, 2

