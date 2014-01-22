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
