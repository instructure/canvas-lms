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

import PropTypes from 'prop-types'
import React, {useState} from 'react'

import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TextArea} from '@instructure/ui-text-area'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('conversations_2')

export const MessageBody = props => {
  const [body, setBody] = useState('')

  const handleBodyChange = e => {
    setBody(e.target.value)
    props.onBodyChange(e.target.value)
  }

  return (
    <TextArea
      label={<ScreenReaderContent>{I18n.t('Message Body')}</ScreenReaderContent>}
      messages={props.messages}
      autoGrow={false}
      height="200px"
      maxHeight="200px"
      value={body}
      onChange={handleBodyChange}
      data-testid="message-body"
    />
  )
}

MessageBody.propTypes = {
  onBodyChange: PropTypes.func.isRequired,
  messages: PropTypes.arrayOf(
    PropTypes.shape({
      text: PropTypes.string,
      type: PropTypes.string,
    })
  ),
}
