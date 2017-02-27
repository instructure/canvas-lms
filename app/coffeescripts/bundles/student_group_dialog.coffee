require [
  'jquery'
  'compiled/models/Group'
  'compiled/models/GroupCategory'
  'compiled/views/groups/manage/GroupEditView'
], ($, Group, GroupCategory, GroupEditView) ->

  group = new Group(ENV.group)
  groupCategory = new GroupCategory(ENV.group_category)
  editView = new GroupEditView({model: group, groupCategory: groupCategory, nameOnly: true})
  editView.setTrigger $('#edit_group')
