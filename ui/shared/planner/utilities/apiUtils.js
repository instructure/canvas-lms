/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import moment from 'moment-timezone'
import _ from 'lodash'
import parseLinkHeader from '@canvas/parse-link-header'

const getItemDetailsFromPlannable = apiResponse => {
  const {plannable, plannable_type, planner_override} = apiResponse
  const plannableId = plannable.id || plannable.page_id

  const details = {
    course_id: plannable.course_id || apiResponse.course_id,
    title: plannable.title,
    completed: isComplete(apiResponse),
    points: plannable.points_possible,
    html_url: apiResponse.html_url || plannable.html_url,
    overrideId: planner_override && planner_override.id,
    overrideAssignId: plannable.assignment_id,
    id: plannableId,
    uniqueId: `${plannable_type}-${plannableId}`,
    location: plannable.location_name || null,
    address: plannable.location_address || null,
    dateStyle: plannable.todo_date ? 'todo' : 'due',
  }
  details.originallyCompleted = details.completed
  details.feedback = apiResponse.submissions ? apiResponse.submissions.feedback : undefined

  if (plannable_type === 'discussion_topic' || plannable_type === 'announcement') {
    details.unread_count = plannable.unread_count
  }

  if (plannable_type === 'planner_note') {
    details.details = plannable.details
  }

  if (plannable_type === 'calendar_event') {
    details.details = plannable.description
    details.allDay = plannable.all_day
    if (!details.allDay && plannable.end_at && plannable.end_at !== apiResponse.plannable_date) {
      details.endTime = moment(plannable.end_at)
    }
    details.onlineMeetingURL = plannable.online_meeting_url
  }

  if (plannable.restrict_quantitative_data) {
    details.restrict_quantitative_data = plannable.restrict_quantitative_data
  }

  return details
}

const TYPE_MAPPING = {
  quiz: 'Quiz',
  discussion_topic: 'Discussion',
  assignment: 'Assignment',
  wiki_page: 'Page',
  announcement: 'Announcement',
  planner_note: 'To Do',
  calendar_event: 'Calendar Event',
  assessment_request: 'Peer Review',
}

const getItemType = plannableType => {
  return TYPE_MAPPING[plannableType]
}

const getApiItemType = overrideType => {
  return _.findKey(TYPE_MAPPING, _.partial(_.isEqual, overrideType))
}

export function findNextLink(response) {
  const linkHeader = getResponseHeader(response, 'link')
  if (linkHeader == null) return null

  const parsedLinks = parseLinkHeader(linkHeader)
  if (parsedLinks == null) return null

  if (parsedLinks.next == null) return null
  return parsedLinks.next.url
}

/**
 * Translates the API data to the format the planner expects
 * */
export function transformApiToInternalItem(apiResponse, courses, groups, timeZone) {
  if (timeZone == null)
    throw new Error('timezone is required when interpreting api data in transformApiToInternalItem')

  const contextInfo = {}
  const context_type = apiResponse.context_type + ''
  const contextId = apiResponse[`${context_type.toLowerCase()}_id`]
  if (context_type === 'Course') {
    const course = courses.find(c => c.id === contextId)
    contextInfo.context = getCourseContext(course)
  } else if (context_type === 'Group') {
    const group = groups.find(g => g.id === contextId) || {
      name: 'Unknown Group',
      color: '#666666',
      url: undefined,
    }
    contextInfo.context = getGroupContext(apiResponse, group)
  } else if (context_type === 'Account') {
    contextInfo.context = getAccountContext(apiResponse)
  }
  const details = getItemDetailsFromPlannable(apiResponse, timeZone)

  const plannableDate = moment.tz(apiResponse.plannable_date, timeZone)

  if (!contextInfo.context && apiResponse.plannable_type === 'planner_note' && details.course_id) {
    const course = courses.find(c => c.id === details.course_id)
    contextInfo.context = getCourseContext(course)
  }

  if (details.unread_count) {
    apiResponse.submissions = apiResponse.submissions || {}
    apiResponse.submissions.unread_count = details.unread_count
  }
  return {
    ...contextInfo,
    id: apiResponse.plannable_id,
    dateBucketMoment: moment.tz(plannableDate, timeZone).startOf('day'),
    type: getItemType(apiResponse.plannable_type),
    status: apiResponse.submissions,
    newActivity:
      apiResponse.new_activity &&
      (apiResponse.plannable_type !== 'discussion_topic' || details.unread_count > 0),
    toggleAPIPending: false,
    date: plannableDate,
    ...details,
  }
}

/**
 * This takes the response from creating a new planner note aka To Do and puts it in the internal
 * format.
 */
export function transformPlannerNoteApiToInternalItem(plannerItemApiResponse, courses, timeZone) {
  const plannerNote = plannerItemApiResponse
  let context = {}
  if (plannerNote.course_id) {
    const course = courses.find(c => c.id === plannerNote.course_id)
    context = getCourseContext(course)
  }
  return {
    id: plannerNote.id,
    uniqueId: `planner_note-${plannerNote.id}`,
    dateBucketMoment: moment.tz(plannerNote.todo_date, timeZone),
    type: 'To Do',
    status: false,
    course_id: plannerNote.course_id,
    context,
    title: plannerNote.title,
    date: moment.tz(plannerNote.todo_date, timeZone),
    details: plannerNote.details,
    completed: false,
  }
}

/**
 * Turn internal item format into data the API can consume for save actions
 */
export function transformInternalToApiItem(internalItem) {
  const contextInfo = {}
  if (internalItem.context) {
    contextInfo.context_type = internalItem.context.type || 'Course'
    contextInfo[`${contextInfo.context_type.toLowerCase()}_id`] = internalItem.context.id
  }
  return {
    id: internalItem.id,
    ...contextInfo,
    todo_date: internalItem.date,
    title: internalItem.title,
    details: internalItem.details,
  }
}

export function transformInternalToApiOverride(internalItem, userId) {
  let type = getApiItemType(internalItem.type)
  let id = internalItem.id
  if (internalItem.overrideAssignId) {
    type = 'assignment'
    id = internalItem.overrideAssignId
  }
  return {
    id: internalItem.overrideId,
    plannable_id: id,
    plannable_type: type,
    user_id: userId,
    marked_complete: internalItem.completed,
  }
}

export function transformApiToInternalGrade(apiResult) {
  // Grades are the same across all enrollments, just look at first one
  const courseId = apiResult.id
  const hasGradingPeriods = apiResult.has_grading_periods
  const restrictQuantitativeData = apiResult.restrict_quantitative_data
  const enrollment = apiResult.enrollments[0]
  let score = enrollment.computed_current_score
  let grade = enrollment.computed_current_grade
  const scoreThasWasCoercedToLetterGrade = enrollment.computed_current_letter_grade
  if (hasGradingPeriods) {
    score = enrollment.current_period_computed_current_score
    grade = enrollment.current_period_computed_current_grade
  }
  return {
    courseId,
    hasGradingPeriods,
    grade,
    score,
    restrictQuantitativeData,
    scoreThasWasCoercedToLetterGrade,
  }
}

export function getContextCodesFromState({courses = []}) {
  return courses?.length
    ? courses
        .map(({id}) => `course_${id}`)
        .sort((a, b) => a.localeCompare(b, 'en', {numeric: true}))
    : undefined
}

function getCourseContext(course) {
  // shouldn't happen, but if the course data is missing, skip it.
  // this has the effect of a planner note showing up as a vanilla todo not associated with a course
  if (!course) return undefined
  return {
    type: 'Course',
    id: course.id,
    title: course.shortName || course.name,
    image_url: course.image || course.image_url,
    color: course.color,
    url: course.href,
  }
}

function getGroupContext(apiResponse, group) {
  if (!group) return undefined
  return {
    type: apiResponse.context_type,
    id: group.id,
    title: group.name,
    image_url: undefined,
    color: group.color,
    url: group.url,
  }
}

function getAccountContext(apiResponse) {
  if (apiResponse?.context_type !== 'Account') return undefined
  const type = apiResponse.context_type
  const id = apiResponse.account_id
  return {
    type,
    id,
    title: apiResponse.context_name,
    image_url: undefined,
    color: ENV.PREFERENCES?.custom_colors[`${type.toLowerCase()}_${id}`],
    url: apiResponse.url,
  }
}

// is the item complete?
// either marked as complete by the user, or because the work was completed.
function isComplete(apiResponse) {
  const {plannable, plannable_type, planner_override, submissions} = apiResponse

  let complete = false
  if (planner_override) {
    complete = planner_override.marked_complete
  } else if (plannable_type === 'assessment_request') {
    complete = plannable.workflow_state === 'completed'
  } else if (submissions) {
    complete = submissions.submitted && !submissions.redo_request
  }
  return complete
}

export function observedUserId(state) {
  if (state.selectedObservee && state.selectedObservee !== state.currentUser.id) {
    return state.selectedObservee
  }
  return null
}

export function observedUserContextCodes(state) {
  if (state.selectedObservee && state.selectedObservee !== state.currentUser.id) {
    return getContextCodesFromState(state)
  }
  return undefined
}

export function getResponseHeader(response, name) {
  return response.headers.get?.(name) || response.headers[name]
}

// take a base url and object of params and generate
// a url with query_string parameters for the params
//
// To build a URL that matches the one build for the prefetch
// params are in the following order
const paramOrder = [
  'start_date',
  'end_date',
  'include',
  'filter',
  'order',
  'per_page',
  'observed_user_id',
  'context_codes',
  'course_ids',
]
export function buildURL(url, params = {}) {
  const result = new URL(url, 'http://localhost/')
  const params2 = {...params}

  // first the order-dependent params
  paramOrder.forEach(key => {
    if (key in params2) {
      serializeParamIntoURL(key, params2[key], result)
      delete params2[key]
    }
  })
  // then any left over
  Object.keys(params2).forEach(key => {
    serializeParamIntoURL(key, params2[key], result)
  })
  return `${result.pathname}${result.search}`
}

function serializeParamIntoURL(key, val, url) {
  if (val === null || typeof val === 'undefined') return
  if (Array.isArray(val)) {
    // assumes values are strings
    val
      .sort((a, b) => a.localeCompare(b, 'en', {numeric: true}))
      .forEach(arrayVal => {
        if (arrayVal === null || typeof arrayVal === 'undefined') return
        url.searchParams.append(`${key}[]`, arrayVal)
      })
  } else {
    url.searchParams.append(key, val)
  }
}
