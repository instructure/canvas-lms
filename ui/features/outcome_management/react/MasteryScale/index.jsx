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

import React, {useCallback, useState, useEffect} from 'react'
import {useApolloClient} from '@apollo/client'
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
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'

const I18n = createI18nScope('MasteryScale')

async function loadProficiencyRatings(client, query, contextId, controller) {
  const queryFn = after => {
    return client.query({
      query,
      variables: {
        contextId,
        proficiencyRatingsCursor: after
      },
      fetchPolicy: process.env.NODE_ENV === 'test' ? undefined : 'no-cache',
      context: { fetchOptions: { signal: controller.signal } }
    })
  }
  const {data: initialData} = JSON.parse(JSON.stringify(await queryFn(null))) // deep copy of frozen object so we can modify it
  const proficiencyRatings = initialData.context.outcomeProficiency?.proficiencyRatingsConnection

  if(!proficiencyRatings) return {data: initialData}

  while (true) {
    const after = proficiencyRatings?.pageInfo?.hasNextPage
        && proficiencyRatings?.pageInfo?.endCursor
    if (!after) break
    const {data: pagedData} = await queryFn(after)
    const pagedProficiencyRatings = pagedData.context.outcomeProficiency.proficiencyRatingsConnection
    proficiencyRatings.nodes = proficiencyRatings.nodes.concat(pagedProficiencyRatings.nodes)
    proficiencyRatings.pageInfo = pagedProficiencyRatings.pageInfo
  }

  return {data: initialData}
}

const MasteryScale = ({onNotifyPendingChanges}) => {
  const [error, setError] = useState(null)
  const [loading, setLoading] = useState(true)
  const [data, setData] = useState(null)
  const {contextType, contextId} = useCanvasContext()
  const client = useApolloClient()
  const query =
    contextType === 'Course' ? COURSE_OUTCOME_PROFICIENCY_QUERY : ACCOUNT_OUTCOME_PROFICIENCY_QUERY

  useEffect(() => {
    const controller = new AbortController()
    loadProficiencyRatings(
      client,
      query,
      contextId,
      controller,
    )
    .then(({data}) => setData(data))
    .catch(error => setError(error))
    .finally(() => setLoading(false))
    return () => controller.abort()
  }, [])

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
              'This mastery scale will be used as the default for all courses within your account.',
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
