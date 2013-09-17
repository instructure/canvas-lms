define [
  'i18n!context_modules'
  'Backbone'
  'jquery'
  'compiled/collections/ModuleItemCollection'
], (I18n, Backbone, $, ModuleItemCollection) ->

  class Module extends Backbone.Model
    resourceName: 'modules'

    initialize: ->
      @course_id = @get('course_id')
      @course_id ||= @collection.course_id if @collection

      items = @get('items')
      @itemCollection = new ModuleItemCollection items,
        module_id: @get('id')
        course_id: @course_id
      if !items
        @itemCollection.setParam('per_page', 50)
        @itemCollection.fetch()

      super
