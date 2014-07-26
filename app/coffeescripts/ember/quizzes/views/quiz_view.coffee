define [
  'ember'
  '../shared/environment'
  '../mixins/views/submission_arrows_view'
  'quiz_rubric'
  'compiled/jquery/ModuleSequenceFooter'
], (Ember, environment, SubmissionArrowsView, createRubricDialog) ->

  QuizView = Ember.View.extend SubmissionArrowsView,

    addBreadCrumb: (->
      quizUrl = @controller.get('htmlURL')
      escapedTitle = $("<div />").text(@controller.get("title")).html()
      breadcrumb = $(
        "<li><a href=\"#{quizUrl}\"><span class=\"ellipsible\">" +
          escapedTitle +
        "</span></a></li>")
      $("#breadcrumbs ul").append(breadcrumb)
    ).on('didInsertElement')

    removeBreadcrumb: (->
      $("#breadcrumbs li").last().remove()
    ).on('willDestroyElement')

    setupViewAddOns: ( ->
      @setupControllerListeners()
      @addModuleSequenceFooter()
    ).on('didInsertElement')

    addModuleSequenceFooter: ->
      this.$('#module_sequence_footer').moduleSequenceFooter(
        courseID: environment.get('courseId')
        assetType: 'Quiz'
        assetID: @controller.get("id")
      )

    setupControllerListeners: ->
      @get('controller').on('rubricDisplayRequest', this, @displayRubric)

    teardownControllerListeners: ( ->
      @get('controller').off('rubricDisplayRequest', this, @displayRubric)
    ).on('willDestroyElement')

    displayRubric: ->
      url = @get('controller.rubricUrl')
      createRubricDialog(url)
