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

import React from 'react'
import {bool, node, oneOf} from 'prop-types'
import {Alert} from '@instructure/ui-alerts'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

CanvasInlineAlert.propTypes = {
  liveAlert: bool,
  screenReaderOnly: bool,
  politeness: oneOf(['assertive', 'polite']),
  children: node,
}

export default function CanvasInlineAlert({
  children,
  liveAlert,
  screenReaderOnly,
  politeness = 'assertive',
  ...alertProps
}) {
  let body = children
  if (liveAlert || screenReaderOnly) {
    body = (
      <span role="alert" aria-live={politeness} aria-atomic={true}>
        {body}
      </span>
    )
  }

  if (screenReaderOnly) {
    return <ScreenReaderContent>{body}</ScreenReaderContent>
  }
  return <Alert {...alertProps}>{body}</Alert>
}
