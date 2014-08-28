define [
  '../start_app'
  'ember'
  'ic-ajax'
  '../../controllers/student_groups_controller'
  'helpers/fakeENV'
], (startApp, Ember, ajax, StudentGroupsController, fakeENV) ->

  App = null

  {run} = Ember


  module 'student_groups_controller',
    setup: ->
      App = startApp()
      fakeENV.setup()
      run => @sgc = StudentGroupsController.create()
      groups = null
      run =>
        groups = [
           id: 1
           name: "one"
           group_category_id: 2
           users: [{id: 1, name: "steve"}, {id: 2, name: "cliff"}, {id: 3, name: "walt"}, {id: 4, name: "pinkman"}]
         ,
           id: 2
           name: "two"
           group_category_id: 1
           users: [{id: 1, name: "steve"}, {id: 2, name: "cliff"}, {id: 3, name: "walt"}]
         ]
        @sgc.set('groups', groups)
    teardown: ->
      run =>
        @sgc.destroy()
        fakeENV.teardown()
      Ember.run App, 'destroy'


  test 'Groups are sorted group category id', ->
    sorted = @sgc.get('sortedGroups')
    equal sorted[0].name, "two"

  test 'filterText will filter groups by user name', ->
    @sgc.set('filterText', "pink")
    sorted = @sgc.get('sortedGroups')
    equal sorted.length, 1
    equal sorted[0].name, "one"


  test 'is member of category should be true if the current user is', ->
    ENV.current_user_id = 1
    equal @sgc.isMemberOfCategory(1)?, true

  test 'is member of category should be false if the current user is not', ->
    ENV.current_user_id = 4
    equal @sgc.isMemberOfCategory(1)?, false

  test 'remove from category removes the user from any group in the category', ->
    ENV.current_user_id = 2
    equal @sgc.isMemberOfCategory(1)?, true
    @sgc.removeFromCategory(1)
    equal @sgc.isMemberOfCategory(1)?, false




