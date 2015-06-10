define [
  './base_controller'
  'i18n!add_module_item'
  '../../../shared/xhr/fetch_all_pages'
  'ic-ajax'
  '../../models/item'
], (Base, I18n, fetch, {request}, Item) ->

  AddFileController = Base.extend

    # TODO: should move this to a model or something, or cache by URLs
    files: (->
      @constructor.files or= fetch("/api/v1/courses/#{ENV.course_id}/files")
    ).property()

    title: (->
      I18n.t('add_file_to', "Add a files to %{module}", module: @get('moduleController.name'))
    ).property('moduleController.name')

    actions:

      toggleSelected: (file) ->
        files = @get('model.selected')
        if files.contains(file)
          files.removeObject(file)
        else
          files.addObject(file)

  AddFileController.reopenClass

    files: null

