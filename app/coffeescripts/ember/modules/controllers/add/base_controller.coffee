define [
  'ember'
  'i18n!create_item_base'
], (Ember, I18n) ->

  {alias} = Ember.computed

  AddBaseController = Ember.Controller.extend

    setSelected: (->
      @set('model.selected', [])
    ).on('init')

