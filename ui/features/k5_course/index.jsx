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
import React from 'react'
import ReactDOM from 'react-dom'
// eslint-disable-next-line import/no-named-as-default
import K5Course from './react/K5Course'
import {useK5Theme} from '@canvas/k5/react/k5-theme'
import ready from '@instructure/ready'

useK5Theme()

ready(() => {
  const courseContainer = document.getElementById('course-dashboard-container')
  if (courseContainer) {
    ReactDOM.render(
      <K5Course
        canManage={ENV.PERMISSIONS.manage}
        canManageGroups={ENV.PERMISSIONS.manage_groups}
        canReadAsAdmin={ENV.PERMISSIONS.read_as_admin}
        canReadAnnouncements={ENV.PERMISSIONS.read_announcements}
        currentUser={ENV.current_user}
        id={ENV.COURSE.id}
        bannerImageUrl={ENV.COURSE.banner_image_url}
        cardImageUrl={ENV.COURSE.image_url}
        color={ENV.COURSE.color}
        name={ENV.COURSE.name}
        plannerEnabled={ENV.STUDENT_PLANNER_ENABLED}
        timeZone={ENV.TIMEZONE}
        courseOverview={ENV.COURSE.course_overview}
        userIsStudent={ENV.COURSE.is_student_or_fake_student}
        hideFinalGrades={ENV.COURSE.hide_final_grades}
        showLearningMasteryGradebook={
          ENV.COURSE.student_outcome_gradebook_enabled && ENV.COURSE.is_student_or_fake_student
        }
        outcomeProficiency={ENV.COURSE.outcome_proficiency}
        showStudentView={ENV.COURSE.show_student_view}
        studentViewPath={ENV.COURSE.student_view_path}
        tabs={ENV.TABS}
        settingsPath={ENV.COURSE.settings_path}
        groupsPath={ENV.COURSE.groups_path}
        latestAnnouncement={ENV.COURSE.latest_announcement}
        pagesPath={ENV.COURSE.pages_url}
        hasWikiPages={ENV.COURSE.has_wiki_pages}
        hasSyllabusBody={ENV.COURSE.has_syllabus_body}
        observedUsersList={ENV.OBSERVED_USERS_LIST}
        selfEnrollment={ENV.COURSE.self_enrollment}
        tabContentOnly={ENV.TAB_CONTENT_ONLY}
        isMasterCourse={ENV.BLUEPRINT_COURSES_DATA?.isMasterCourse}
        showImmersiveReader={ENV.SHOW_IMMERSIVE_READER}
        gradingScheme={ENV.GRADING_SCHEME}
        restrictQuantitativeData={ENV.RESTRICT_QUANTITATIVE_DATA}
      />,
      courseContainer
    )
  }
})
