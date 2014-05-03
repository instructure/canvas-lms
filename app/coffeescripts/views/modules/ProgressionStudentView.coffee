define [
  'i18n!context_modules'
  'jquery'
  'Backbone'
  'compiled/collections/ModuleCollection'
  'jst/modules/ProgressionStudentView'
  'jst/modules/ProgressionModuleCollection'
  'compiled/views/PaginatedCollectionView'
  'compiled/views/modules/ProgressionModuleView'
], (I18n, $, Backbone, ModuleCollection, template, collectionTemplate, PaginatedCollectionView, ProgressionModuleView) ->

  class ProgressionStudentView extends Backbone.View

    tagName: 'li'
    className: 'student'
    template: template

    events:
      'click': 'showProgressions'

    initialize: ->
      super
      @$index = @model.collection.view.$el
      @$students = @$index.find('#progression_students')
      @$modules = @$index.find('#progression_modules')

    afterRender: ->
      super
      @showProgressions() if !@model.collection.currentStudentView
      @syncHeight()

    createProgressions: ->
      studentId = @model.get('id')
      modules = new ModuleCollection null,
        course_id: ENV.COURSE_ID
        per_page: 50
        params:
          student_id: studentId
          include: ['items']
      modules.student_id = studentId
      modules.syncHeight = @syncHeight
      modules.fetch()

      studentUrl = "#{ENV.COURSE_USERS_PATH}/#{studentId}"
      @progressions = new PaginatedCollectionView
        collection: modules
        itemView: ProgressionModuleView
        template: collectionTemplate
        student: @model.attributes
        student_link: "<a href='#{studentUrl}'>#{@model.get('name')}</a>"

      @progressions.render()
      @progressions.$el.appendTo(@$modules)

    showProgressions: ->
      @$modules.attr('aria-busy', 'true')
      @model.collection.currentStudentView?.hideProgressions()
      @model.collection.currentStudentView = this

      @syncHeight()
      @$el.addClass('active').attr('aria-selected', true)
      if !@progressions
        @createProgressions()
      else
        @progressions.show()

    hideProgressions: ->
      @progressions.hide()
      @$el.removeClass('active').removeAttr('aria-selected')

    syncHeight: =>
      setTimeout =>
        @$students.height(@$modules.height())
        @$students.find('.collectionViewItems').
          height((@$students.height() || 0) - (@$students.find('.header').height() || 16) - 16)
      , 0

