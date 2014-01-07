define [
  'jquery'
  'underscore'
  'Backbone'
  'compiled/collections/NeverDropCollection'
  'compiled/views/assignments/NeverDropCollectionView'
  'helpers/util'
], ($, _, Backbone, NeverDropCollection, NeverDropCollectionView, util) ->

  class AssignmentStub extends Backbone.Model
    name: -> @get('name')
    toView: =>
      name: @get('name')
      id: @id

  class Assignments extends Backbone.Collection
    model: AssignmentStub


  module "NeverDropCollectionView",
    setup: ->
      @clock = sinon.useFakeTimers()
      util.useOldDebounce()
      @assignments = new Assignments((id: "#{i}", name: "Assignment #{i}") for i in [1..3])
      @never_drops = new NeverDropCollection [],
        assignments: @assignments
        ag_id: 'new'
      @view = new NeverDropCollectionView
        collection: @never_drops

      $('#fixtures').empty().append @view.render().el

    teardown: ->
      @clock.restore()
      util.useNormalDebounce()


  addNeverDrop= ->
    @never_drops.add
      id: @never_drops.size()
      label_id: 'new'

  test "possibleValues is set to the range of assignment ids", ->
    deepEqual @never_drops.possibleValues, @assignments.map (a) -> a.id

  test "adding a NeverDrop to the collection reduces availableValues by one", ->
    start_length = @never_drops.availableValues.length
    addNeverDrop.call @
    equal start_length - 1, @never_drops.availableValues.length

  test "adding a NeverDrop renders a <select> with the value from the front of the availableValues collection", ->
    expected_val = @never_drops.availableValues.slice(0)[0].id
    addNeverDrop.call @
    @clock.tick(101)
    view = $('#fixtures').find('select')
    ok view.length, 'a select was rendered'
    equal expected_val, view.val(), 'the selects value is the same as the last available value'

  test "the number of <option>s with the value the same as availableValue should equal the number of selects", ->
    addNeverDrop.call @
    addNeverDrop.call @
    @clock.tick(101)
    available_val = @never_drops.availableValues.at(0).id
    equal $('#fixtures').find('option[value='+ available_val+']').length, 2

  test "removing a NeverDrop from the collection increases availableValues by one", ->
    addNeverDrop.call @
    @clock.tick(101)
    current_size = @never_drops.availableValues.length
    model = @never_drops.at(0)
    @never_drops.remove model
    equal current_size + 1, @never_drops.availableValues.length

  test "removing a NeverDrop from the collection removes the view", ->
    addNeverDrop.call @
    model = @never_drops.at(0)
    @never_drops.remove model

    @clock.tick(101)
    view = $('#fixtures').find('select')
    equal view.length, 0


  test "changing a <select> will remove all <option>s with that value from other selects", ->
    addNeverDrop.call @
    addNeverDrop.call @
    target_id = "1"

    @clock.tick(101)
    ok $('#fixtures').find('option[value='+target_id+']').length, 2
    #change one of the selects
    $('#fixtures').find('select:first').val(target_id).trigger('change')

    @clock.tick(101)
    #should only be one now
    ok $('#fixtures').find('option[value='+target_id+']').length, 1
    # target_id is now taken
    ok @never_drops.takenValues.find (nd) -> nd.id == target_id


  test "changing a <select> will add all <option>s with the previous value to other selects", ->
    addNeverDrop.call @
    addNeverDrop.call @
    change_id = "1"
    target_id = "3"

    @clock.tick(101)
    #should just have the selected one
    ok $('#fixtures').find('option[value='+target_id+']').length, 1
    #change one of the selects
    $('#fixtures').find('select:first').val(change_id).trigger('change')

    @clock.tick(101)
    #should now be more than one
    ok $('#fixtures').find('option[value='+target_id+']').length, 2

    # target_id is now available
    ok @never_drops.availableValues.find (nd) -> nd.id == target_id

  test "resetting NeverDrops with a chosen assignment renders a <span>", ->
    target_id = "1"
    @never_drops.reset [
      id: @never_drops.length
      label_id: 'new'
      chosen: 'Assignment 1'
      chosen_id: target_id
    ]

    @clock.tick(101)
    ok $('#fixtures').find('span').length, 1
    ok @never_drops.takenValues.find (nd) -> nd.id == target_id

  test "clicking the remove button, removes a model from the NeverDrop Collection", ->
    addNeverDrop.call @
    @clock.tick(101)
    initial_length = @never_drops.length
    $('#fixtures').find('.remove_never_drop').trigger('click')
    @clock.tick(101)
    equal initial_length - 1, @never_drops.length

  test "when there are no availableValues, the add assignment link is not rendered", ->
    addNeverDrop.call @
    addNeverDrop.call @
    addNeverDrop.call @

    @clock.tick(101)
    equal $('#fixtures').find('.add_never_drop').length, 0

  test "when there are no takenValues, the add assignment says 'add an assignment'", ->
    text = $('#fixtures').find('.add_never_drop').text()
    equal $.trim(text), 'Add an assignment'

  test "when there is at least one takenValue, the add assignment says 'add another assignment'", ->
    addNeverDrop.call @
    @clock.tick(101)
    text = $('#fixtures').find('.add_never_drop').text()
    equal $.trim(text), 'Add another assignment'
