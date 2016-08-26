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

  createView = (quiz, options={}) ->
    quiz ?= new Quiz(id: 1, title: 'Foo')

    icon = new PublishIconView(model: quiz)

    ENV.PERMISSIONS = {
      manage: options.canManage
    }

    ENV.FLAGS = {
      post_to_sis_enabled: options.post_to_sis
    }

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

  test "initializes sis toggle if post to sis enabled", ->
    quiz = new Quiz(id: 1, title: 'Foo', can_update: true)
    view = createView(quiz, canManage: true, post_to_sis: true)
    ok view.sisButtonView

  test "does not initialize sis toggle if post to sis disabled", ->
    quiz = new Quiz(id: 1, title: 'Foo', can_update: true)
    view = createView(quiz, canManage: true, post_to_sis: false)
    ok !view.sisButtonView

  test "does not initialize sis toggle if sis enabled but can't manage", ->
    quiz = new Quiz(id: 1, title: 'Foo', can_update: false)
    view = createView(quiz, canManage: false, post_to_sis: false)
    ok !view.sisButtonView

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

  test 'renders lockAt/unlockAt for multiple due dates', ->
    quiz = new Quiz(id: 1, title: 'mdd', all_dates: [
      { due_at: new Date() },
      { due_at: new Date() }
    ])
    view = createView(quiz)
    json = view.toJSON()
    equal json.showAvailability, true

  test 'renders lockAt/unlockAt when locked', ->
    future = new Date()
    future.setDate(future.getDate() + 10)
    quiz = new Quiz(id: 1, title: 'mdd', unlock_at: future.toISOString())
    view = createView(quiz)
    json = view.toJSON()
    equal json.showAvailability, true

  test 'renders lockAt/unlockAt when locking in future', ->
    past = new Date()
    past.setDate(past.getDate() - 10)
    future = new Date()
    future.setDate(future.getDate() + 10)
    quiz = new Quiz(
      id: 1,
      title: 'unlock later',
      unlock_at: past.toISOString(),
      lock_at: future.toISOString())
    view = createView(quiz)
    json = view.toJSON()
    equal json.showAvailability, true

  test 'does not render lockAt/unlockAt when not locking in future', ->
    past = new Date()
    past.setDate(past.getDate() - 10)
    quiz = new Quiz(id: 1, title: 'unlocked for good', unlock_at: past.toISOString())
    view = createView(quiz)
    json = view.toJSON()
    equal json.showAvailability, false
