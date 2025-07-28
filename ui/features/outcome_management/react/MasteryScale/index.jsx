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
import {useScope as createI18nScope} from '@canvas/i18n'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import ProficiencyTable from './ProficiencyTable'
import RoleList from '../RoleList'
import {
  saveProficiency,
  ACCOUNT_OUTCOME_PROFICIENCY_QUERY,
  COURSE_OUTCOME_PROFICIENCY_QUERY,
} from '@canvas/outcomes/graphql/MasteryScale'
import {useAllPages} from '@canvas/query'
import {executeQuery} from '@canvas/graphql'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'

const I18n = createI18nScope('MasteryScale')

const queryFn = ({pageParam, queryKey}) => {
  const [_key, contextType, contextId] = queryKey
  const query =
    contextType === 'Course' ? COURSE_OUTCOME_PROFICIENCY_QUERY : ACCOUNT_OUTCOME_PROFICIENCY_QUERY
  return executeQuery(query, {
    contextId,
    proficiencyRatingsCursor: pageParam,
  })
}

const getNextPageParam = lastPage => {
  const pageInfo = lastPage?.context.outcomeProficiency?.proficiencyRatingsConnection?.pageInfo
  return pageInfo?.hasNextPage ? pageInfo.endCursor : null
}

const MasteryScale = ({onNotifyPendingChanges}) => {
  const {contextType, contextId} = useCanvasContext()

  const {
    data,
    isError: error,
    isLoading: loading,
    hasNextPage,
  } = useAllPages({
    queryKey: [
      contextType === 'Course' ? 'courseProficiencyRatings' : 'accountProficiencyRatings',
      contextType,
      contextId,
    ],
    queryFn,
    getNextPageParam,
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
          }),
        )
        throw e
      }
    },
    [contextType, contextId],
  )

  if (loading || hasNextPage) {
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

  const getOutcomeProficiency = () => {
    return data.pages.reduce((acc, page) => {
      if (!acc) return page
      acc.context.outcomeProficiency.proficiencyRatingsConnection.nodes = [
        ...acc.context.outcomeProficiency.proficiencyRatingsConnection.nodes,
        ...page.context.outcomeProficiency.proficiencyRatingsConnection.nodes,
      ]
      return acc
    }, null).context.outcomeProficiency
  }

  const roles = ENV.PROFICIENCY_SCALES_ENABLED_ROLES || []
  const accountRoles = roles.filter(role => role.is_account_role)
  const canManage = ENV.PERMISSIONS.manage_proficiency_scales

  return (
    <div data-testid="masteryScales">
      {canManage && contextType === 'Account' && (
        <p>
          <Text>
            {I18n.t(
              'This mastery scale will be used as the default for all courses within your account.',
            )}
          </Text>
        </p>
      )}

      <ProficiencyTable
        contextType={contextType}
        proficiency={getOutcomeProficiency() || undefined} // send undefined when value is null
        update={updateProficiencyRatings}
        updateError={updateProficiencyRatingsError}
        onNotifyPendingChanges={onNotifyPendingChanges}
      />

      {accountRoles.length > 0 && (
        <RoleList
          description={I18n.t(
            'Permission to change this mastery scale at the account level is enabled for:',
          )}
          roles={accountRoles}
        />
      )}

      {roles.length > 0 && (
        <RoleList
          description={I18n.t(
            'Permission to change this mastery scale at the course level is enabled for:',
          )}
          roles={roles}
        />
      )}
    </div>
  )
}

export default MasteryScale
