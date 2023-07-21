/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'
import {Alert} from '@instructure/ui-alerts'
import {Link} from '@instructure/ui-link'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('shared_due_dates_react_due_dates_in_course_pacing')

const CoursePacingNotice = props => {
  return (
    <View as="div" margin="medium 0 0 0" data-testid="CoursePacingNotice">
      <Alert variant="info">
        <View as="div" margin="0 0 small 0">
          {I18n.t('This course is using Course Pacing. Go to Course Pacing to manage due dates.')}
        </View>
        {props.courseId && (
          <Link href={`/courses/${props.courseId}/course_pacing`}>{I18n.t('Course Pacing')}</Link>
        )}
      </Alert>
    </View>
  )
}

export function renderCoursePacingNotice(mountPoint, courseId) {
  ReactDOM.render(<CoursePacingNotice courseId={courseId} />, mountPoint)
}

export default CoursePacingNotice
