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
import React, {useContext, useEffect} from 'react'
import {func, string, object} from 'prop-types'
import {useQuery} from 'react-apollo'
import NotificationPreferencesContextSelect from './NotificationPreferencesContextSelect'
import {NOTIFICATION_PREFERENCES_CONTEXT_SELECT_QUERY} from '../graphql/Queries'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'

const I18n = useI18nScope('courses')

export default function NotificationPreferencesContextSelectQuery(props) {
  const {setOnFailure} = useContext(AlertManagerContext)
  const {error, data} = useQuery(NOTIFICATION_PREFERENCES_CONTEXT_SELECT_QUERY, {
    variables: {
      userId: props.userId,
    },
  })

  useEffect(() => {
    if (error) {
      setOnFailure(I18n.t('Failed to load courses. Refresh the page to try again.'))
    }
  }, [error, setOnFailure])

  return (
    <NotificationPreferencesContextSelect
      currentContext={props.currentContext}
      enrollments={data?.legacyNode?.enrollments}
      handleContextChanged={props.onContextChanged}
    />
  )
}

NotificationPreferencesContextSelectQuery.propTypes = {
  userId: string.isRequired,
  currentContext: object.isRequired,
  onContextChanged: func,
}
