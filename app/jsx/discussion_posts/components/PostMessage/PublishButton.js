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

import PropTypes from 'prop-types'
import React, {useState} from 'react'
import {Button} from '@instructure/ui-buttons'
import {IconCompleteSolid, IconNoLine} from '@instructure/ui-icons'
import I18n from 'i18n!conversations_2'

export function PublishButton({...props}) {
  const [publishStatus, setPublishStatus] = useState(props.initialState)
  const handleInteraction = () => {
    if (publishStatus === 'published') {
      setPublishStatus('hovered')
    }
  }
  const handleExit = () => {
    if (publishStatus === 'hovered') {
      setPublishStatus('published')
    }
  }

  return (
    <Button
      onMouseEnter={handleInteraction}
      onMouseLeave={handleExit}
      onFocus={handleInteraction}
      onBlur={handleExit}
      margin="0 xxx-small"
      renderIcon={iconForStatus(publishStatus)}
      color={colorForStatus(publishStatus)}
      interaction={interactionForStatus(publishStatus)}
      onClick={props.onClick}
    >
      {textCallbackForStatus(publishStatus).call()}
    </Button>
  )
}

const textCallbackForStatus = status => {
  switch (status) {
    case 'published':
      return () => I18n.t('Published')
    case 'publishing':
      return () => I18n.t('Publishing...')
    case 'unpublished':
      return () => I18n.t('Publish')
    case 'unpublishing':
      return () => I18n.t('Unpublishing...')
    case 'hovered':
      return () => I18n.t('Unpublish')
    default:
      throw new Error(`Unsupported option: ${status}`)
  }
}

const iconForStatus = status => {
  switch (status) {
    case 'published':
    case 'publishing':
      return IconCompleteSolid
    default:
      return IconNoLine
  }
}

const colorForStatus = status => {
  switch (status) {
    case 'published':
      return 'success'
    case 'unpublishing':
    case 'hovered':
      return 'danger'
    default:
      return 'secondary'
  }
}

const interactionForStatus = status => {
  switch (status) {
    case 'unpublishing':
    case 'publishing':
      return 'readonly'
    default:
      return 'enabled'
  }
}

PublishButton.propTypes = {
  initialState: PropTypes.oneOf(['published', 'publishing', 'unpublished', 'unpublishing'])
    .isRequired,
  onClick: PropTypes.func.isRequired
}

export default PublishButton
