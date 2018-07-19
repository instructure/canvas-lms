/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that they will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import moment from 'moment-timezone';
import _ from 'lodash';
import parseLinkHeader from 'parse-link-header';
import { makeEndOfDayIfMidnight } from './dateUtils';

const getItemDetailsFromPlannable = (apiResponse, timeZone) => {
  let { plannable, plannable_type, planner_override } = apiResponse;
  const plannableId = plannable.id || plannable.page_id;
  const markedComplete = planner_override;

  const details = {
    course_id: plannable.course_id,
    title: plannable.name || plannable.title,
    // items are completed if the user marks it as complete or made a submission
    completed: (markedComplete != null)
      ? markedComplete.marked_complete
      : (apiResponse.submissions && apiResponse.submissions.submitted
    ),
    points: plannable.points_possible,
    html_url: apiResponse.html_url || plannable.html_url,
    overrideId: planner_override && planner_override.id,
    overrideAssignId: plannable.assignment_id,
    id: plannableId,
    uniqueId: `${plannable_type}-${plannableId}`,
    location: plannable.location_name || null,
    dateStyle: plannable.todo_date ? 'todo' : 'due'
  };
  details.originallyCompleted = details.completed;
  details.feedback = apiResponse.submissions ? apiResponse.submissions.feedback : undefined;

  if (plannable_type === 'discussion_topic' || plannable_type === 'announcement') {
    details.unread_count = plannable.unread_count;
  }

  if (plannable_type === 'planner_note') {
    details.details = plannable.details;
  }

  if (plannable_type === 'calendar_event') {
    details.allDay = plannable.all_day;
    if (!details.allDay && plannable.end_at && plannable.end_at !== apiResponse.plannable_date ) {
      details.endTime = moment(plannable.end_at);
    }
  }

  return details;
};

const TYPE_MAPPING = {
  quiz: "Quiz",
  discussion_topic: "Discussion",
  assignment: "Assignment",
  wiki_page: "Page",
  announcement: "Announcement",
  planner_note: "To Do",
  calendar_event: "Calendar Event",
};

const getItemType = (plannableType) => {
  return TYPE_MAPPING[plannableType];
};

const getApiItemType = (overrideType) => {
  return _.findKey(TYPE_MAPPING, _.partial(_.isEqual, overrideType));
};

export function findNextLink (response) {
  const linkHeader = response.headers.link;
  if (linkHeader == null) return null;

  const parsedLinks = parseLinkHeader(linkHeader);
  if (parsedLinks == null) return null;

  if (parsedLinks.next == null) return null;
  return parsedLinks.next.url;
}

/**
* Translates the API data to the format the planner expects
**/
export function transformApiToInternalItem (apiResponse, courses, groups, timeZone) {
  if (timeZone == null) throw new Error('timezone is required when interpreting api data in transformApiToInternalItem');

  const contextInfo = {};
  const context_type = apiResponse.context_type + '';
  const contextId = apiResponse[`${context_type.toLowerCase()}_id`];
  if (context_type === 'Course') {
    const course = courses.find(c => c.id === contextId);
    contextInfo.context = getCourseContext(course);
  } else if (context_type === 'Group') {
    const group = groups.find(g => g.id === contextId) || {name: "Unknown Group", color: "#666666", url: undefined};
    contextInfo.context = getGroupContext(apiResponse, group);
  }
  const details = getItemDetailsFromPlannable(apiResponse, timeZone);

  // Standardize 00:00:00 date to 11:59PM on the current day to make due date less confusing
  const plannableDate = makeEndOfDayIfMidnight(apiResponse.plannable_date, timeZone);

  if ((!contextInfo.context) && apiResponse.plannable_type === 'planner_note' && (details.course_id)) {
    const course = courses.find(c => c.id === details.course_id);
    contextInfo.context = getCourseContext(course);
  }

  if (details.unread_count) {
    apiResponse.submissions = apiResponse.submissions || {};
    apiResponse.submissions.unread_count = details.unread_count;
  }
  return {
    ...contextInfo,
    id: apiResponse.plannable_id,
    dateBucketMoment: moment.tz(plannableDate, timeZone).startOf('day'),
    type: getItemType(apiResponse.plannable_type),
    status: apiResponse.submissions,
    newActivity: apiResponse.new_activity,
    toggleAPIPending: false,
    date: plannableDate,
    ...details,
  };
}

/**
 * This takes the response from creating a new planner note aka To Do and puts it in the internal
 * format.
 */
export function transformPlannerNoteApiToInternalItem (plannerItemApiResponse, courses, timeZone) {
  const plannerNote = plannerItemApiResponse;
  let context = {};
  if (plannerNote.course_id) {
    const course = courses.find(c => c.id === plannerNote.course_id);
    context = getCourseContext(course);
  }
  return {
    id: plannerNote.id,
    uniqueId: `planner_note-${plannerNote.id}`,
    dateBucketMoment: moment.tz(plannerNote.todo_date, timeZone),
    type: 'To Do',
    status: false,
    course_id: plannerNote.course_id,
    context: context,
    title: plannerNote.title,
    date: moment.tz(plannerNote.todo_date, timeZone),
    details: plannerNote.details,
    completed: false
  };
}

/**
* Turn internal item format into data the API can consume for save actions
*/
export function transformInternalToApiItem (internalItem) {
  const contextInfo = {};
  if (internalItem.context) {
    contextInfo.context_type = internalItem.context.type || 'Course';
    contextInfo[`${contextInfo.context_type.toLowerCase()}_id`] = internalItem.context.id;
  }
  return {
    id: internalItem.id,
    ...contextInfo,
    todo_date: internalItem.date,
    title: internalItem.title,
    details: internalItem.details,
  };
}

export function transformInternalToApiOverride (internalItem, userId) {
  let type = getApiItemType(internalItem.type);
  let id = internalItem.id;
  if (internalItem.overrideAssignId) {
    type = 'assignment';
    id = internalItem.overrideAssignId;
  }
  return {
    id: internalItem.overrideId,
    plannable_id: id,
    plannable_type: type,
    user_id: userId,
    marked_complete: internalItem.completed
  };
}

export function transformApiToInternalGrade (apiResult) {
  // Grades are the same across all enrollments, just look at first one
  const courseId = apiResult.id;
  const hasGradingPeriods = apiResult.has_grading_periods;
  const enrollment = apiResult.enrollments[0];
  let score = enrollment.computed_current_score;
  let grade = enrollment.computed_current_grade;
  if (hasGradingPeriods) {
    score = enrollment.current_period_computed_current_score;
    grade = enrollment.current_period_computed_current_grade;
  }
  return {courseId, hasGradingPeriods, grade, score};
}

function getCourseContext(course) {
  // shouldn't happen, but if the course data is missing, skip it.
  // this has the effect of a planner note showing up as a vanilla todo not associated with a course
  if (!course) return undefined;
  return {
    type: 'Course',
    id: course.id,
    title: course.shortName,
    image_url: course.image,
    inform_students_of_overdue_submissions: course.informStudentsOfOverdueSubmissions,
    color: course.color,
    url: course.href
  };
}

function getGroupContext(apiResponse, group) {
  if (!group) return undefined;
  return {
    type: apiResponse.context_type,
    id: group.id,
    title: group.name,
    image_url: undefined,
    inform_students_of_overdue_submissions: false,  // group items don't have submissions
    color: group.color,
    url: group.url
  };
}
