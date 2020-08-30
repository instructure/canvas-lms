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
import I18n from 'i18n!MasteryScale'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import ProficiencyTable from './ProficiencyTable'
import {saveProficiency, OUTCOME_PROFICIENCY_QUERY} from './api'
import {useQuery, useMutation} from 'react-apollo'

const MasteryScale = ({contextType, contextId}) => {
  const {loading, error, data} = useQuery(OUTCOME_PROFICIENCY_QUERY, {
    variables: {contextId}
  })

  // const [updateProficiencyRatingsQuery, {error: updateProficiencyRatingsError}] = useMutation(
  //   SET_OUTCOME_PROFICIENCY_RATINGS
  // )
  const [updateProficiencyRatingsError, setUpdateProficiencyRatingsError] = useState(null)
  const updateProficiencyRatings = useCallback(
    async config => {
      try {
        const response = await saveProficiency(contextType, contextId, config)
        if (response.status !== 200) {
          setUpdateProficiencyRatingsError(
            I18n.t('An error occurred updating the proficiency ratings')
          )
          throw new Error(I18n.t('HTTP Response: %{code}', {code: response.status}))
        }
      } catch (e) {
        setUpdateProficiencyRatingsError(
          I18n.t('An error occurred updating the proficiency ratings: %{message}', {
            message: e.message
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
        {I18n.t('An error occurred while loading the proficiency ratings: %{error}', {error})}
      </Text>
    )
  }
  const {outcomeProficiency} = data.account
  return (
    <div>
      <Heading level="h5" margin="medium 0">
        {I18n.t('Set the mastery scale to be used for all courses within this account.')}
      </Heading>
      <ProficiencyTable
        proficiency={outcomeProficiency || undefined} // send undefined when value is null
        update={updateProficiencyRatings}
        updateError={updateProficiencyRatingsError}
      />
    </div>
  )
}

export default MasteryScale
