define [
  'compiled/models/Quiz'
  'compiled/collections/QuizCollection'
], (Quiz, QuizCollection) ->
  module 'QuizCollection',

  test 'builds a collection', ->
    collection = new QuizCollection([new Quiz(id: 123)])
    ok collection.get(123)