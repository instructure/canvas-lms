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

const getItemDetailsFromPlannable = (apiResponse, timeZone) => {
  let { plannable, plannable_type, planner_override } = apiResponse;
  const plannableId = plannable.id || plannable.page_id;
  const markedComplete = planner_override;

  const details = {
    course_id: plannable.course_id,
    title: plannable.name || plannable.title,
    date: plannable.due_at || plannable.todo_date,
    completed: (markedComplete != null) ? markedComplete.marked_complete : (apiResponse.submissions
      && (apiResponse.submissions.submitted
      || apiResponse.submissions.excused
      || apiResponse.submissions.graded)
    ),
    points: plannable.points_possible,
    html_url: plannable.html_url,
    overrideId: planner_override && planner_override.id,
    overrideAssignId: plannable.assignment_id,
    id: plannableId,
    uniqueId: `${plannable_type}-${plannableId}`,
  };
  if (plannable_type === 'discussion_topic') {
    if (plannable.assignment) {
      details.date = plannable.assignment.due_at;
    }
  }
  if (plannable_type === 'discussion_topic' || plannable_type === 'announcement') {
    details.unread_count = plannable.unread_count;
  }
  if (plannable_type === 'announcement' && !details.date) {
    details.date = plannable.delayed_post_at || plannable.posted_at;
  }

  if (plannable_type === 'planner_note') {
    details.details = plannable.details;
  }
  // Standardize 00:00:00 date to 11:59PM on the current day to make due date less confusing
  let currentDay = moment(details.date);
  if (isMidnight(currentDay, timeZone)) {
    details.date = currentDay.endOf('day').toISOString();
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
};

const getItemType = (plannableType) => {
  return TYPE_MAPPING[plannableType];
};

const getApiItemType = (overrideType) => {
  return _.findKey(TYPE_MAPPING, _.partial(_.isEqual, overrideType));
};

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
    contextInfo.context = getCourseContext(apiResponse, course);
  } else if (context_type === 'Group') {
    const group = groups.find(g => g.id === contextId) || {name: "Unknown Group", color: "#666666", url: undefined};
    contextInfo.context = getGroupContext(apiResponse, group);
  }
  const details = getItemDetailsFromPlannable(apiResponse, timeZone);

  if ((!contextInfo.context) && apiResponse.plannable_type === 'planner_note' && (details.course_id)) {
    const course = courses.find(c => c.id === details.course_id);
    // shouldn't happen, but if the course data is missing, skip it.
    // this has the effect of the planner note showing up as a vanilla todo not associated with a course
    if (course) {
      contextInfo.context = {
        type: 'Planner Note',
        id: details.course_id,
        title: course.shortName,
        image_url: course.image,
        inform_students_of_overdue_submissions: course.informStudentsOfOverdueSubmissions,
        color: course.color,
        url: course.href
      };
    }
  }

  if (details.unread_count) {
    apiResponse.submissions = apiResponse.submissions || {};
    apiResponse.submissions.unread_count = details.unread_count;
  }
  return {
    ...contextInfo,
    id: apiResponse.plannable_id,
    dateBucketMoment: moment.tz(details.date, timeZone).startOf('day'),
    type: getItemType(apiResponse.plannable_type),
    status: apiResponse.submissions,
    newActivity: apiResponse.new_activity,
    toggleAPIPending: false,
    ...details
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
    if (course) {
      context = {
        type: 'Planner Note',
        id: plannerNote.course_id,
        title: course.shortName,
        image_url: course.image,
        inform_students_of_overdue_submissions: course.informStudentsOfOverdueSubmissions,
        color: course.color,
        url: course.href
      };
    }
  }
  return {
    id: plannerNote.id,
    uniqueId: `planner_note-${plannerNote.id}`,
    dateBucketMoment: moment.tz(plannerNote.todo_date, timeZone).startOf('day'),
    type: 'To Do',
    status: false,
    course_id: plannerNote.course_id,
    context: context,
    title: plannerNote.title,
    date: plannerNote.todo_date,
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

function getCourseContext(apiResponse, course) {
  if (!course) return undefined;
  return {
    type: apiResponse.context_type,
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

function isMidnight(currentDay, timeZone) {
  // in languages like Arabic, moment.format returns strings in the native characters
  // so this doesn't work
  //currentDay.tz(timeZone).format('HH:mm:ss') === '00:00:00'
  return currentDay.hours() === currentDay.minutes() === currentDay.seconds() === 0;
}
