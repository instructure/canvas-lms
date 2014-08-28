define [
  'i18n!student_groups'
  'ember'
], (I18n,Ember) ->

  StudentGroupsController = Ember.ObjectController.extend
    groups: []
    filterText: ""
    content: Ember.Object.create()
    searchPlaceholder: (->
      I18n.t('search_groups_placeholder',"Search Groups or People")
    ).property()
    searchAriaLabel: (->
      I18n.t('student_groups_filter_description',"As you type in this field, the list of groups will be automatically filtered to only include those whose names match your input.")
    ).property()

    usersPath: "/courses/#{ENV.course_id}/users"
    groupsUrl: "/api/v1/courses/#{ENV.course_id}/groups?include[]=users&include[]=group_category"
    sortedGroups: (->
      groups = @get('groups') || []
      text = @get('filterText').toLowerCase()
      groups = groups.filter (group) ->
        text.length == 0 or
          group.name.toLowerCase().indexOf(text) >= 0 or
          group.users.find (user) ->
            (user.display_name and user.display_name.toLowerCase().indexOf(text) >= 0) or
            (user.name and user.name.toLowerCase().indexOf(text) >= 0)

      groups.sortBy('group_category_id')
    ).property('groups.[]', 'filterText')

    removeFromCategory: (categoryId) ->
      @groupsForCategory(categoryId).forEach (group) ->
        user = group.users.findBy('id', ENV.current_user_id)
        if user
          group.users.removeObject(user)

    groupsForCategory: (categoryId) ->
      @get('groups').filterBy('group_category_id', categoryId)

    isMemberOfCategory: (categoryId) ->
      @groupsForCategory(categoryId).any (group) ->
        group.users.findBy('id', ENV.current_user_id)


