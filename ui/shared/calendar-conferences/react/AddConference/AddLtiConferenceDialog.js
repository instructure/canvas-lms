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

import React, {useEffect, useCallback} from 'react'
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import ExternalToolModalLauncher from '@canvas/external-tools/react/components/ExternalToolModalLauncher'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import webConferenceType from '../proptypes/webConferenceType'

const I18n = useI18nScope('conferences')

const LTI_DATA_TYPES = ['link', 'html']

const AddLtiConferenceDialog = ({context, conferenceType, isOpen, onRequestClose, onContent}) => {
  const [contextType, contextId] = context.split('_')

  const addContentItems = useCallback(
    async ev => {
      const returnedItem = ev.content_items.find(item => LTI_DATA_TYPES.includes(item.type))
      if (!returnedItem) {
        showFlashError(I18n.t('No valid LTI resource was returned'))()
        onRequestClose()
        return
      }
      onContent(returnedItem)
    },
    [onContent, onRequestClose]
  )

  const handleWindowEvent = useCallback(
    event => {
      if (
        event.origin === ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN &&
        event.data &&
        event.data.subject === 'LtiDeepLinkingResponse'
      ) {
        addContentItems(event.data)
      }
    },
    [addContentItems]
  )

  useEffect(() => {
    window.addEventListener('message', handleWindowEvent)
    return () => {
      window.removeEventListener('message', handleWindowEvent)
    }
  }, [handleWindowEvent])

  const toolName = conferenceType?.lti_settings?.text || conferenceType?.name
  return (
    <ExternalToolModalLauncher
      isOpen={isOpen}
      title={toolName ? I18n.t('Add %{toolName}', {toolName}) : I18n.t('Add Conference')}
      tool={{
        definition_id: conferenceType?.lti_settings?.tool_id,
      }}
      onRequestClose={onRequestClose}
      contextType={contextType}
      contextId={parseInt(contextId, 10)}
      launchType="conference_selection"
    />
  )
}

AddLtiConferenceDialog.propTypes = {
  context: PropTypes.string.isRequired,
  conferenceType: webConferenceType.isRequired,
  isOpen: PropTypes.bool.isRequired,
  onRequestClose: PropTypes.func.isRequired,
  onContent: PropTypes.func.isRequired,
}

export default AddLtiConferenceDialog
