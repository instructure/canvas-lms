define [
  'ember'
  'i18n!create_item_base'
], (Ember, I18n) ->

  {alias} = Ember.computed

  CreateBaseController = Ember.Controller.extend

    item: null

    moduleController: alias('parentController.parentController')

    addItemController: alias('parentController')

    removeOnError: (->
      item = @get('item')
      error = item.get('error')
      return unless error
      alert(I18n.t("there_was_an_error", 'There was an error saving "%{title}", please try again.', title: item.get('title')))
      @get('moduleController.items').removeObject(item)
    ).observes('item.error')

    actions:

      create: ->
        item = @createItem()
        item.set('module_id', @get('moduleController.model.id'))
        @get('moduleController.items').addObject(item)
        @get('addItemController').send('quitEditing')
        @set('item', item)

      cancel: ->
        @get('parentController').send('quitEditing')

