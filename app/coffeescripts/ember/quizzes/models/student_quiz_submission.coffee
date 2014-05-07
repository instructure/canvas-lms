define [
  './quiz_submission'
  'ember-data'
], (QuizSubmission, DS) ->

  {belongsTo, attr} = DS

  StudentQuizSubmission = QuizSubmission.extend
    quiz: belongsTo 'quiz', async: false, inverse: 'studentQuizSubmissions'
