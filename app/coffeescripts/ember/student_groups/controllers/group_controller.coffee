define [
  'i18n!student_groups'
  'ember'
  'ic-ajax'
  'jquery'
  'compiled/jquery.rails_flash_notifications'
], (I18n, Ember, ajax, $) ->

  GroupController = Ember.ObjectController.extend

    currentUser: {}
    groupUrl: (->
      "/groups/#{@get('id')}"
    ).property('id')

    usersUrl: (->
      "/api/v1/groups/#{@get('id')}/memberships"
    ).property('id')

    i18nStudentsCount: (->
      I18n.t('students_count', 'student', count: @get('memberCount'))
    ).property('memberCount')

    showWhileSearching: (->
      if @get('parentController.filterText').length > 0
        @set('showBody', true)
      else
        @set('showBody', false)
    ).observes('parentController.filterText').on('init')

    memberCount: Ember.computed.alias('users.length')

    isExpanded: (->
      '' + this.get('showBody');
    ).property('showBody')

    groupName: ( ->
      I18n.t('group_name', "%{group_name} in %{group_category}", {group_name: @get('name'), group_category: @get('group_category.name')});
    ).property('name', 'group_category.name')

    sgid: (->
      "student-group-#{@.get('id')}"
    ).property('id')

    hasMultipleMembers: Ember.computed.not('memberCount',1)
    actions:
      visitGroup: ->
        if @get('isMember')
          window.location.href = @get('groupUrl')
      toggleBody: ->
        if @.get('memberCount') > 0
          focusedElement = "##{@get('sgid')} ul.student-group-list"
          @toggleProperty('showBody')
          if (!this.get('showBody'))
            focusedElement = "##{@get('sgid')} .student-group-title"
          Ember.run.scheduleOnce 'afterRender', ->
            Ember.$(focusedElement).focus()  
        else
          @set('showBody', false)
      join: (group) ->
        membership = @store.createRecord('membership', {
          user_id: ENV.current_user_id
          group_id: @get('id')
        })
        controller = this
        membership.save().then (membership)->
          unless controller.get('isStudentGroup')
            controller.parentController.removeFromCategory(controller.get('group_category_id'))
          controller.get('users').addObject(ENV.current_user)
          $.flashMessage I18n.t('group_join', "Joined Group %{group_name}", group_name: group.name)
      leave: (group) ->
        controller = this
        Ember.run =>
          ajax.request("#{@get('usersUrl')}/self",{type: "DELETE"}).then (response) ->
            user = controller.get('users').findBy('id', ENV.current_user_id)
            controller.get('users').removeObject(user)
            $.flashMessage I18n.t('group_leave', "Left Group %{group_name}", group_name: group.name)
            if controller.get('memberCount') == 0
              controller.set('showBody', false)

    isMember: (->
      @get('model').users.findBy('id', ENV.current_user_id)?
    ).property('users.@each.id')

    canSignup: (->
      @get('group_category.self_signup') == "enabled" or @get('join_level') == "parent_context_auto_join"
    ).property('group_category.self_signup', 'join_level')


    isFull: (->
      @get('max_membership')? and @get('memberCount') >= @get('max_membership')
    ).property('memberCount')

    isMemberOfCategory: (->
      @parentController.isMemberOfCategory(@get('group_category_id'))
    ).property('users.@each.id')

    isStudentGroup: (->
      @get('group_category.role') == 'student_organized'
    ).property('group_category.role')

    shouldSwitch: (->
      @get('isMemberOfCategory') && !@get('isStudentGroup')
    ).property('isMemberOfCategory', 'isStudentGroup')
