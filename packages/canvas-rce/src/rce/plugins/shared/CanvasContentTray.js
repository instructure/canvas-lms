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

import React, {Suspense, useState} from 'react'
import {bool, oneOf, func} from 'prop-types'
import {Tray} from '@instructure/ui-overlays'
import {CloseButton} from '@instructure/ui-buttons'
import {Spinner} from '@instructure/ui-elements'
import formatMessage from '../../../format-message'

/**
 * Returns the translated tray label
 * @param {string} activeContentType
 * @returns {string}
 */
function getTrayLabel(activeContentType) {
  switch (activeContentType) {
    case 'links':
      return formatMessage('Course Links')
    case 'images':
      return formatMessage('Course Images')
    case 'media':
      return formatMessage('Course Media')
    case 'documents':
      return formatMessage('Course Documents')
    default:
      return formatMessage('Tray') // Shouldn't ever get here
  }
}

/**
 * Returns the component lazily for the given active content
 * @param {string} activeContentType
 */
function loadTrayContent(activeContentType) {
  switch (activeContentType) {
    case 'links':
    case 'images':
    case 'media':
    case 'documents':
      return React.lazy(() => import('./FakeComponent'))
  }
}

/**
 * This component is used within various plugins to handle loading in content
 * from Canvas.  It is essentially the main component.
 */
export default function CanvasContentTray(props) {
  const [activeContentType, _setActiveContentType] = useState(props.initialContentType)
  const ContentComponent = loadTrayContent(activeContentType)
  return (
    <Tray label={getTrayLabel(activeContentType)} open={props.isOpen} placement="end">
      <CloseButton placement="end" offset="medium" variant="icon" onClick={props.handleClose}>
        Close
      </CloseButton>
      <div>Add Stuff</div>
      <Suspense fallback={<Spinner title={formatMessage('Loading')} size="large" />}>
        <ContentComponent />
      </Suspense>
    </Tray>
  )
}

CanvasContentTray.propTypes = {
  /**
   * Is the tray currently open?
   */
  isOpen: bool,
  /**
   * This dictates the type of content that the tray will load initially
   * after the initial load, this value is controlled by the activeContentType
   * state property.
   */
  initialContentType: oneOf(['links', 'images', 'media', 'documents']).isRequired,
  /**
   * How to handle closing the modal
   */
  handleClose: func.isRequired
}

CanvasContentTray.defaultProps = {
  isOpen: false
}
