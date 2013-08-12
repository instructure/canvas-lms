define [
  'i18n!quizzes'
  'Backbone'
  'compiled/models/Quiz'
], (I18n, Backbone, Quiz) ->

  class QuizCollection extends Backbone.Collection

    model: Quiz
