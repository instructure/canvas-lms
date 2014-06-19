define [
  'ember'
  'ic-tabs'
], (Ember) ->

  ScreenreaderGradebookView = Ember.View.extend

    didInsertElement: ->
      #horrible hack to get disabled instead of disabled="disabled" on buttons
      this.$('button:disabled').prop('disabled', true)
