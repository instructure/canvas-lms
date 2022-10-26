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

import React, {useRef, useState} from 'react'
import CanvasInlineAlert from '@canvas/alerts/react/InlineAlert'
import {Spinner} from '@instructure/ui-spinner'

export default function DirectShareOperationStatus({promise, startingMsg, successMsg, errorMsg}) {
  const [operationStatus, setOperationStatus] = useState('starting')
  const previousPromise = useRef(null)

  if (previousPromise.current !== promise) {
    previousPromise.current = promise
    setOperationStatus('starting')
    if (promise) {
      promise
        .then(() => {
          if (promise === previousPromise.current) {
            setOperationStatus('success')
          }
        })
        .catch(err => {
          if (promise === previousPromise.current) {
            console.error(err) // eslint-disable-line no-console
            if (err && err.response) console.error(err.response) // eslint-disable-line no-console
            setOperationStatus('error')
          }
        })
    }
  }

  let alert
  const alertProps = {
    liveAlert: true,
    margin: 'small 0',
  }

  if (operationStatus === 'error') {
    alert = (
      <CanvasInlineAlert variant="error" {...alertProps}>
        {errorMsg}
      </CanvasInlineAlert>
    )
  } else if (operationStatus === 'success') {
    alert = (
      <CanvasInlineAlert variant="success" {...alertProps}>
        {successMsg}
      </CanvasInlineAlert>
    )
  } else if (operationStatus === 'starting') {
    alert = (
      <CanvasInlineAlert variant="info" {...alertProps}>
        {startingMsg}
        <Spinner renderTitle={startingMsg} size="x-small" />
      </CanvasInlineAlert>
    )
  }

  return promise ? alert : null
}
