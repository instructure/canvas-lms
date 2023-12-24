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

import {useState, useCallback} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {CREATE_LEARNING_OUTCOME_GROUP} from '../../graphql/Management'
import {useMutation} from 'react-apollo'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const I18n = useI18nScope('FindOutcomesModal')

const useGroupCreate = () => {
  const [createdGroups, setCreatedGroups] = useState([])
  const [addOutcomeGroup] = useMutation(CREATE_LEARNING_OUTCOME_GROUP)

  const createGroup = useCallback(
    async (groupName, parentGroupId) => {
      try {
        const addOutcomeGroupResult = await addOutcomeGroup({
          variables: {
            input: {
              id: parentGroupId,
              title: groupName,
            },
          },
        })
        const newGroup =
          addOutcomeGroupResult.data?.createLearningOutcomeGroup?.learningOutcomeGroup
        const errors = addOutcomeGroupResult.data?.createLearningOutcomeGroup?.errors
        if (errors !== null) throw new Error(errors?.[0]?.message)

        setCreatedGroups(prevCreatedGroups => [...prevCreatedGroups, newGroup._id])

        showFlashAlert({
          message: I18n.t('"%{groupName}" was successfully created.', {groupName}),
          type: 'success',
        })
        return newGroup
      } catch (err) {
        showFlashAlert({
          message: I18n.t('An error occurred while creating this group. Please try again.'),
          type: 'error',
        })
      }
    },
    [addOutcomeGroup]
  )

  const clearCreatedGroups = () => setCreatedGroups([])

  return {
    createGroup,
    createdGroups,
    clearCreatedGroups,
  }
}

export default useGroupCreate
