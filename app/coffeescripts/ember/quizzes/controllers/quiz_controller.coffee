define [
  'ember'
], (Ember) ->

  QuizController = Ember.ObjectController.extend

    actions:
      publish: ->
        @set 'published', true
        @get('model').save()

      unpublish: ->
        @set 'published', false
        @get('model').save()

    # Kind of a gross hack so we can get quiz arrows in...
    addLegacyJS: (->
      return unless @get('quizSubmissionHTML.html')
      Ember.$(document.body).append """
        <script src="/javascripts/compiled/bundles/quiz_show.js"></script>
      """
    ).observes('quizSubmissionHTML.html')
