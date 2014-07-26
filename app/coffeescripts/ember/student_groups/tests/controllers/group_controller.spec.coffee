define [
  '../start_app'
  'ember'
  'ic-ajax'
  '../../controllers/group_controller'
  '../../controllers/student_groups_controller'
  'helpers/fakeENV'
], (startApp, Ember, ajax, GroupController, StudentGroupsController, fakeENV) ->

  App = null

  {run} = Ember


  module 'group_controller',
    setup: ->
      fakeENV.setup()
      App = startApp()
      run => @sgc = StudentGroupsController.create()
      run => @gc = GroupController.create(parentController: @sgc, showBody: false)
      run =>
        @group =
           id: 1
           name: "one"
           group_category_id: 2
           users: [{id: 1, name: "steve"}, {id: 2, name: "cliff"}, {id: 3, name: "walt"}, {id: 4, name: "pinkman"}]

        @gc.set('content', @group)
        @gc.set('group', @group)
    teardown: ->
      run =>
        fakeENV.teardown()
        @gc.destroy()
        @sgc.destroy()
      Ember.run App, 'destroy'


  test 'should show body while searching', ->
    equal @gc.get('showBody'), false
    @sgc.set('filterText', "abc")
    equal @gc.get('showBody'), true

  test 'member count should sum the users', ->
    equal @gc.get('memberCount'), @group.users.length


  test 'toggleBody should change show body if the group has members', ->
    @gc.send('toggleBody')
    equal @gc.get('showBody'), true

  test 'leave should remove the current user from the group', ->
    ENV.current_user_id = 1
    ajax.defineFixture '/api/v1/groups/1/memberships/self',
      response:
        id: "1"
      textStatus: 'success'
      jqXHR: {}
    
    @gc.send('leave', @group)

    equal @gc.get('users').length, 3
