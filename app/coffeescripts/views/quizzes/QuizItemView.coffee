define [
  'i18n!quizzes.index'
  'jquery'
  'underscore'
  'Backbone'
  'jsx/shared/conditional_release/CyoeHelper'
  'compiled/views/PublishIconView'
  'compiled/views/assignments/DateDueColumnView'
  'compiled/views/assignments/DateAvailableColumnView'
  'compiled/views/SisButtonView'
  'jst/quizzes/QuizItemView'
  'jquery.disableWhileLoading'
], (I18n, $, _, Backbone, CyoeHelper, PublishIconView, DateDueColumnView, DateAvailableColumnView, SisButtonView, template) ->

  class ItemView extends Backbone.View

    template: template

    tagName:   'li'
    className: 'quiz'

    @child 'publishIconView',         '[data-view=publish-icon]'
    @child 'dateDueColumnView',       '[data-view=date-due]'
    @child 'dateAvailableColumnView', '[data-view=date-available]'
    @child 'sisButtonView',           '[data-view=sis-button]'

    events:
      'click': 'clickRow'
      'click .delete-item': 'onDelete'
      'click .migrate': 'migrateQuiz'

    messages:
      confirm: I18n.t('confirms.delete_quiz', 'Are you sure you want to delete this quiz?')
      multipleDates: I18n.t('multiple_due_dates', 'Multiple Dates')
      deleteSuccessful: I18n.t('flash.removed', 'Quiz successfully deleted.')
      deleteFail: I18n.t('flash.fail', 'Quiz deletion failed.')

    initialize: (options) ->
      @initializeChildViews()
      @observeModel()
      super

    initializeChildViews: ->
      @publishIconView = false
      @sisButtonView = false

      if @canManage()
        @publishIconView = new PublishIconView(model: @model)
        if @model.postToSISEnabled()
          @sisButtonView = new SisButtonView(model: @model, sisName: @model.postToSISName())

      @dateDueColumnView       = new DateDueColumnView(model: @model)
      @dateAvailableColumnView = new DateAvailableColumnView(model: @model)

    afterRender: ->
      this.$el.toggleClass('quiz-loading-overrides', !!@model.get('loadingOverrides'))

    # make clicks follow through to url for entire row
    clickRow: (e) =>
      target = $(e.target)
      return if target.parents('.ig-admin').length > 0 or target.hasClass 'ig-title'

      row   = target.parents('li')
      title = row.find('.ig-title')
      @redirectTo title.attr('href') if title.length > 0

    redirectTo: (path) ->
      location.href = path

    migrateQuizEnabled: =>
      return ENV.FLAGS && ENV.FLAGS.migrate_quiz_enabled

    migrateQuiz: (e) =>
      e.preventDefault()
      courseId = ENV.context_asset_string.split('_')[1]
      quizId = @options.model.id
      url = "/api/v1/courses/#{courseId}/content_exports?export_type=quizzes2&quiz_id=#{quizId}"
      dfd = $.ajaxJSON url, 'POST'
      @$el.disableWhileLoading dfd
      $.when(dfd)
        .done (response, status, deferred) =>
          $.flashMessage I18n.t('Migration successful')
        .fail =>
          $.flashError I18n.t("An error occurred while migrating.")

    canDelete: ->
      @model.get('permissions').delete

    onDelete: (e) =>
      e.preventDefault()
      if @canDelete()
        @delete() if confirm(@messages.confirm)

    # delete quiz item
    delete: ->
      @$el.hide()
      @model.destroy
        success : =>
          @$el.remove()
          $.flashMessage @messages.deleteSuccessful
        error : =>
          @$el.show()
          $.flashError @messages.deleteFail

    observeModel: ->
      @model.on('change:published', @updatePublishState)
      @model.on('change:loadingOverrides', @render)

    updatePublishState: =>
      @$('.ig-row').toggleClass('ig-published', @model.get('published'))

    canManage: ->
      ENV.PERMISSIONS.manage

    toJSON: ->
      base = _.extend(@model.toJSON(), @options)
      base.quiz_menu_tools = ENV.quiz_menu_tools
      _.each base.quiz_menu_tools, (tool) =>
        tool.url = tool.base_url + "&quizzes[]=#{@model.get("id")}"

      base.cyoe = CyoeHelper.getItemData(base.assignment_id, base.quiz_type == 'assignment')
      base.return_to = encodeURIComponent window.location.pathname

      if @model.get("multiple_due_dates")
        base.selector  = @model.get("id")
        base.link_text = @messages.multipleDates
        base.link_href = @model.get("url")

      base.migrateQuizEnabled = @migrateQuizEnabled
      base.showAvailability = @model.multipleDueDates() or not @model.defaultDates().available()
      base.showDueDate = @model.multipleDueDates() or @model.singleSectionDueDate()
      base
