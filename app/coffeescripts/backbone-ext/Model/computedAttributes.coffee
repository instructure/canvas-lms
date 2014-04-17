define ['vendor/backbone', 'underscore'], (Backbone, _) ->

  _.extend Backbone.Model.prototype,

    initialize: ->
      @_configureComputedAttributes() if @computedAttributes?

    ##
    # Allows computed attributes. If your attribute depends on other
    # attributes in the model, pass in an object with the dependencies
    # and your computed attribute will stay up-to-date.
    #
    # ex.
    #
    #   class SomeModel extends Backbone.Model
    #
    #     defaults:
    #       first_name: 'Jon'
    #       last_name: 'Doe'
    #
    #     computedAttributes: [
    #       # can send a string for simple attributes
    #       'occupation'
    #
    #       # or an object for attributes with dependencies
    #       {
    #         name: 'fullName'
    #         deps: ['first_name', 'last_name']
    #       }
    #     ]
    #
    #     occupation: ->
    #       # some sort of computation...
    #       'programmer'
    #
    #     fullName: ->
    #       @get('first_name') + ' ' + @get('last_name')
    #
    #
    #  model = new SomeModel()
    #  model.get 'fullName' #> 'Jon Doe'
    #  model.set 'first_name', 'Jane'
    #  model.get 'fullName' #> 'Jane Doe'
    #  model.get 'occupation' #> 'programmer'
    _configureComputedAttributes: ->
      set = (methodName) => @set methodName, @[methodName]()

      _.each @computedAttributes, (methodName) =>
        if typeof methodName is 'string'
          set methodName
        else # config object
          set methodName.name
          eventName = _.map(methodName.deps, (name) -> "change:#{name}").join ' '
          @bind eventName, -> set methodName.name

  Backbone.Model

