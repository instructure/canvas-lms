require [
  'jquery',
  'compiled/collections/UserCollection'
  'jst/modules/ProgressionsIndex'
  'compiled/views/PaginatedCollectionView'
  'compiled/views/modules/ProgressionStudentView'
], ($, UserCollection, progressionsIndexTemplate, PaginatedCollectionView, ProgressionStudentView) ->

  $(document.body).addClass 'context_modules2'

  if ENV.RESTRICTED_LIST
    students = new UserCollection ENV.VISIBLE_STUDENTS
    students.urls = null
  else
    students = new UserCollection null,
      params:
        per_page: 50
        enrollment_type: 'student'

  indexView = new PaginatedCollectionView
    collection: students
    itemView: ProgressionStudentView
    template: progressionsIndexTemplate
    modules_url: ENV.MODULES_URL
    autoFetch: true

  unless ENV.RESTRICTED_LIST
    # attach the view's scroll container once it's populated
    students.fetch success: ->
      return if students.length == 0
      indexView.resetScrollContainer(indexView.$el.find('#progression_students .collectionViewItems'))

  indexView.render()
  if ENV.RESTRICTED_LIST && ENV.VISIBLE_STUDENTS.length == 1
    indexView.$el.find('#progression_students').hide()
  indexView.$el.appendTo($('#content'))

