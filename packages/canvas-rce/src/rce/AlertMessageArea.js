/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {Alert} from '@instructure/ui-alerts'
import React from 'react'
import {arrayOf, func, number, shape, string} from 'prop-types'

/**
 * Shows messages that have been provided to it in the RCE
 */
export default function AlertMessageArea({messages, afterDismiss, liveRegion}) {
  return (
    <div>
      {messages.map(message => (
        <Alert
          key={message.id}
          variant={message.variant || message.type || 'info'}
          timeout={10000}
          liveRegion={liveRegion}
          onDismiss={() => afterDismiss(message.id)}
        >
          {message.text}
        </Alert>
      ))}
    </div>
  )
}

AlertMessageArea.propTypes = {
  messages: arrayOf(
    shape({
      id: number,
      variant: string,
      text: string,
    })
  ).isRequired,
  afterDismiss: func,
  liveRegion: func.isRequired,
}
