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

import React, {useEffect, useRef} from 'react'

import {View} from '@instructure/ui-view'

import {buildSvg} from '../../svg'
import checkerboardStyle from '../../../shared/CheckerboardStyling'
import formatMessage from 'format-message'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const SQUARE_SIZE = 8

export const Preview = ({settings}) => {
  const wrapper = useRef(null)

  useEffect(() => {
    const svg = buildSvg(settings, {isPreview: true})
    appendSvg(svg, wrapper.current)
  }, [settings])

  const previewMessage = formatMessage('Icon Preview')

  return (
    <View as="div">
      <ScreenReaderContent>{previewMessage}</ScreenReaderContent>
      <div
        aria-hidden="true"
        style={{
          ...checkerboardStyle(SQUARE_SIZE),
          display: 'flex',
          justifyContent: 'center',
        }}
        ref={wrapper}
      />
    </View>
  )
}

/**
 * Remove the node contents and append the svg element.
 */
function appendSvg(svg, node) {
  if (!node) return
  while (node.firstChild) {
    node.removeChild(node.lastChild)
  }
  node.appendChild(svg)
}
