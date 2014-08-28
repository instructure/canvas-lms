define [
  'i18n!quizzes.index'
  'jquery'
  'underscore'
  'Backbone'
  'compiled/views/PublishIconView'
  'compiled/views/assignments/DateDueColumnView'
  'compiled/views/assignments/DateAvailableColumnView'
  'jst/quizzes/QuizItemView'
], (I18n, $, _, Backbone, PublishIconView, DateDueColumnView, DateAvailableColumnView, template) ->

  class ItemView extends Backbone.View

    template: template

    tagName:   'li'
    className: 'quiz'

    @child 'publishIconView',         '[data-view=publish-icon]'
    @child 'dateDueColumnView',       '[data-view=date-due]'
    @child 'dateAvailableColumnView', '[data-view=date-available]'

    events:
      'click': 'clickRow'
      'click .delete-item': 'onDelete'

    messages:
      confirm: I18n.t('confirms.delete_quiz', 'Are you sure you want to delete this quiz?')
      multipleDates: I18n.t('multiple_due_dates', 'Multiple Dates')

    initialize: (options) ->
      @initializeChildViews()
      @observeModel()
      super

    initializeChildViews: ->
      @publishIconView = false

      if @canManage()
        @publishIconView = new PublishIconView(model: @model)

      @dateDueColumnView       = new DateDueColumnView(model: @model)
      @dateAvailableColumnView = new DateAvailableColumnView(model: @model)

    # make clicks follow through to url for entire row
    clickRow: (e) =>
      target = $(e.target)
      return if target.parents('.ig-admin').length > 0 or target.hasClass 'ig-title'

      row   = target.parents('li')
      title = row.find('.ig-title')
      @redirectTo title.attr('href') if title.length > 0

    redirectTo: (path) ->
      location.href = path

    onDelete: (e) =>
      e.preventDefault()
      @delete() if confirm(@messages.confirm)

    # delete quiz item
    delete: ->
      @model.destroy()
      @$el.remove()

    observeModel: ->
      @model.on('change:published', @upatePublishState)

    upatePublishState: =>
      @$('.ig-row').toggleClass('ig-published', @model.get('published'))

    canManage: ->
      ENV.PERMISSIONS.manage

    toJSON: ->
      base = _.extend(@model.toJSON(), @options)
      base.quiz_menu_tools = ENV.quiz_menu_tools
      _.each base.quiz_menu_tools, (tool) =>
        tool.url = tool.base_url + "&quizzes[]=#{@model.get("id")}"

      if @model.get("multiple_due_dates")
        base.selector  = @model.get("id")
        base.link_text = @messages.multipleDates
        base.link_href = @model.get("url")
      base
