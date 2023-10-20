/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import React, {useCallback, useState} from 'react'
import {useQuery} from 'react-apollo'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import ProficiencyTable from './ProficiencyTable'
import RoleList from '../RoleList'
import {
  saveProficiency,
  ACCOUNT_OUTCOME_PROFICIENCY_QUERY,
  COURSE_OUTCOME_PROFICIENCY_QUERY,
} from '@canvas/outcomes/graphql/MasteryScale'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'

const I18n = useI18nScope('MasteryScale')

const MasteryScale = ({onNotifyPendingChanges}) => {
  const {contextType, contextId} = useCanvasContext()
  const query =
    contextType === 'Course' ? COURSE_OUTCOME_PROFICIENCY_QUERY : ACCOUNT_OUTCOME_PROFICIENCY_QUERY

  const {loading, error, data} = useQuery(query, {
    variables: {contextId},
    fetchPolicy: process.env.NODE_ENV === 'test' ? undefined : 'no-cache',
  })

  const [updateProficiencyRatingsError, setUpdateProficiencyRatingsError] = useState(null)
  const updateProficiencyRatings = useCallback(
    async config => {
      try {
        const response = await saveProficiency(contextType, contextId, config)
        if (response.status !== 200) {
          setUpdateProficiencyRatingsError(I18n.t('An error occurred updating the mastery scale'))
          throw new Error(I18n.t('HTTP Response: %{code}', {code: response.status}))
        }
      } catch (e) {
        setUpdateProficiencyRatingsError(
          I18n.t('An error occurred updating the mastery scale: %{message}', {
            message: e.message,
          })
        )
        throw e
      }
    },
    [contextType, contextId]
  )

  if (loading) {
    return (
      <div style={{textAlign: 'center'}}>
        <Spinner renderTitle={I18n.t('Loading')} size="large" margin="0 0 0 medium" />
      </div>
    )
  }
  if (error) {
    return (
      <Text color="danger">
        {I18n.t('An error occurred while loading the mastery scale: %{error}', {error})}
      </Text>
    )
  }
  const {outcomeProficiency} = data.context

  const roles = ENV.PROFICIENCY_SCALES_ENABLED_ROLES || []
  const accountRoles = roles.filter(role => role.is_account_role)
  const canManage = ENV.PERMISSIONS.manage_proficiency_scales

  return (
    <div data-testid="masteryScales">
      {canManage && contextType === 'Account' && (
        <p>
          <Text>
            {I18n.t(
              'This mastery scale will be used as the default for all courses within your account.'
            )}
          </Text>
        </p>
      )}

      <ProficiencyTable
        contextType={contextType}
        proficiency={outcomeProficiency || undefined} // send undefined when value is null
        update={updateProficiencyRatings}
        updateError={updateProficiencyRatingsError}
        onNotifyPendingChanges={onNotifyPendingChanges}
      />

      {accountRoles.length > 0 && (
        <RoleList
          description={I18n.t(
            'Permission to change this mastery scale at the account level is enabled for:'
          )}
          roles={accountRoles}
        />
      )}

      {roles.length > 0 && (
        <RoleList
          description={I18n.t(
            'Permission to change this mastery scale at the course level is enabled for:'
          )}
          roles={roles}
        />
      )}
    </div>
  )
}

export default MasteryScale
