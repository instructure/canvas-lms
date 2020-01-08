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

import I18n from 'i18n!CoursesTray'
import React from 'react'
import {bool, arrayOf, shape, string} from 'prop-types'
import {View} from '@instructure/ui-layout'
import {Heading, List, Spinner, Text} from '@instructure/ui-elements'
import {Link} from '@instructure/ui-link'

export default function CoursesTray({courses, hasLoaded}) {
  return (
    <View as="div" padding="medium">
      <Heading level="h3" as="h2">
        {I18n.t('Courses')}
      </Heading>
      <hr role="presentation" />
      <List variant="unstyled" margin="small 0" itemSpacing="small">
        {hasLoaded ? (
          courses
            .map(course => (
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
            ))
            .concat([
              <List.Item key="hr">
                <hr role="presentation" />
              </List.Item>,
              <List.Item key="all">
                <Link isWithinText={false} href="/courses">
                  {I18n.t('All Courses')}
                </Link>
              </List.Item>
            ])
        ) : (
          <List.Item>
            <Spinner size="small" renderTitle={I18n.t('Loading')} />
          </List.Item>
        )}
      </List>
      <br />
      <Text as="div">
        {I18n.t(
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
  hasLoaded: bool.isRequired
}

CoursesTray.defaultProps = {
  courses: []
}
