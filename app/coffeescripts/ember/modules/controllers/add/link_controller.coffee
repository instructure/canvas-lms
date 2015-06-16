define [
  './base_controller'
  'i18n!create_module_item_quiz'
  '../../models/item'
], (Base, I18n, Item) ->

  CreateLinkController = Base.extend

    text:
      title: I18n.t('link_title', 'Link Title')
      url: I18n.t('url', 'URL')

    createItem: ->
      link = @get('model')
      item = Item.createRecord
        module_id: @get('moduleController.model.id')
        type: 'ExternalUrl'
        title: link.title
        external_url: link.url
      item.save()
      item

