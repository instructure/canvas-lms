define [
  'compiled/collections/GroupUserCollection'
  'compiled/models/GroupUser'
], (GroupUserCollection, GroupUser) ->

  class GroupCategoryUserCollection extends GroupUserCollection

    model: GroupUser

    ##
    # The group category id the users belong to

    @optionProperty 'groupCategoryId'


    url: ->
      "/api/v1/group_categories/#{@groupCategoryId}/users"

