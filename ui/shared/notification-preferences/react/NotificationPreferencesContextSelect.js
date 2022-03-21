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

import React, {useCallback, useMemo} from 'react'
import {arrayOf, func, string} from 'prop-types'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Flex} from '@instructure/ui-flex'
import {EnrollmentShape} from './Shape'
import {useScope as useI18nScope} from '@canvas/i18n'
import {groupBy, sortBy, sortedUniqBy} from 'lodash'

const I18n = useI18nScope('notification_preferences')

export default function NotificationPreferencesContextSelect(props) {
  const sortedGroupedUniqueEnrollments = useMemo(() => {
    if (!props.enrollments) return []

    const uniqueEnrollments = sortedUniqBy(props.enrollments, 'course._id')
    const groupedEnrollments = Object.entries(groupBy(uniqueEnrollments, 'course.term._id'))
    return sortBy(groupedEnrollments, [([_, e]) => e[0].course.term.name])
  }, [props.enrollments])

  const handleChange = useCallback(
    (_, data) => {
      if (props.handleContextChanged) props.handleContextChanged(data.value)
    },
    [props]
  )

  return (
    <Flex justifyItems="space-between" margin="small 0">
      <SimpleSelect
        renderLabel={I18n.t('Settings for')}
        value={props.currentContext || 'account'}
        onChange={handleChange}
      >
        <SimpleSelect.Option id="account" value="account">
          {I18n.t('Account')}
        </SimpleSelect.Option>
        {sortedGroupedUniqueEnrollments.map(([termId, enrollments]) => (
          <SimpleSelect.Group renderLabel={enrollments[0].course.term.name} key={termId}>
            {enrollments.map(e => (
              <SimpleSelect.Option key={e.course._id} id={e.course._id} value={e.course._id}>
                {e.course.name}
              </SimpleSelect.Option>
            ))}
          </SimpleSelect.Group>
        ))}
      </SimpleSelect>
    </Flex>
  )
}

NotificationPreferencesContextSelect.propTypes = {
  currentContext: string,
  enrollments: arrayOf(EnrollmentShape),
  handleContextChanged: func
}
