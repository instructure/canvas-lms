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
import I18n from 'i18n!*'

export default function NotificationPreferencesContextSelect(props) {
  const activeUniqueEnrollments = useMemo(() => {
    const courseIds = new Set()
    return (
      props.enrollments?.filter(e => {
        if (e.state !== 'active') return false
        const duplicate = courseIds.has(e.course.id)
        courseIds.add(e.course.id)
        return !duplicate
      }) || []
    )
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
        {activeUniqueEnrollments.map(e => (
          <SimpleSelect.Option key={e.course.id} id={e.course.id} value={e.course._id}>
            {e.course.name}
          </SimpleSelect.Option>
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
