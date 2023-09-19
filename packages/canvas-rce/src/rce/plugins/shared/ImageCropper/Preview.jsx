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

import React, {useEffect, createRef} from 'react'
import PropTypes from 'prop-types'
import formatMessage from '../../../../format-message'
import {ImageCropperSettingsPropTypes} from './propTypes'
import {buildSvg} from './svg'
import {PREVIEW_WIDTH, PREVIEW_HEIGHT, BACKGROUND_SQUARE_SIZE} from './constants'
import {useMouseWheel} from './useMouseWheel'
import {useKeyMouseTouchEvents} from './useKeyMouseEvents'
import checkerboardStyle from '../CheckerboardStyling'
import {View} from '@instructure/ui-view'

/**
 * Remove the node contents and append the svg element.
 */
function replaceSvg(svg, node) {
  if (!node) return
  while (node.firstChild) {
    node.removeChild(node.lastChild)
  }
  node.appendChild(svg)
}

function getTransformValue({translateX, translateY, rotation, scaleRatio}) {
  const values = []
  if (translateX !== 0) values.push(`translateX(${translateX}px)`)
  if (translateY !== 0) values.push(`translateY(${translateY}px)`)
  if (rotation && rotation % 360 !== 0) values.push(`rotate(${rotation}deg)`)
  if (scaleRatio > 1) values.push(`scale(${scaleRatio})`)
  return values.join(' ')
}

export const Preview = ({image, settings, dispatch}) => {
  const previewRef = createRef()
  const shapeRef = createRef()
  const imgRef = createRef()
  const {shape, rotation, scaleRatio, translateX, translateY} = settings
  const [tempScaleRatio, onWheelCallback] = useMouseWheel(scaleRatio, dispatch)
  const [tempTranslateX, tempTranslateY, onMouseDownCallback, onTouchStartCallback] =
    useKeyMouseTouchEvents(translateX, translateY, dispatch, imgRef)

  useEffect(() => {
    imgRef.current.ondragstart = () => false
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  useEffect(() => {
    const svg = buildSvg(shape)
    replaceSvg(svg, shapeRef.current)
  })

  const transformValue = getTransformValue({
    translateX: tempTranslateX,
    translateY: tempTranslateY,
    rotation,
    scaleRatio: tempScaleRatio,
  })

  function isSafariVersion15OrLesser() {
    const match = /Version\/(\d+).+Safari/.exec(navigator.userAgent)
    return match ? parseInt(match[1], 10) < 16 : false
  }

  // Clip is not supported in Safari until v16.
  // It's needed here to prevent a strange screenreader
  // behavior that makes the cropper look bad. 'hidden'
  // suffices when clip is not available, although it's not perfect
  // TODO: remove when Safari versions >= 16 are more commonplace
  const overflow = isSafariVersion15OrLesser() ? 'hidden' : 'clip'

  return (
    <div
      style={{
        justifyContent: 'center',
        overflow,
        ...checkerboardStyle(BACKGROUND_SQUARE_SIZE),
      }}
    >
      <View
        as="div"
        tabIndex={0}
        id="cropper-preview"
        ref={previewRef}
        height={PREVIEW_HEIGHT}
        width={PREVIEW_WIDTH}
        position="relative"
        focusPosition="inset"
        insetInlineStart="0"
        insetBlockStart="0"
        textAlign="center"
        shouldAnimateFocus={false}
        onWheel={onWheelCallback}
      >
        {/* eslint-disable-next-line jsx-a11y/no-noninteractive-element-interactions */}
        <img
          src={image}
          ref={imgRef}
          alt={formatMessage('Image to crop')}
          style={{
            height: '100%',
            objectFit: 'contain',
            textAlign: 'center',
            transform: transformValue,
          }}
          onMouseDown={onMouseDownCallback}
          onTouchStart={onTouchStartCallback}
        />
        <div
          id="cropShapeContainer"
          ref={shapeRef}
          style={{
            position: 'absolute',
            top: 0,
            left: 0,
            pointerEvents: 'none',
          }}
        />
      </View>
    </div>
  )
}

Preview.propTypes = {
  image: PropTypes.string.isRequired,
  settings: ImageCropperSettingsPropTypes.isRequired,
  dispatch: PropTypes.func.isRequired,
}
