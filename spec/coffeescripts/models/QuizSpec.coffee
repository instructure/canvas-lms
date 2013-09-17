define [
  'jquery'
  'compiled/models/Quiz'
  'compiled/models/Assignment'
  'compiled/collections/AssignmentOverrideCollection'
  'jquery.ajaxJSON'
], ($, Quiz, Assignment, AssignmentOverrideCollection) ->

  module 'Quiz',
    setup: ->
      @quiz = new Quiz(id: 1, html_url: 'http://localhost:3000/courses/1/quizzes/24')
      @ajaxStub = sinon.stub $, 'ajaxJSON'

    teardown: ->
      $.ajaxJSON.restore()


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


  test '#initialize defaults publishable to true', ->
    ok @quiz.get('publishable')

  test '#initialize sets publishable to false', ->
    @quiz = new Quiz(publishable: false)
    ok !@quiz.get('publishable')

  test '#initialize sets publishable from can_unpublish and published', ->
    @quiz = new Quiz(can_unpublish: false, published: true)
    ok !@quiz.get('publishable')


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
    equal @quiz.get('possible_points_label'), '0 pts'

  test "#initialize sets possible points count with 1 points", ->
    @quiz = new Quiz(points_possible: 1)
    equal @quiz.get('possible_points_label'), "1 pt"

  test "#initialize sets possible points count with 2 points", ->
    @quiz = new Quiz(points_possible: 2)
    equal @quiz.get('possible_points_label'), "2 pts"


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
