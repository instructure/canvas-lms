define [
  'jquery'
  'compiled/models/Quiz'
  'compiled/collections/AssignmentOverrideCollection'
  'jquery.ajaxJSON'
], ($, Quiz, AssignmentOverrideCollection) ->

  module 'Quiz',
    setup: ->
      @quiz = new Quiz({id: 1}, {baseUrl: '/courses/1/quizzes'})
      @ajaxStub = sinon.stub $, 'ajaxJSON'

    teardown: ->
      $.ajaxJSON.restore()

  test '#initialize defaults publishable to true', ->
    ok @quiz.get("publishable")

  test '#initialize sets publishable to false', ->
    @quiz = new Quiz(publishable: false)
    ok !@quiz.get('publishable')

  test "#initialize ignores assignment_overrides if not given", ->
    ok !@quiz.get("assignment_overrides")

  test "#initialize assigns assignment_override collection", ->
    @quiz = new Quiz(assignment_overrides: [])
    equal @quiz.get("assignment_overrides").constructor, AssignmentOverrideCollection

  test "#publish saves to the server", ->
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

  test '#publishUrl builds url from baseUrl', ->
    equal @quiz.publishUrl(), "/courses/1/quizzes/publish"

  test '#unpublishUrl builds url from baseUrl', ->
    equal @quiz.unpublishUrl(), "/courses/1/quizzes/unpublish"
