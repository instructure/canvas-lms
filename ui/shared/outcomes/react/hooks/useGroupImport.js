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

import {useState} from 'react'
import I18n from 'i18n!FindOutcomesModal'
import {IMPORT_OUTCOME_GROUP} from '@canvas/outcomes/graphql/Management'
import {useMutation} from 'react-apollo'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'

const useGroupImport = () => {
  const [importGroupsStatus, setImportGroupsStatus] = useState({})
  const {contextId: targetContextId, contextType: targetContextType, isCourse} = useCanvasContext()
  const [importGroupMutation] = useMutation(IMPORT_OUTCOME_GROUP)

  const importGroup = async groupId => {
    try {
      const importGroupResult = await importGroupMutation({
        variables: {
          input: {
            groupId,
            targetContextId,
            targetContextType
          }
        }
      })

      const importErrors = importGroupResult.data?.importOutcomes?.errors
      const errorMessage = importErrors?.[0]?.message
      if (importErrors !== null) throw new Error(errorMessage)

      showFlashAlert({
        message: isCourse
          ? I18n.t('The outcome group was successfully imported into this course')
          : I18n.t('The outcome group was successfully imported into this account'),
        type: 'success'
      })

      // Temp value for [groupId] until OUT-4632 is merged
      setImportGroupsStatus({
        ...importGroupsStatus,
        [groupId]: true
      })
    } catch (err) {
      showFlashAlert({
        message: err.message
          ? I18n.t('An error occurred while importing this group: %{message}.', {
              message: err.message
            })
          : I18n.t('An error occurred while importing this group.'),
        type: 'error'
      })
    }
  }

  return {
    importGroup,
    importGroupsStatus
  }
}

export default useGroupImport
