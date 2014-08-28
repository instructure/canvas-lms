define [
  './base_controller'
  'i18n!create_module_item_quiz'
  '../../models/item'
], (Base, I18n, Item) ->

  CreateHeaderController = Base.extend

    text:
      headerName: I18n.t('header_name', 'Header Name')

    createItem: ->
      header = @get('model')
      item = Item.createRecord
        module_id: @get('moduleController.model.id')
        title: header.title
        type: 'SubHeader'
      item.save()
      item

