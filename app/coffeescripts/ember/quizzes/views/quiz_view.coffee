define [
  'ember'
  '../shared/environment'
  'compiled/jquery/ModuleSequenceFooter'
], (Ember, environment) ->
  QuizView = Ember.View.extend
    addBreadCrumb: (->
      quizUrl = @controller.get('htmlURL')
      breadcrumb = $(
        "<li><a href=\"#{quizUrl}\"><span class=\"ellipsible\">" +
          @controller.get("title") +
        "</span></a></li>")
      $("#breadcrumbs ul").append(breadcrumb)
    ).on('didInsertElement')

    removeBreadcrumb: (->
      $("#breadcrumbs li").last().remove()
    ).on('willDestroyElement')

    addModuleSequenceFooter: (->
      this.$('#module_sequence_footer').moduleSequenceFooter(
        courseID: environment.get('courseId')
        assetType: 'Quiz'
        assetID: @controller.get("id")
      )
    ).on('didInsertElement')


