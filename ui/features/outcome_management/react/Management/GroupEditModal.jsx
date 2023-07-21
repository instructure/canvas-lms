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

import React from 'react'
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import GroupEditForm from './GroupEditForm'
import {UPDATE_LEARNING_OUTCOME_GROUP} from '@canvas/outcomes/graphql/Management'
import {useMutation} from 'react-apollo'
import {outcomeGroupShape} from './shapes'

const I18n = useI18nScope('FindOutcomesModal')

const GroupEditModal = ({outcomeGroup, isOpen, onCloseHandler}) => {
  const [editOutcomeGroup] = useMutation(UPDATE_LEARNING_OUTCOME_GROUP)

  const onEditGroupHandler = group => {
    ;(async () => {
      const input = {
        id: outcomeGroup._id,
        title: group.title,
      }
      if (group.description) input.description = group.description

      try {
        const result = await editOutcomeGroup({
          variables: {
            input,
          },
        })

        const updatedOutcomeGroup = result.data?.updateLearningOutcomeGroup?.learningOutcomeGroup
        const errorMessage = result.data?.updateLearningOutcomeGroup?.errors?.[0]?.message
        if (!updatedOutcomeGroup) throw new Error(errorMessage)

        showFlashAlert({
          type: 'success',
          message: I18n.t('"%{groupTitle}" was successfully updated.', {groupTitle: group.title}),
        })
      } catch (err) {
        showFlashAlert({
          message: I18n.t('An error occurred while editing this group. Please try again.'),
          type: 'error',
        })
      }
    })()
    onCloseHandler()
  }

  return (
    <GroupEditForm
      key={isOpen ? 0 : 1}
      isOpen={isOpen}
      onCloseHandler={onCloseHandler}
      initialValues={outcomeGroup}
      onSubmit={onEditGroupHandler}
    />
  )
}

GroupEditModal.propTypes = {
  outcomeGroup: outcomeGroupShape.isRequired,
  isOpen: PropTypes.bool.isRequired,
  onCloseHandler: PropTypes.func.isRequired,
}

export default GroupEditModal
