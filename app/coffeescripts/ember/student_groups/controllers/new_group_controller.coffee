define [
  'ember'
  'ic-ajax'
], (Ember,ajax) ->

  NewGroupController = Ember.ObjectController.extend

    needs: [ 'student_groups', 'users' ]

    joinLevel: 'parent_context_auto_join'
    name: ''
    nameError: (->
      length = @get('name').length
      length == 0 or length > 255
    ).property('name.length')



    selectOptions: [
      {value: 'parent_context_auto_join', desc: 'Course members are free to join'},
      {value: 'invitation_only', desc: 'Membership by invitation only'},
    ]


    buildInvites: ->
      invites = {}
      @get('controllers.users').forEach (user) ->
        invites[user.get('id')] = if user.get('invite') then 1 else 0
      invites


    actions:
      createGroup: ->
        unless @nameError
          invites = @buildInvites()
          group = @store.createRecord 'group',
            name: @get('name')
            join_level: @get('joinLevel')
            course_id: ENV.course_id
            invites: invites

          group.save().then (group) =>
            @set('name','')
            json = group.toJSON()
            json.users = [ENV.current_user]
            @get('controllers.student_groups.groups').pushObject(json)
