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
import type {AlertVariant} from './types'

interface AlertMessageAreaProps {
  messages: {
    id: number
    variant: AlertVariant
    text: string
  }[]
  afterDismiss: (messageId: number) => void
  liveRegion?: () => HTMLElement | null | undefined
}

/**
 * Shows messages that have been provided to it in the RCE
 */
export default function AlertMessageArea({
  messages,
  afterDismiss,
  liveRegion,
}: AlertMessageAreaProps) {
  return (
    <div>
      {messages.map(message => (
        <Alert
          key={message.id}
          variant={message.variant || 'info'}
          timeout={10000}
          // @ts-expect-error
          liveRegion={liveRegion}
          onDismiss={() => afterDismiss(message.id)}
        >
          {message.text}
        </Alert>
      ))}
    </div>
  )
}
