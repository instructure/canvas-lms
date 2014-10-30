define [
  'Backbone'
  'compiled/models/Quiz'
  'compiled/collections/QuizCollection'
  'compiled/views/quizzes/QuizItemGroupView'
  'jquery'
  'helpers/fakeENV'
  'helpers/jquery.simulate'
], (Backbone, Quiz, QuizCollection, QuizItemGroupView, $, fakeENV) ->

  fixtures = $('#fixtures')

  createView = (collection) ->
    collection ?= new QuizCollection([{id: 1, title: 'Foo'}, {id: 2, title: 'Bar'}])
    view = new QuizItemGroupView(collection: collection, listId: "assignment-quizzes")
    view.$el.appendTo $('#fixtures')
    view.render()

  module 'QuizItemGroupView',
    setup: -> fakeENV.setup()
    teardown: -> fakeENV.teardown()

  test '#isEmpty is false if any items arent hidden', ->
    collection = new QuizCollection([{id: 1, title: 'Foo'}, {id: 2, title: 'Bar'}])
    view = new createView(collection)
    ok !view.isEmpty()

  test '#isEmpty is true if collection is empty', ->
    collection = new QuizCollection([])
    view = new createView(collection)
    ok view.isEmpty()

  test '#isEmpty is true if all items are hidden', ->
    collection = new QuizCollection([{id: 1, hidden: true}, {id: 2, hidden: true}])
    view = new createView(collection)
    ok view.isEmpty()


  test 'should filter models with title that doesnt match term', ->
    collection = new QuizCollection([{id: 1}, {id: 2}])
    view = createView(collection)
    model = new Quiz(title: "Foo Name")

    ok  view.filter(model, "name")
    ok !view.filter(model, "zzz")

  test 'should not use regexp to filter models', ->
    collection = new QuizCollection([{id: 1}, {id: 2}])
    view = createView(collection)
    model = new Quiz(title: "Foo Name")

    ok !view.filter(model, ".*name")
    ok !view.filter(model, "zzz")

  test 'should filter models with multiple terms', ->
    collection = new QuizCollection([{id: 1}, {id: 2}])
    view = createView(collection)
    model = new Quiz(title: "Foo Name bar")

    ok  view.filter(model, "name bar")
    ok !view.filter(model, "zzz")


  test 'should rerender on filter change', ->
    collection = new QuizCollection([{id: 1, title: 'hey'}, {id: 2, title: 'foo'}])
    view = createView(collection)
    equal view.$el.find('.collectionViewItems li').length, 2

    view.filterResults('hey')
    equal view.$el.find('.collectionViewItems li').length, 1

  test 'should not render no content message if quizzes are available', ->
    collection = new QuizCollection([{id: 1}, {id: 2}])
    view = createView(collection)
    equal view.$el.find('.collectionViewItems li').length, 2
    ok !view.$el.find('.no_content').is(':visible')

  test 'should render no content message if no quizzes available', ->
    collection = new QuizCollection([])
    view = createView(collection)
    equal view.$el.find('.collectionViewItems li').length, 0
    ok view.$el.find('.no_content').is(':visible')


  test 'clicking the header should toggle arrow state', ->
    collection = new QuizCollection([{id: 1}, {id: 2}])
    view = createView(collection)

    ok  view.$('.element_toggler i').hasClass('icon-mini-arrow-down')
    ok !view.$('.element_toggler i').hasClass('icon-mini-arrow-right')

    view.$('.element_toggler').simulate 'click'

    ok !view.$('.element_toggler i').hasClass('icon-mini-arrow-down')
    ok  view.$('.element_toggler i').hasClass('icon-mini-arrow-right')

