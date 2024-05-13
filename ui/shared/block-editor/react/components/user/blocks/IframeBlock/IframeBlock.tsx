/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useCallback, useEffect, useState} from 'react'
import {useEditor, useNode} from '@craftjs/core'
import {IframeBlockSettings} from './IframeBlockSettings'
import {IconCanvasLogoLine} from '@instructure/ui-icons'

const WIDTH = '450px'
const HEIGHT = '250px'

type IframeBlockProps = {
  src?: string
  title?: string
}

const IframeBlock = ({src = 'about:blank', title = ''}) => {
  const {actions, query, enabled} = useEditor(state => {
    return {
      enabled: state.options.enabled,
    }
  })
  const {
    id,
    connectors: {connect, drag},
  } = useNode()
  const [overlayDivRef, setOverlayDivRef] = useState<HTMLDivElement | null>(null)
  const [pos, setPos] = useState({width: WIDTH, height: HEIGHT})

  const handleClick = useCallback(() => {
    actions.selectNode(id)
  }, [actions, id])

  useEffect(() => {
    if (enabled && overlayDivRef) {
      overlayDivRef.addEventListener('click', handleClick, true)

      return () => {
        overlayDivRef?.removeEventListener('click', handleClick, true)
      }
    }
  }, [enabled, handleClick, overlayDivRef])

  // return (
  //   <div
  //     className="iframe-block"
  //     ref={ref => {
  //       ref && connect(drag(ref))
  //       setOverlayDivRef(ref)
  //     }}
  //     style={{width: WIDTH, height: HEIGHT}}
  //   >
  //     <iframe src={src} title={title} />
  //     <div className="iframe-block__overlay" style={{width: pos.width, height: pos.height}} />
  //   </div>
  // )
  return (
    <div
      className="iframe-block"
      ref={ref => {
        ref && connect(drag(ref))
        setOverlayDivRef(ref)
      }}
      style={{width: WIDTH, height: HEIGHT}}
    >
      <div className="block-header">
        <IconCanvasLogoLine size="x-small" inline={true} />
        <span className="block-header-title">Canavas Content</span>
      </div>
      <iframe src={src} title={title} />
    </div>
  )
}

IframeBlock.craft = {
  displayName: 'Canvas Content',
  defaultProps: {
    src: 'about:blank',
    title: '',
  },
  related: {
    settings: IframeBlockSettings,
  },
}

export {IframeBlock}
