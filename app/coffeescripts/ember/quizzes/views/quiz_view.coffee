define [
  'ember'
  '../shared/environment'
  'compiled/jquery/ModuleSequenceFooter'
], (Ember, environment) ->
  QuizView = Ember.View.extend
    addModuleSequenceFooter: (->
      this.$('#module_sequence_footer').moduleSequenceFooter(
        courseID: environment.get('courseId')
        assetType: 'Quiz'
        assetID: @controller.get("id")
      )
    ).on('didInsertElement')


