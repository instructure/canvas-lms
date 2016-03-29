define [
  'Backbone'
  'compiled/models/Quiz'
  'compiled/views/quizzes/QuizItemView'
  'compiled/views/PublishIconView'
  'jquery'
  'helpers/fakeENV'
  'helpers/jquery.simulate'
], (Backbone, Quiz, QuizItemView, PublishIconView, $, fakeENV) ->

  fixtures = $('#fixtures')

  createView = (quiz) ->
    quiz ?= new Quiz(id: 1, title: 'Foo')

    icon = new PublishIconView(model: quiz)
    view = new QuizItemView(model: quiz, publishIconView: icon)

    view.$el.appendTo $('#fixtures')
    view.render()

  module 'QuizItemView',
    setup: -> fakeENV.setup()
    teardown: -> fakeENV.teardown()

  test 'renders admin if can_update', ->
    quiz = new Quiz(id: 1, title: 'Foo', can_update: true)
    view = createView(quiz)
    equal view.$('.ig-admin').length, 1

  test 'doesnt render admin if can_update is false', ->
    quiz = new Quiz(id: 1, title: 'Foo', can_update: false)
    view = createView(quiz)
    equal view.$('.ig-admin').length, 0


  test 'udpates publish status when model changes', ->
    quiz = new Quiz(id: 1, title: 'Foo', published: false)
    view = createView(quiz)

    ok !view.$el.find(".ig-row").hasClass("ig-published")

    quiz.set("published", true)
    ok view.$el.find(".ig-row").hasClass("ig-published")


  test 'prompts confirm for delete', ->
    quiz = new Quiz(id: 1, title: 'Foo', can_update: true)
    view = createView(quiz)
    quiz.destroy = -> true

    @stub(window, "confirm", -> true )

    view.$('.delete-item').simulate 'click'
    ok window.confirm.called

  test 'confirm delete destroys model', ->
    quiz = new Quiz(id: 1, title: 'Foo', can_update: true)
    view = createView(quiz)

    destroyed = false
    quiz.destroy = ->  destroyed = true
    @stub(window, "confirm", -> true )

    view.$('.delete-item').simulate 'click'
    ok destroyed

  test 'doesnt redirect if clicking on ig-admin area', ->
    view = createView()

    redirected = false
    view.redirectTo = -> redirected = true

    view.$('.ig-admin').simulate 'click'
    ok !redirected

  test 'follows through when clicking on row', ->
    view = createView()

    redirected = false
    view.redirectTo = ->
      redirected = true

    view.$('.ig-details').simulate 'click'
    ok redirected
