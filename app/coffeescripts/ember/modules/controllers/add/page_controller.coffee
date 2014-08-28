define [
  './base_controller'
  'i18n!add_module_item'
  '../../../shared/xhr/fetch_all_pages'
  'ic-ajax'
  '../../models/item'
], (Base, I18n, fetch, {request}, Item) ->

  AddPageController = Base.extend

    pages: (->
      @constructor.pages or= fetch("/api/v1/courses/#{ENV.course_id}/pages")
    ).property()

    title: (->
      I18n.t('add_page_to', "Add a pages to %{module}", module: @get('moduleController.name'))
    ).property('moduleController.name')

    actions:

      toggleSelected: (page) ->
        pages = @get('model.selected')
        if pages.contains(page)
          pages.removeObject(page)
        else
          pages.addObject(page)

  AddPageController.reopenClass

    pages: null

