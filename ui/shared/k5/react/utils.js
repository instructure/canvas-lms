/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import moment from 'moment-timezone'
import PropTypes from 'prop-types'

import {asJson, defaultFetchOptions} from '@canvas/util/xhr'

import doFetchApi from '@canvas/do-fetch-api-effect'
import AssignmentGroupGradeCalculator from '@canvas/grading/AssignmentGroupGradeCalculator'
import {scoreToGrade} from '@instructure/grading-utils'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'

const I18n = useI18nScope('k5_utils')

export const countByCourseId = arr =>
  arr.reduce((acc, {course_id}) => {
    if (!acc[course_id]) {
      acc[course_id] = 0
    }
    acc[course_id]++
    return acc
  }, {})

export const transformGrades = courses =>
  courses.map(course => {
    const hasGradingPeriods = course.has_grading_periods
    const basicCourseInfo = {
      courseId: course.id,
      courseName: course.name,
      courseImage: course.image_download_url,
      courseColor: course.course_color,
      finalGradesHidden: course.hide_final_grades,
      gradingPeriods: hasGradingPeriods ? course.grading_periods : [],
      hasGradingPeriods,
      isHomeroom: course.homeroom_course,
      enrollments: course.enrollments,
      gradingScheme: course.grading_scheme,
      restrictQuantitativeData: course.restrict_quantitative_data,
    }
    return getCourseGrades(basicCourseInfo)
  })

export const getCourseGrades = (course, observedUserId) => {
  const hasGradingPeriods = course.hasGradingPeriods
  // Getting the observee enrollment if observedUserId is provided, as the observer enrollment
  // does not include the observee grades information, if the observedUserId is null,
  // just take the first enrollment as grades are the same across all non-observer enrollments
  const enrollment = observedUserId
    ? course.enrollments.find(e => e.user_id === observedUserId)
    : course.enrollments.filter(e => e.type !== 'observer')[0]
  // There could be the case in which the observed user enrollment is not active, if the student
  // has not accepted the course invitation for example, in this case we are going to get a
  // undefined enrollment
  const showTotalsForAllGradingPeriods = enrollment?.totals_for_all_grading_periods_option
  return {
    ...course,
    currentGradingPeriodId: enrollment?.current_grading_period_id,
    currentGradingPeriodTitle: enrollment?.current_grading_period_title,
    enrollmentType: enrollment?.type,
    score: hasGradingPeriods
      ? enrollment?.current_period_computed_current_score
      : enrollment?.computed_current_score,
    grade: hasGradingPeriods
      ? enrollment?.current_period_computed_current_grade
      : enrollment?.computed_current_grade,
    showTotalsForAllGradingPeriods,
    totalScoreForAllGradingPeriods: showTotalsForAllGradingPeriods
      ? enrollment?.computed_current_score
      : null,
    totalGradeForAllGradingPeriods: showTotalsForAllGradingPeriods
      ? enrollment?.computed_current_grade
      : null,
  }
}

export const fetchGradesForGradingPeriod = (gradingPeriodId, userId = 'self') =>
  asJson(
    window.fetch(
      `/api/v1/users/${userId}/enrollments?state[]=active&&type[]=StudentEnrollment&grading_period_id=${gradingPeriodId}`,
      defaultFetchOptions()
    )
  ).then(enrollments =>
    enrollments.map(({course_id, grades}) => ({
      courseId: course_id,
      score: grades && grades.current_score,
      grade: grades && grades.current_grade,
    }))
  )

export const fetchLatestAnnouncement = courseId =>
  asJson(
    window.fetch(
      `/api/v1/announcements?context_codes=course_${courseId}&active_only=true&per_page=1`,
      defaultFetchOptions()
    )
  ).then(data => {
    if (data?.length > 0) {
      return data[0]
    }
    return null
  })

/* Fetches instructors for a given course - in this case an instructor is a user with
   either a Teacher or TA enrollment. */
export const fetchCourseInstructors = courseId =>
  asJson(
    window.fetch(
      `/api/v1/courses/${courseId}/users?enrollment_type[]=teacher&enrollment_type[]=ta&include[]=avatar_url&include[]=bio&include[]=enrollments`,
      defaultFetchOptions()
    )
  )

export const fetchCourseApps = courseIds =>
  asJson(
    window.fetch(
      `/api/v1/external_tools/visible_course_nav_tools?${courseIds
        .map(id => `context_codes[]=course_${id}`)
        .join('&')}`,
      defaultFetchOptions()
    )
  )

export const fetchCourseTabs = courseId =>
  asJson(window.fetch(`/api/v1/courses/${courseId}/tabs`, defaultFetchOptions()))

export const readableRoleName = role => {
  const ROLES = {
    TeacherEnrollment: I18n.t('Teacher'),
    TaEnrollment: I18n.t('Teaching Assistant'),
    DesignerEnrollment: I18n.t('Designer'),
    StudentEnrollment: I18n.t('Student'),
    StudentViewEnrollment: I18n.t('Student'),
    ObserverEnrollment: I18n.t('Observer'),
  }
  // Custom roles return as named
  return ROLES[role] || role
}

export const sendMessage = (recipientId, message, subject) =>
  doFetchApi({
    path: '/api/v1/conversations',
    method: 'POST',
    body: {recipients: [recipientId], body: message, group_conversation: false, subject},
  })

const getSubmission = (assignment, observedUserId) =>
  observedUserId
    ? assignment.submission?.find(s => s.user_id === observedUserId)
    : assignment.submission

/* Takes raw response from assignment_groups API and returns an array of objects with each
   assignment group's id, name, and total score. If gradingPeriodId is passed, only return
   totals for assignment groups which have assignments in the provided grading period. */
export const getAssignmentGroupTotals = (
  data,
  gradingPeriodId,
  observedUserId,
  restrictQuantitativeData = false,
  gradingScheme = []
) => {
  if (gradingPeriodId) {
    data = data.filter(group =>
      group.assignments?.some(a => {
        const submission = getSubmission(a, observedUserId)
        return submission?.grading_period_id === gradingPeriodId
      })
    )
  }
  return data.map(group => {
    const assignments = group.assignments.map(a => ({
      ...a,
      submission: getSubmission(a, observedUserId),
    }))
    const groupScores = AssignmentGroupGradeCalculator.calculate(
      assignments.map(a => {
        return {
          points_possible: a.points_possible,
          assignment_id: a.id,
          assignment_group_id: a.assignment_group_id,
          ...a.submission,
        }
      }),
      {...group, assignments},
      false
    )

    let score
    if (groupScores.current.possible === 0) {
      score = I18n.t('n/a')
    } else {
      const tempScore = (groupScores.current.score / groupScores.current.possible) * 100
      score = restrictQuantitativeData
        ? scoreToGrade(tempScore, gradingScheme)
        : I18n.n(tempScore, {percentage: true, precision: 2})
    }

    return {
      id: group.id,
      name: group.name,
      score,
    }
  })
}
// Take an assignment and submission and output the expected value when Restrict_quantitative_data is enabled
const formatGradeToRQD = (assignment, submission) => {
  if (!ENV.RESTRICT_QUANTITATIVE_DATA) return
  let rqdFormattedGrade = ''
  // When RQD is on and score and points possible === 0, we have a special case where we want the grade to be displayed as "complete"
  if (submission?.score === 0 && assignment?.points_possible === 0) {
    rqdFormattedGrade = 'complete'
  } else {
    rqdFormattedGrade = GradeFormatHelper.formatGrade(submission?.grade, {
      gradingType: assignment.grading_type,
      pointsPossible: assignment.points_possible,
      score: submission?.score,
      restrict_quantitative_data: ENV.RESTRICT_QUANTITATIVE_DATA,
      grading_scheme: ENV.GRADING_SCHEME,
    })
  }

  return rqdFormattedGrade
}

/* Takes raw response from assignment_groups API and returns an array of assignments with
   grade information, sorted by due date. */
export const getAssignmentGrades = (data, observedUserId) => {
  return data
    .map(group =>
      group.assignments.map(a => {
        const submission = getSubmission(a, observedUserId)
        const rqd_grading_type = !['not_graded', 'pass_fail', 'gpa_scale'].includes(a.grading_type)
          ? 'letter_grade'
          : a.grading_type
        const rqdFormattedGrade = formatGradeToRQD(a, submission)
        return {
          id: a.id,
          assignmentName: a.name,
          url: a.html_url,
          dueDate: a.due_at,
          assignmentGroupName: group.name,
          assignmentGroupId: group.id,
          pointsPossible: a.points_possible,
          gradingType: ENV.RESTRICT_QUANTITATIVE_DATA ? rqd_grading_type : a.grading_type,
          restrictQuantitativeData: ENV.RESTRICT_QUANTITATIVE_DATA,
          score: submission?.score,
          grade: ENV.RESTRICT_QUANTITATIVE_DATA ? rqdFormattedGrade : submission?.grade,
          submissionDate: submission?.submitted_at,
          unread: submission?.read_state === 'unread',
          late: submission?.late,
          excused: submission?.excused,
          missing: submission?.missing,
          hasComments: !!submission?.submission_comments?.length,
        }
      })
    )
    .flat(1)
    .sort((a, b) => {
      if (a.dueDate == null) return 1
      if (b.dueDate == null) return -1
      return moment(a.dueDate).diff(moment(b.dueDate))
    })
}

/* Formats course total score and grade (if applicable) into string from enrollments API
   response */
export const getTotalGradeStringFromEnrollments = (
  enrollments,
  userId,
  observedUserId,
  restrictQuantitativeData = false,
  gradingScheme = []
) => {
  let grades
  if (observedUserId) {
    const enrollment = enrollments.find(
      ({associated_user_id}) => associated_user_id === observedUserId
    )
    grades = enrollment?.observed_user?.enrollments[0]?.grades
  } else {
    grades = enrollments.find(({user_id}) => user_id === userId)?.grades
  }
  if (grades?.current_score == null) {
    return I18n.t('n/a')
  }
  if (restrictQuantitativeData) {
    return scoreToGrade(grades.current_score, gradingScheme)
  }
  const score = I18n.n(grades.current_score, {percentage: true, precision: 2})
  return grades.current_grade == null
    ? score
    : I18n.t('%{score} (%{grade})', {score, grade: grades.current_grade})
}

/* Takes an array of courses and returns an array of ImportantInfoShapes */
export const fetchImportantInfos = courses =>
  Promise.all(
    courses.map(c =>
      doFetchApi({
        path: `/api/v1/courses/${c.id}`,
        params: {
          include: ['syllabus_body'],
        },
      }).then(data => ({
        courseId: c.id,
        courseName: c.shortName,
        canEdit: c.canManage,
        content: data.json.syllabus_body,
      }))
    )
  ).then(infos => infos.filter(info => info.content))

/* Turns raw announcement data from API into usable object */
export const parseAnnouncementDetails = (announcement, course) => {
  const retval = {
    courseId: course.id,
    courseName: course.shortName,
    courseUrl: course.href,
    canEdit: course.canManage,
    canReadAnnouncements: course.canReadAnnouncements,
    published: course.published,
  }
  if (announcement) {
    retval.announcement = transformAnnouncement(announcement)
    retval.canEdit = announcement.permissions.update
  }
  return retval
}

export const transformAnnouncement = announcement => {
  if (!announcement) return undefined

  let attachment
  if (announcement?.attachments[0]) {
    attachment = {
      display_name: announcement.attachments[0].display_name,
      url: announcement.attachments[0].url,
      filename: announcement.attachments[0].filename,
    }
  }

  return {
    id: announcement.id,
    title: announcement.title,
    message: announcement.message,
    url: announcement.html_url,
    postedDate: announcement.posted_at ? new Date(announcement.posted_at) : undefined,
    attachment,
  }
}

/* Helper function to take a list of announcements coming back from API
   and partition them into homeroom and non-homeroom groups */
export const groupAnnouncementsByHomeroom = (announcements = [], courses = []) =>
  courses.reduce(
    (acc, course) => {
      const announcement = announcements.find(a => a.context_code === `course_${course.id}`)
      const group = acc[course.isHomeroom]
      const parsedAnnouncement = course.isHomeroom
        ? parseAnnouncementDetails(announcement, course)
        : announcement
      if (parsedAnnouncement) acc[course.isHomeroom] = [...group, parsedAnnouncement]
      return acc
    },
    {true: [], false: []}
  )

export const saveElementaryDashboardPreference = disabled =>
  doFetchApi({
    path: '/api/v1/users/self/settings',
    method: 'PUT',
    body: {elementary_dashboard_disabled: disabled},
  })

export const ignoreTodo = ignoreUrl =>
  doFetchApi({
    path: ignoreUrl,
    method: 'DELETE',
  })

export const groupImportantDates = (assignments, events, timeZone) => {
  if (!assignments) return []
  const groups = assignments.concat(events).reduce((acc, item) => {
    const parsedItem = {
      id: item.id,
      title: item.title,
      context: item.context_name,
      color: item.context_color || DEFAULT_COURSE_COLOR,
      type: item.type === 'event' ? 'event' : item.assignment.submission_types[0],
      url: item.html_url,
    }
    const date = item.type === 'event' ? item.start_at : item.assignment.due_at
    const dateBucket = moment(date).tz(timeZone).startOf('day').toISOString()
    parsedItem.start = date
    acc.has(dateBucket) ? acc.get(dateBucket).push(parsedItem) : acc.set(dateBucket, [parsedItem])
    return acc
  }, new Map())
  const dates = []
  groups.forEach((items, date) => {
    dates.push({
      date,
      items: items.sort((a, b) => moment(a.start).diff(moment(b.start))),
    })
  })
  return dates.sort((a, b) => moment(a.date).diff(moment(b.date)))
}

export const saveSelectedContexts = selected_contexts =>
  doFetchApi({
    path: `/api/v1/calendar_events/save_selected_contexts`,
    method: 'POST',
    params: {selected_contexts},
  }).then(data => data.json)

export const dropCourse = url =>
  doFetchApi({
    path: url,
    method: 'POST',
  })

export const TAB_IDS = {
  HOME: 'tab-home',
  HOMEROOM: 'tab-homeroom',
  SCHEDULE: 'tab-schedule',
  GRADES: 'tab-grades',
  RESOURCES: 'tab-resources',
  GROUPS: 'tab-groups',
  MODULES: 'tab-modules',
  TODO: 'tab-todo',
}

export const FOCUS_TARGETS = {
  TODAY: 'today',
  MISSING_ITEMS: 'missing-items',
}

export const DEFAULT_COURSE_COLOR = '#394B58'

export const GradingPeriodShape = {
  id: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired,
  end_date: PropTypes.string,
  start_date: PropTypes.string,
  workflow_state: PropTypes.string,
}

export const MOBILE_NAV_BREAKPOINT_PX = 768
