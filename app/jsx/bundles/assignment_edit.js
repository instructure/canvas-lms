// manage groups is for the add_group_category dialog
import Assignment from 'compiled/models/Assignment'
import EditHeaderView from 'compiled/views/assignments/EditHeaderView'
import EditView from 'compiled/views/assignments/EditView'
import SectionCollection from 'compiled/collections/SectionCollection'
import DueDateList from 'compiled/models/DueDateList'
import DueDateOverride from 'compiled/views/assignments/DueDateOverride'
import AssignmentGroupSelector from 'compiled/views/assignments/AssignmentGroupSelector'
import GradingTypeSelector from 'compiled/views/assignments/GradingTypeSelector'
import GroupCategorySelector from 'compiled/views/assignments/GroupCategorySelector'
import PeerReviewsSelector from 'compiled/views/assignments/PeerReviewsSelector'
import 'grading_standards'
import LockManager from 'jsx/blueprint_courses/lockManager'

const lockManager = new LockManager()
lockManager.init({ itemType: 'assignment', page: 'edit' })

ENV.ASSIGNMENT.assignment_overrides = ENV.ASSIGNMENT_OVERRIDES

const userIsAdmin = ENV.current_user_roles.includes('admin')

const assignment = new Assignment(ENV.ASSIGNMENT)
assignment.urlRoot = ENV.URL_ROOT

const sectionList = new SectionCollection(ENV.SECTION_LIST)
const dueDateList = new DueDateList(assignment.get('assignment_overrides'), sectionList, assignment)

const assignmentGroupSelector = new AssignmentGroupSelector({
  parentModel: assignment,
  assignmentGroups: (typeof ENV !== 'undefined' && ENV !== null ? ENV.ASSIGNMENT_GROUPS : undefined) || []
})
const gradingTypeSelector = new GradingTypeSelector({
  parentModel: assignment
})
const groupCategorySelector = new GroupCategorySelector({
  parentModel: assignment,
  groupCategories: (typeof ENV !== 'undefined' && ENV !== null ? ENV.GROUP_CATEGORIES : undefined) || [],
  inClosedGradingPeriod: assignment.inClosedGradingPeriod()
})
const peerReviewsSelector = new PeerReviewsSelector({
  parentModel: assignment
})

const headerEl = ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED ? '#edit_assignment_header-cr' : '#edit_assignment_header'

const lockedItems =
  ((ENV.MASTER_COURSE_DATA && ENV.MASTER_COURSE_DATA.is_master_course_child_content && ENV.MASTER_COURSE_DATA.restricted_by_master_course)
  ? (ENV.MASTER_COURSE_DATA.master_course_restrictions || ENV.MASTER_COURSE_DATA.default_restrictions)
  : {}) || {};

const editView = new EditView({
  el: '#edit_assignment_form',
  model: assignment,
  assignmentGroupSelector,
  gradingTypeSelector,
  groupCategorySelector,
  peerReviewsSelector,
  views: {
    'js-assignment-overrides': new DueDateOverride({
      model: dueDateList,
      views: {},
      postToSIS: assignment.postToSIS(),
      dueDatesReadonly: !!lockedItems.due_dates,
      availabilityDatesReadonly: !!lockedItems.availability_dates
    })
  },
  lockedItems: assignment.id ? lockedItems : {} // if no id, creating a new assignment
})

const editHeaderView = new EditHeaderView({
  el: headerEl,
  model: assignment,
  userIsAdmin,
  views: {
    edit_assignment_form: editView
  }
})

editHeaderView.render()
