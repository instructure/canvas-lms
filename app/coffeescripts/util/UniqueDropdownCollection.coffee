define [
  'Backbone'
  'underscore'
], (Backbone, _) ->

  # For all your dropdown widget-y needs.
  #
  # Example: Say I have a list of sections I want to assign for some due dates.
  # I have an example UI that has several <select> dropdowns that looks like:
  #
  # <select name="section_id"><!-- options go here... ></select>
  # <input type=date name="due_date"/>
  #
  # Imagine you have 4 sections in the course, so you'd have 4 widgets
  # with the above markup.
  #
  # However, say you have a unique constraint that a section may only have one
  # due date. To help the user's experience, we want to hide sections that
  # have already been assigned a due date in the other drop downs. We also
  # want to make the interface very responsive, so adding changing the section
  # in one dropdown makes the section available to choose in all the other
  # dropdowns (since it was previously taken, but now available to choose from).
  # You can use the variable due date widget to see an example of this behavior.
  # (NOTE: The variable due date widget doesn't use this... yet)
  #
  # UniqueDropdownCollection will watch your models for change events, so
  # when your passed 'propertyName' value changes, UniqueDropdownCollection
  # will remove it from `collection.takenValues` and add it to
  # `collection.availableValues` accordingly. `availableValues` and
  # `takenValues` are both instances of `Backbone.Collection`, so you
  # can use the handy dandy `change/add/remove` events we all love. See
  # the documentation below for what kind of objects these collections
  # store the possible values as.
  #
  # You can also call `add/remove` like you would on a normal
  # `Backbone.Collection`. UniqueDropdownCollection will make a value
  # available if you remove the record, and taken if you create a new record
  # (the new record will have the first available value in `availableValues`.
  #
  # Example:
  #
  # ENV.SECTION_IDS = [1, 2, 3, 4]
  # models = (new Assignment(id: i, section_id: i) for i in [1..3])
  #
  # collection = new UniqueDropdownCollection models,
  #   model: Assignment
  #   propertyName: 'section_id'
  #   possibleValues: ENV.SECTION_IDS
  #
  # collection.availableValues.find (m) -> m.get('value') == 4 # true
  # collection.takenValues.find (m) -> m.get('value') == 4 # false
  #
  # models[0].set 'section_id', 4
  #
  # collection.availableValues.find (m) -> m.get('value') == 4 # false
  # collection.takenValues.find (m) -> m.get('value') == 4 # true
  #
  # Listening for changes on `availableValues` and `takenValues`
  #
  # These collections have objects that look like this:
  #
  #   id: 'some value goes here'
  #   value: 'some value goes here'
  #
  # If you're going to listen on these collections, I recommend listening on
  # the `add/remove` events of the collections, and re-render your dropdown
  # accordingly.

  class UniqueDropdownCollection extends Backbone.Collection

    # Public
    # records - Array of records to watch for changes on
    # options: a hash with the usual options Backbone.Collection takes, with
    # a few extra added goodies:
    #   propertyName: string representing the property name on your model.
    #     e.g. model.get('section_id')
    #   possibleValues: an array of possible values `propertyName` can
    #     choose from
    #
    # NOTE: BE SURE TO PASS A `model` OPTION!
    initialize: (records, options={}) ->
      @takenValues ||= new Backbone.Collection []
      @availableValues ||= new Backbone.Collection []
      {@possibleValues, @propertyName} = options
      @availableValues.comparator = 'value'
      @calculateTakenValues(records)

      @on "reset", @calculateTakenValues
      @on "change:#{@propertyName}", @updateAvailableValues
      @on "remove", @removeModel

    calculateTakenValues: (records) =>
      if records instanceof Backbone.Collection
        takenValues = records.map (m) => m.get(@propertyName)
      else
        takenValues = (model.get(@propertyName) for model in records)

      # we need to reset the collections so that
      # we can calculate the fresh taken and available values
      @takenValues.reset null, silent: true
      @availableValues.reset null, silent: true
      # Create Backbone Models with IDs so we can remove and add them
      # quickly (rather than filtering and removing from an index every time)
      # in @takenValues and @availableValues
      for takenValue in takenValues
        @takenValues.add new Backbone.Model id: takenValue, value: takenValue

      for value in _.difference @possibleValues, takenValues
        @availableValues.add new Backbone.Model id: value, value: value


    updateAvailableValues: (model) =>
      previousValue = model.previousAttributes()[@propertyName]
      currentValue = model.get(@propertyName)

      previouslyAvailableValue = @availableValues.get currentValue
      previouslyTakenValue = @takenValues.get previousValue

      @availableValues.remove previouslyAvailableValue
      @takenValues.remove previouslyTakenValue

      @takenValues.add previouslyAvailableValue
      @availableValues.add previouslyTakenValue


    removeModel: (model) =>
      value = model.get @propertyName
      previouslyTakenValue = @takenValues.get value

      @takenValues.remove previouslyTakenValue
      @availableValues.add previouslyTakenValue

    # method for how to find the next model to add.
    # defaults to the first item 
    # in @availableValues
    #
    # override if you need more complex logic
    #
    # Returns a model from @availableValues
    findNextAvailable: ->
      @availableValues.at(0)

    # overrides Backbone.Collection.add
    add: (models, options) ->
      # if we pass a plan object, modify it with an available value before
      # passing it to the "model" constructor.
      if !_.isArray(models) && (typeof models is 'object') && !(models instanceof Backbone.Model)
        previouslyAvailableValue = @findNextAvailable()
        @availableValues.remove previouslyAvailableValue
        @takenValues.add previouslyAvailableValue
        models[@propertyName] = previouslyAvailableValue.get 'value'

      super


