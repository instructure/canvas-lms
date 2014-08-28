define [
  'underscore'
  'jquery'
  'Backbone'
  'jquery.instructure_forms'
], (_,$, Backbone) ->
  class ContentMigration extends Backbone.Model
    urlRoot: => "/api/v1/courses/#{@get('course_id')}/content_migrations"
    @dynamicDefaults = {}

    # Creates a dynamic default for this models attributes. This means that
    # the default values for this model (instance) will be whatever it was 
    # set to originally.
    #   id: 
    #      model = new ContentMigration foo: 'bar', cat: 'Fluffy'
    #      model.set('pill', adderall) # don't do drugs...
    #      
    #      model.dynamicDefaults = {foo: 'bar', cat: 'Fluffy'} 
    # @api public backbone override

    initialize:(attributes) -> 
      super
      @dynamicDefaults = attributes

    # Clears all attributes on the model and reset's the model to it's 
    # origional state when initialized. Uses the dynamicDefaults to 
    # determin which properties were used.
    #
    # @api public

    resetModel: -> 
      @clear()
      @resetDynamicDefaultCollections()
      @set @dynamicDefaults

    # Loop through all defaults and reset any collections to be blank that
    # might exist. 
    #
    # @api private

    resetDynamicDefaultCollections: -> 
      _.each @dynamicDefaults, (value, key, list) ->
        if value instanceof Backbone.Collection
          collection = value
          
          # Force models into an new array since we modify collections
          # models in the .each which effects the loop since
          # collection.models is pass by reference.
          models = collection.map (model) -> model
          _.each models, (model) -> collection.remove model

    # Handles two cases. Migration with and without a file. 
    # When saving we extract the fileElement (input type="file" dom node) 
    # so we can then pass it into our custom "multipart" upload function. 
    #
    # Steps: 
    #   * Get file element
    #   * Save the migration model which should start the process but does
    #     not up upload the file at this point
    #   * Create a temp backbone model that uses the url recieved back from
    #     the first migration save. This is the url used to save the actual 
    #     migration file. 
    #   * Save the temp backbone model which will upload the file to amazon
    #     and return a 302 from which we can start processing the migration
    #     file. 
    #
    #  @returns deffered object
    #  @api public backbone override

    save: =>
      return super unless @get('pre_attachment') # No attachment, regular save
      dObject = $.Deferred()

      fileElement = @get('pre_attachment').fileElement
      delete @get('pre_attachment').fileElement

      super _.omit(arguments[0], 'file'),
        error: (xhr) => dObject.rejectWith(this, xhr.responseText)
        success: (model, xhr, options) => 
          tempModel = new Backbone.Model(@get('pre_attachment').upload_params)
          tempModel.url = => @get('pre_attachment').upload_url
          tempModel.set('attachment', fileElement)

          tempModel.save null,
            multipart: fileElement 
            success: (model, xhr) => 
              return dObject.rejectWith(this, xhr.message) if xhr.message
              this.fetch success: => dObject.resolve() # sets the poll url
            error: (message) => dObject.rejectWith(this, message)

      dObject

    # These models will have many SubDayModels via a collection. This model has attributes
    # that must go with the request. 
    #
    # @api private backbone override

    toJSON: -> 
      json = super
      @addDaySubsitutions(json)
      @translateDateAdjustmentParams(json)
      json

    # Add day substituions to a json object if this model has a daySubCollection. 
    # remember json is pass by reference so changes are reflected on the origional
    # json object
    # 
    # @api private

    addDaySubsitutions: (json) => 
      collection = @daySubCollection
      json.date_shift_options ||= {}
      json.date_shift_options.day_substitutions = collection.toJSON() if collection

    # Convert date adjustment (shift / remove) radio buttons into the format
    # expected by the Canvas API
    #
    # @api private

    translateDateAdjustmentParams: (json) =>
      if json.adjust_dates
        if json.adjust_dates.enabled == '1'
          json.date_shift_options[json.adjust_dates.operation] = '1'
        delete json.adjust_dates

