/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {Alert} from '@instructure/ui-alerts'
import {oneOf, func, array, shape, string} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('account_course_user_search')

const errorLoadingMessage = I18n.t(
  'There was an error with your query; please try a different search'
)
const noCoursesFoundMessage = I18n.t('No courses found')
const noUsersFoundMessage = I18n.t('No users found')
const userResultsUpdatedMessage = I18n.t('User results updated.')
const courseResultsUpdatedMessage = I18n.t('Course results updated.')

const TIMEOUT = 5000

const linkPropType = shape({
  url: string.isRequired,
  page: string.isRequired,
}).isRequired

/**
 * This component handles reading the updated message only when rendered and
 * only when the collection has finished loading
 */
export default function SRSearchMessage({collection, dataType, getLiveAlertRegion}) {
  if (collection.loading) {
    return <noscript />
  }

  if (collection.error) {
    return (
      <Alert screenReaderOnly={true} liveRegion={getLiveAlertRegion} timeout={TIMEOUT}>
        {errorLoadingMessage}
      </Alert>
    )
  }
  if (!collection.data.length) {
    if (dataType === 'Course') {
      return (
        <Alert screenReaderOnly={true} liveRegion={getLiveAlertRegion} timeout={TIMEOUT}>
          {noCoursesFoundMessage}
        </Alert>
      )
    }
    if (dataType === 'User') {
      return (
        <Alert screenReaderOnly={true} liveRegion={getLiveAlertRegion} timeout={TIMEOUT}>
          {noUsersFoundMessage}
        </Alert>
      )
    }
  }

  if (dataType === 'Course') {
    return (
      <Alert screenReaderOnly={true} liveRegion={getLiveAlertRegion} timeout={TIMEOUT}>
        {courseResultsUpdatedMessage}
      </Alert>
    )
  }
  if (dataType === 'User') {
    return (
      <Alert screenReaderOnly={true} liveRegion={getLiveAlertRegion} timeout={TIMEOUT}>
        {userResultsUpdatedMessage}
      </Alert>
    )
  }

  return <noscript />
}

SRSearchMessage.propTypes = {
  collection: shape({
    data: array.isRequired,
    links: shape({current: linkPropType}),
  }).isRequired,
  dataType: oneOf(['Course', 'User']).isRequired,
  getLiveAlertRegion: func,
}

SRSearchMessage.defaultProps = {
  getLiveAlertRegion() {
    return document.getElementById('flash_screenreader_holder')
  },
}
