define [
  './base_controller'
  'i18n!create_module_item_quiz'
  '../../models/item'
  'ic-ajax'
], (Base, I18n, Item, {request}) ->

  CreatePageController = Base.extend

    text:
      pageName: I18n.t('page_name', 'Page Name')

    createItem: ->
      page = @get('model')
      item = Item.createRecord(title: page.title, type: 'Page')
      request(
        url: "/api/v1/courses/#{ENV.course_id}/pages"
        type: 'post'
        data: wiki_page: page
      ).then(((savedPage) =>
        item.set('content_id', savedPage.id)
        item.set('page_url', savedPage.url)
        item.save()
      ), (=>
        item.set('error', true)
      ))
      item

