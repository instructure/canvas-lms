define [
  'jquery'
  'underscore'
  'vendor/jquery.ba-tinypubsub'
], ($, _) -> 
  # Handles rendering the correct view depending on the 
  # value selected. 
  class ConverterViewControl
    @subscribed = false
    @registeredViews = []
    
    # Returns an instance of the model. This model has 
    # been cached so can only be set once. Used to 
    # ensure multiple bundle files are using the same
    # model instance
    # -----------------------------------------------
    # @api public
    # @returns Object (Backbone Model)

    @getModel: -> @_model
    
    # Set and instance of a model. Only sets the model
    # once so we don't have more than one model used 
    # between multiple bundle files.
    # -----------------------------------------------
    # @api public
    # @expects Backbone.Model instance

    @setModel: (model) -> @_model = model unless @_model
    
    # Adds the options to the registeredViews
    # The options should include a 'view' and 
    # a value in the options hash. This also
    # will subscribe to the pubsub one time 
    # if there haven't been any previous 
    # subscriptions. 
    #
    # options look like this
    # ie: 
    #     {key: 'id_of_view', view: new BackboneView}
    #
    # @api public

    @register: (options) -> 
      @registeredViews.push options

      unless @subscribed
        $.subscribe 'contentImportChange', @renderView
        @subscribed = true

    # Clears and resets this control class. 
    # * sets subscribed to false
    # * clears out any old views

    @resetControl: -> 
      @subscribed = false
      @registeredViews.length = 0 # clears the array

    @getView: (key) =>
      _.find @registeredViews, (regView) -> regView.key == key

    # Find the view for which the value we are looking for 
    # exists and render it in the parent view. This is tightly
    # coupled to a converter view being passed in. Maybe there
    # is a better way to handle this. Sets the migrationConverterView's
    # validateBeforeSave function which is an override comming from 
    # the ValidatedFormView which the migrationConverterView should 
    # be extending. 
    #
    # @api private

    @renderView: (options) => 
      value = options.value
      migrationConverterView = options.migrationConverter

      regView = @getView(value)

      if regView?.view?.validateBeforeSave
        migrationConverterView.validateBeforeSave = regView.view.validateBeforeSave

      migrationConverterView.renderConverter regView?.view
