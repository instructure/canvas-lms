import $ from 'jquery'
import Group from 'compiled/models/Group'
import GroupCategory from 'compiled/models/GroupCategory'
import GroupEditView from 'compiled/views/groups/manage/GroupEditView'

const group = new Group(ENV.group)
const groupCategory = new GroupCategory(ENV.group_category)
const editView = new GroupEditView({model: group, groupCategory, nameOnly: true})
editView.setTrigger($('#edit_group'))
