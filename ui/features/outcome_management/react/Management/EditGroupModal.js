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

import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {updateOutcomeGroup} from '@canvas/outcomes/graphql/Management'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'
import {FORM_ERROR} from 'final-form'
import I18n from 'i18n!FindOutcomesModal'
import PropTypes from 'prop-types'
import React from 'react'
import {outcomeGroupShape} from './shapes'
import EditGroupForm from './EditGroupForm'

const EditGroupModal = ({outcomeGroup, isOpen, onCloseHandler}) => {
  const {contextType, contextId} = useCanvasContext()

  const onSubmit = async group => {
    delete group._id
    if (!group.description) {
      group.description = ''
    }

    try {
      await updateOutcomeGroup(contextType, contextId, outcomeGroup._id, group)
      onCloseHandler()
      showFlashAlert({
        type: 'success',
        message: I18n.t('The group %{title} was successfully updated.', {title: group.title})
      })
    } catch (err) {
      const message = err.message
        ? I18n.t('An error occurred while updating the group: %{message}', {
            message: err.message
          })
        : I18n.t('An error occurred while updating the group.')

      showFlashAlert({
        type: 'error',
        message
      })

      return {
        [FORM_ERROR]: I18n.t('An error occurred while updating the group: %{message}', {
          message: err.message
        })
      }
    }
  }

  return (
    <EditGroupForm
      key={isOpen ? 0 : 1}
      isOpen={isOpen}
      onCloseHandler={onCloseHandler}
      initialValues={outcomeGroup}
      onSubmit={onSubmit}
    />
  )
}

EditGroupModal.propTypes = {
  outcomeGroup: outcomeGroupShape.isRequired,
  isOpen: PropTypes.bool.isRequired,
  onCloseHandler: PropTypes.func.isRequired
}

export default EditGroupModal
