import $ from 'jquery'
import DiscussionTopic from 'compiled/models/DiscussionTopic'
import Announcement from 'compiled/models/Announcement'
import DueDateList from 'compiled/models/DueDateList'
import EditView from 'compiled/views/DiscussionTopics/EditView'
import OverrideView from 'compiled/views/assignments/DueDateOverride'
import AssignmentGroupCollection from 'compiled/collections/AssignmentGroupCollection'
import SectionCollection from 'compiled/collections/SectionCollection'
import splitAssetString from 'compiled/str/splitAssetString'
import 'grading_standards'

const isAnnouncement = ENV.DISCUSSION_TOPIC.ATTRIBUTES != null ? ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement : undefined
const model = new (isAnnouncement ? Announcement : DiscussionTopic)(ENV.DISCUSSION_TOPIC.ATTRIBUTES, {parse: true})
model.urlRoot = ENV.DISCUSSION_TOPIC.URL_ROOT
const assignment = model.get('assignment')

const sectionList = new SectionCollection(ENV.SECTION_LIST)
const dueDateList = new DueDateList(assignment.get('assignment_overrides'), sectionList, assignment)

const [contextType] = splitAssetString(ENV.context_asset_string)
const view = new EditView({
  model,
  permissions: ENV.DISCUSSION_TOPIC.PERMISSIONS,
  contextType,
  views: {
    'js-assignment-overrides': new OverrideView({
      model: dueDateList,
      views: {}
    })
  }
})

if ((contextType === 'courses') && !isAnnouncement && ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_CREATE_ASSIGNMENT) {
  (view.assignmentGroupCollection = new AssignmentGroupCollection()).contextAssetString = ENV.context_asset_string
}

$(() => {
  view.render().$el.appendTo('#content')
  $('#discussion-title').focus()
})

export default view

