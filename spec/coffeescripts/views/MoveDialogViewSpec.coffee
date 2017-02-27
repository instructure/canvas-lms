define [
  'underscore'
  'jquery'
  'Backbone'
  'compiled/views/MoveDialogView'
  'helpers/jquery.simulate'
], (_, $, Backbone, MoveDialogView) ->

  server = null

  class AssignmentStub extends Backbone.Model
    name: -> @get('name')
    toView: =>
      name: @get('name')
      id: @id

  class Assignments extends Backbone.Collection
    model: AssignmentStub
    comparator: 'position'

  class AssignmentGroups extends Backbone.Collection
    comparator: 'position'

  genSetup = ->
    @assignments_1 = new Assignments((id: "#{i}", name: "Assignment #{i}") for i in [1..3])
    @assignments_2 = new Assignments((id: "#{i}", name: "Assignment #{i}") for i in [5..10])
    @assignmentGroups = new AssignmentGroups [
      new Backbone.Model assignments: @assignments_1, id: "1"
      new Backbone.Model assignments: @assignments_2, id: "2"
    ]

  createDialog = (hasParentCollection, saveURL) ->
    @model = @assignments_1.at(0)
    @moveDialog = new MoveDialogView
      model: @model
      nested: true if hasParentCollection
      parentCollection: @assignmentGroups if hasParentCollection
      childKey: 'assignments'
      parentKey: 'assignment_group_id'
      saveURL: saveURL

  QUnit.module 'MoveDialogView',
    setup: ->
      genSetup.call @
      @update_spy = @spy MoveDialogView.prototype, 'updateListView'
      createDialog.call @, true
    teardown: ->
      @moveDialog.remove()

  test 'child views don\'t exist on init', ->
    ok !@moveDialog.listView and !@moveDialog.parentListView

  test '#getFormData returns ids', ->
    @moveDialog.open()
    expected = @assignments_1.pluck('id')
    _.each @moveDialog.getFormData(), (val, ind) ->
      equal val, expected[ind]

  test '#getFormData adds model id at end if value is "last"', ->
    @moveDialog.open()
    expected = _.pluck @assignments_1.slice(1), 'id'
    expected.push @assignments_1.at(0).id

    lastSelect = @moveDialog.$('select').last()
    lastSelect.find('option').last().prop('selected', true)
    lastSelect.trigger('change')

    _.each @moveDialog.getFormData(), (val, ind) ->
      equal val, expected[ind]

  test 'two selects are attached with #attachChildViews', ->
    @moveDialog.open()
    equal @moveDialog.$('select').length, 2

  test 'changing the value of the parentList select sets the collection on the listView', ->
    @moveDialog.open()
    initialHTML = @moveDialog.$('select').last().html()

    firstSelect = @moveDialog.$('select').first()
    firstSelect.find('option').last().prop('selected', true)
    firstSelect.trigger('change')

    ok @update_spy.calledOnce
    notEqual @moveDialog.$('select').last().html(), initialHTML

    options = @moveDialog.$('select').last().find('option')
    # each option value corresponds to an item id
    _.each options, (ele, ind) =>
      {value} = ele
      if value != "last"
        equal value, @assignments_2.at(ind).id


  QUnit.module 'MoveDialogView without a parentCollection',
    setup: ->
      genSetup.call @
      createDialog.call @, false
    teardown: ->
      @moveDialog.remove()

  test 'only one select is attached with #attachChildViews', ->
    @moveDialog.open()
    equal @moveDialog.$('select').length, 1


  QUnit.module 'MoveDialogView save and save success',
    setup: ->
      genSetup.call @
      server = sinon.fakeServer.create()
      @sort_spy = @spy Assignments.prototype, 'sort'
      @reset_spy = @spy Assignments.prototype, 'reset'

    teardown: ->
      _.each server.requests, -> server.respond()
      server.restore()
      @moveDialog.remove()

  test '@saveURL as a string', ->
    saveURL = "/test"
    createDialog.call @, true, saveURL
    @moveDialog.open()
    @moveDialog.submit()

    equal server.requests[0].url, saveURL

  test '@saveURL as a function', ->
    # give it something that will be
    # defined on the @moveDialog
    saveURL = ->
      "/test/#{@childKey}"
    createDialog.call @, true, saveURL
    @moveDialog.open()
    @moveDialog.submit()


    equal server.requests[0].url, saveURL.call @moveDialog

  test 'collection #sort and #reset are called on success', ->
    saveURL = "/test"
    createDialog.call @, true, saveURL
    @moveDialog.open()
    @moveDialog.submit()
    server.respond 'POST', '/test', [
      200
      'Content-Type': 'application/json'
      JSON.stringify [2,1,3]
    ]

    ok @sort_spy.called
    ok @reset_spy.called

  test 'parentKey value on the model is updated on save success when the model moves collections', ->
    saveURL = "/test"
    createDialog.call @, true, saveURL
    # we don't initially have a parentKey relationship on the stub model
    ok !@model.has('assignment_group_id')
    @moveDialog.open()

    # need to change the parentCollection selector
    firstSelect = @moveDialog.$('select').first()
    firstSelect.find('option').last().prop('selected', true)
    firstSelect.trigger('change')

    @moveDialog.submit()
    server.respond 'POST', '/test', [
      200
      'Content-Type': 'application/json'
      JSON.stringify [2,1,3]
    ]

    ok @model.has('assignment_group_id')

  test 'parentKey value on the model is updated on save success and is a string', ->
    saveURL = "/test"
    createDialog.call @, true, saveURL
    # we don't initially have a parentKey relationship on the stub model
    ok !@model.has('assignment_group_id')
    @moveDialog.open()

    # need to change the parentCollection selector
    firstSelect = @moveDialog.$('select').first()
    firstSelect.find('option').last().prop('selected', true)
    firstSelect.trigger('change')

    @moveDialog.submit()
    server.respond 'POST', '/test', [
      200
      'Content-Type': 'application/json'
      JSON.stringify [2,1,3]
    ]

    ok @model.has('assignment_group_id')
    ok typeof @model.get('assignment_group_id') == 'string'
