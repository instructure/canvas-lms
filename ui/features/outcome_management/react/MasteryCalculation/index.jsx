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

import React, {useCallback} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import ProficiencyCalculation from './ProficiencyCalculation'
import RoleList from '../RoleList'
import {
  ACCOUNT_OUTCOME_CALCULATION_QUERY,
  COURSE_OUTCOME_CALCULATION_QUERY,
  SET_OUTCOME_CALCULATION_METHOD,
} from '@canvas/outcomes/graphql/MasteryCalculation'
import {useQuery, useMutation} from 'react-apollo'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const I18n = useI18nScope('MasteryScale')

const MasteryCalculation = ({onNotifyPendingChanges}) => {
  const {contextType, contextId} = useCanvasContext()
  const query =
    contextType === 'Course' ? COURSE_OUTCOME_CALCULATION_QUERY : ACCOUNT_OUTCOME_CALCULATION_QUERY
  const {loading, error, data} = useQuery(query, {
    variables: {contextId},
  })

  const [setCalculationMethodQuery, {error: setCalculationMethodError}] = useMutation(
    SET_OUTCOME_CALCULATION_METHOD
  )

  const setCalculationMethod = useCallback(
    (calculationMethod, calculationInt) => {
      setCalculationMethodQuery({
        variables: {contextType, contextId, calculationMethod, calculationInt},
      }).then(() =>
        showFlashAlert({
          message: I18n.t('Mastery calculation saved'),
          type: 'success',
        })
      )
    },
    [contextType, contextId, setCalculationMethodQuery]
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
        {I18n.t('An error occurred while loading the mastery calculation: %{error}', {error})}
      </Text>
    )
  }
  const {outcomeCalculationMethod} = data.context
  const roles = ENV.PROFICIENCY_CALCULATION_METHOD_ENABLED_ROLES || []
  const accountRoles = roles.filter(role => role.is_account_role)
  const canManage = ENV.PERMISSIONS.manage_proficiency_calculations
  return (
    <>
      <ProficiencyCalculation
        method={outcomeCalculationMethod || undefined} // send undefined when value is null
        update={setCalculationMethod}
        updateError={setCalculationMethodError}
        canManage={canManage}
        onNotifyPendingChanges={onNotifyPendingChanges}
      />

      {accountRoles.length > 0 && (
        <RoleList
          description={I18n.t(
            'Permission to change this mastery calculation at the account level is enabled for:'
          )}
          roles={accountRoles}
        />
      )}

      {roles.length > 0 && (
        <RoleList
          description={I18n.t(
            'Permission to change this mastery calculation at the course level is enabled for:'
          )}
          roles={roles}
        />
      )}
    </>
  )
}

export default MasteryCalculation
