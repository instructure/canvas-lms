define [
  'jquery'
  'compiled/models/Quiz'
  'compiled/models/Assignment'
  'compiled/models/DateGroup'
  'compiled/collections/AssignmentOverrideCollection'
  'jquery.ajaxJSON'
], ($, Quiz, Assignment, DateGroup, AssignmentOverrideCollection) ->

  QUnit.module 'Quiz',
    setup: ->
      @quiz = new Quiz(id: 1, html_url: 'http://localhost:3000/courses/1/quizzes/24')
      @ajaxStub = @stub $, 'ajaxJSON'

    teardown: ->

  # Initialize

  test '#initialize ignores assignment if not given', ->
    ok !@quiz.get('assignment')

  test '#initialize sets assignment', ->
    assign = id: 1, title: 'Foo Bar'
    @quiz = new Quiz(assignment: assign)
    equal @quiz.get('assignment').constructor, Assignment

  test '#initialize ignores assignment_overrides if not given', ->
    ok !@quiz.get('assignment_overrides')

  test '#initialize assigns assignment_override collection', ->
    @quiz = new Quiz(assignment_overrides: [])
    equal @quiz.get('assignment_overrides').constructor, AssignmentOverrideCollection

  test '#initialize should set url from html url', ->
    equal @quiz.get('url'), 'http://localhost:3000/courses/1/quizzes/1'

  test '#initialize should set edit_url from html url', ->
    equal @quiz.get('edit_url'), 'http://localhost:3000/courses/1/quizzes/1/edit'

  test '#initialize should set publish_url from html url', ->
    equal @quiz.get('publish_url'), 'http://localhost:3000/courses/1/quizzes/publish'

  test '#initialize should set unpublish_url from html url', ->
    equal @quiz.get('unpublish_url'), 'http://localhost:3000/courses/1/quizzes/unpublish'

  test '#initialize should set title_label from title', ->
    @quiz = new Quiz(title: 'My Quiz!', readable_type: 'Quiz')
    equal @quiz.get('title_label'), 'My Quiz!'

  test '#initialize should set title_label from readable_type', ->
    @quiz = new Quiz(readable_type: 'Quiz')
    equal @quiz.get('title_label'), 'Quiz'

  test '#initialize defaults unpublishable to true', ->
    ok @quiz.get('unpublishable')

  test '#initialize sets unpublishable to false', ->
    @quiz = new Quiz(unpublishable: false)
    ok !@quiz.get('unpublishable')

  test '#initialize sets publishable from can_unpublish and published', ->
    @quiz = new Quiz(can_unpublish: false, published: true)
    ok !@quiz.get('unpublishable')

  test "#initialize sets question count", ->
    @quiz = new Quiz(question_count: 1, published: true)
    equal @quiz.get('question_count_label'), "1 Question"

    @quiz = new Quiz(question_count: 2, published: true)
    equal @quiz.get('question_count_label'), "2 Questions"

  test "#initialize sets possible points count with no points", ->
    @quiz = new Quiz()
    equal @quiz.get('possible_points_label'), ''

  test "#initialize sets possible points count with 0 points", ->
    @quiz = new Quiz(points_possible: 0)
    equal @quiz.get('possible_points_label'), ''

  test "#initialize sets possible points count with 1 points", ->
    @quiz = new Quiz(points_possible: 1)
    equal @quiz.get('possible_points_label'), "1 pt"

  test "#initialize sets possible points count with 2 points", ->
    @quiz = new Quiz(points_possible: 2)
    equal @quiz.get('possible_points_label'), "2 pts"

  test "#initialize points possible to null if ungraded survey", ->
    @quiz = new Quiz(points_possible: 5, quiz_type: "survey")
    equal @quiz.get('possible_points_label'), ""

  # Publishing

  test '#publish saves to the server', ->
    @quiz.publish()
    ok @ajaxStub.called

  test '#publish sets published attribute to true', ->
    @quiz.publish()
    ok @quiz.get('published')

  test '#unpublish saves to the server', ->
    @quiz.unpublish()
    ok @ajaxStub.called

  test '#unpublish sets published attribute to false', ->
    @quiz.unpublish()
    ok !@quiz.get('published')

  # multiple due dates

  QUnit.module "Quiz#multipleDueDates"

  test "checks for multiple due dates from assignment overrides", ->
    quiz = new Quiz all_dates: [{title: "Winter"}, {title: "Summer"}]
    ok quiz.multipleDueDates()

  test "checks for no multiple due dates from quiz overrides", ->
    quiz = new Quiz
    ok !quiz.multipleDueDates()

  QUnit.module "Quiz#allDates"

  test "gets the due dates from the assignment overrides", ->
    dueAt = new Date("2013-08-20T11:13:00Z")
    dates = [
      new DateGroup due_at: dueAt, title: "Everyone"
    ]
    quiz     = new Quiz all_dates: dates
    allDates = quiz.allDates()
    first    = allDates[0]

    equal first.dueAt+"", dueAt+""
    equal first.dueFor,   "Everyone"

  test "gets empty due dates when there are no dates", ->
    quiz = new Quiz
    deepEqual quiz.allDates(), []


  # single section due date

  test "gets the due date for section instead of null", ->
    dueAt = new Date("2013-11-27T11:01:00Z")
    quiz = new Quiz all_dates: [
      {due_at: null, title: "Everyone"},
      {due_at: dueAt, title: "Summer"}
    ]
    @stub quiz, "multipleDueDates", -> false
    deepEqual quiz.singleSectionDueDate(), dueAt.toISOString()

  test "returns due_at when only one date/section are present", ->
    date = Date.now()
    quiz = new Quiz name: 'Taco party!'
    quiz.set 'due_at', date
    deepEqual quiz.singleSectionDueDate(), quiz.dueAt()

  # toView

  QUnit.module "Quiz#toView"

  test "returns the quiz's dueAt", ->
    date = Date.now()
    quiz = new Quiz name: 'foo'
    quiz.dueAt date
    json = quiz.toView()
    deepEqual json.dueAt, date

  test "returns quiz's lockAt", ->
    lockAt = Date.now()
    quiz = new Quiz name: 'foo'
    quiz.lockAt lockAt
    json = quiz.toView()
    deepEqual json.lockAt, lockAt

  test "includes quiz's unlockAt", ->
    unlockAt = Date.now()
    quiz = new Quiz name: 'foo'
    quiz.unlockAt unlockAt
    json = quiz.toView()
    deepEqual json.unlockAt, unlockAt

  test "includes htmlUrl", ->
    quiz = new Quiz url: 'http://example.com/quizzes/1'
    json = quiz.toView()
    deepEqual json.htmlUrl, 'http://example.com/quizzes/1'

  test "includes multipleDueDates", ->
    quiz = new Quiz all_dates: [{title: "Summer"}, {title: "Winter"}]
    json = quiz.toView()
    deepEqual json.multipleDueDates, true

  test "includes allDates", ->
    quiz = new Quiz all_dates: [{title: "Summer"}, {title: "Winter"}]
    json = quiz.toView()
    equal json.allDates.length, 2

  test "includes singleSectionDueDate", ->
    dueAt = new Date("2013-11-27T11:01:00Z")
    quiz = new Quiz all_dates: [
      {due_at: null, title: "Everyone"},
      {due_at: dueAt, title: "Summer"}
    ]
    @stub quiz, "multipleDueDates", -> false
    json = quiz.toView()
    equal json.singleSectionDueDate, dueAt.toISOString()
