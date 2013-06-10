define [
  'Backbone'
  'jst/content_migrations/ContentCheckbox'
  'compiled/collections/content_migrations/ContentCheckboxCollection'
  'compiled/views/CollectionView'
], (Backbone, template, CheckboxCollection, CollectionView) ->
  class ContentCheckboxView extends Backbone.View
    template: template

    els: 
      '[data-content=sublevelCheckboxes]' : '$sublevelCheckboxes'

    # Bind a change event only to top level checkboxes that are 
    # initially loaded.

    initialize: -> 
      super
      @hasSubItemsUrl = !!@model.get('sub_items_url')
      @hasSubItems = !!@model.get('sub_items')

      @$el.on  "click", "#selectAll-#{@cid}", @checkAllChildren
      @$el.on  "click", "#selectNone-#{@cid}", @uncheckAllChildren

      if @hasSubItemsUrl
        @$el.on "change", "#checkbox-#{@cid}", @toplevelCheckboxEvents

    toJSON: -> 
      json = super
      json.hasSubCheckboxes = @hasSubItems || @hasSubItemsUrl
      json.onlyLabel = @hasSubItems and !@hasSubItemsUrl
      json.checked = @model.collection?.isTopLevel
      json

    # If this checkbox model has sublevel checkboxes, create a new collection view
    # and render the sub-level checkboxes in the collection view. 
    # @api custom backbone override

    afterRender: -> 
      if @hasSubItems
        @sublevelCheckboxes = new CheckboxCollection @model.get('sub_items')
        @renderSublevelCheckboxes()

    # Check/Uncheck all children checkboxes
    # @api private

    checkAllChildren: => @$el.find('[type=checkbox]').prop('checked', true)
    uncheckAllChildren: => @$el.find('[type=checkbox]').prop('checked', false)

    #normalCheckboxEvents: (event) => 
      #if $(event.target).is(':checked')
        #@$el.find('[type=checkbox]').prop('checked', true)
      #else
        #@$el.find('[type=checkbox]').prop('checked', false)
    
    # Determins if we should hide the sublevel checkboxes or 
    # fetch new ones. 
    # @returns undefined
    # @api private

    toplevelCheckboxEvents: (event) => 
      return unless @hasSubItemsUrl

      if $(event.target).is(':checked')
        @$sublevelCheckboxes.hide()
      else
        @$sublevelCheckboxes.show()

        unless @sublevelCheckboxes
          @fetchSublevelCheckboxes()
          @renderSublevelCheckboxes()
    
    # Attempt to fetch sublevel in a new checkbox collection. Cache
    # the collection so it doesn't call the server twice.
    # @api private

    fetchSublevelCheckboxes: -> 
      @sublevelCheckboxes = new CheckboxCollection
      @sublevelCheckboxes.url = @model.get('sub_items_url')

      dfd = @sublevelCheckboxes.fetch()
      @$el.disableWhileLoading dfd
    
    # Render all sublevel checkboxes in a collection view. The template
    # should take care of rendering any "sublevel" checkboxes that may
    # be on each of these models. 
    # @api private

    renderSublevelCheckboxes: -> 
      checkboxCollectionView = new CollectionView
                                 collection: @sublevelCheckboxes
                                 itemView: ContentCheckboxView
                                 el: @$sublevelCheckboxes

      checkboxCollectionView.render()

