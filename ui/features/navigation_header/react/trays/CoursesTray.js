/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import React from 'react'
import {bool, arrayOf, shape, string} from 'prop-types'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {List} from '@instructure/ui-list'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {Link} from '@instructure/ui-link'

const I18n = useI18nScope('CoursesTray')

const UNPUBLISHED = 'unpublished'

export default function CoursesTray({courses, hasLoaded, k5User}) {
  const showSplitList = window.ENV.current_user_roles?.includes('teacher')

  function renderSplitList() {
    const published = courses.filter(course => course.workflow_state !== UNPUBLISHED)
    const unpublished = courses.filter(course => course.workflow_state === UNPUBLISHED)
    return (
      <>
        {published.length > 0 && (
          <Heading level="h4" as="h3" key="published_courses">
            {k5User ? I18n.t('Published Subjects') : I18n.t('Published Courses')}
          </Heading>
        )}
        <List key="published" variant="unstyled" margin="small small" itemSpacing="small">
          {published.map(renderCourse)}
        </List>
        {unpublished.length > 0 && (
          <Heading level="h4" as="h3" key="unpublished_courses">
            {k5User ? I18n.t('Unpublished Subjects') : I18n.t('Unpublished Courses')}
          </Heading>
        )}
        <List key="unpublished" variant="unstyled" margin="small small" itemSpacing="small">
          {unpublished.map(renderCourse)}
        </List>
      </>
    )
  }

  function renderCourse(course) {
    return (
      <List.Item key={course.id}>
        <Link isWithinText={false} href={`/courses/${course.id}`}>
          {course.name}
        </Link>
        {course.enrollment_term_id > 1 && (
          <Text as="div" size="x-small" weight="light">
            {course.term.name}
          </Text>
        )}
      </List.Item>
    )
  }

  function renderContent() {
    const courseList = showSplitList ? (
      renderSplitList()
    ) : (
      <List variant="unstyled" margin="small 0" itemSpacing="small">
        {courses.map(renderCourse)}
      </List>
    )
    return (
      <>
        {courseList}
        <List variant="unstyled" margin="small 0" itemSpacing="small">
          <List.Item key="hr">
            <hr role="presentation" />
          </List.Item>
          <List.Item key="all">
            <Link isWithinText={false} href="/courses">
              {k5User ? I18n.t('All Subjects') : I18n.t('All Courses')}
            </Link>
          </List.Item>
        </List>
      </>
    )
  }

  function renderLoading() {
    return (
      <List variant="unstyled" margin="small 0" itemSpacing="small">
        <List.Item>
          <Spinner size="small" renderTitle={I18n.t('Loading')} />
        </List.Item>
      </List>
    )
  }

  return (
    <View as="div" padding="medium">
      <Heading level="h3" as="h2">
        {k5User ? I18n.t('Subjects') : I18n.t('Courses')}
      </Heading>
      <hr role="presentation" />
      {hasLoaded ? renderContent() : renderLoading()}
      <br />
      <Text as="div">
        {k5User
          ? I18n.t(
              'Welcome to your subjects! To customize the list of subjects,  click on the "All Subjects" link and star the subjects to display.'
            )
          : I18n.t(
              'Welcome to your courses! To customize the list of courses,  click on the "All Courses" link and star the courses to display.'
            )}
      </Text>
    </View>
  )
}

CoursesTray.propTypes = {
  courses: arrayOf(
    shape({
      id: string.isRequired,
      name: string.isRequired
    })
  ).isRequired,
  hasLoaded: bool.isRequired,
  k5User: bool.isRequired
}

CoursesTray.defaultProps = {
  courses: []
}
