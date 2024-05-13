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
import {useEditor, useNode, type Node} from '@craftjs/core'
import {useClassNames} from '../../../../utils'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

export type PageBlockProps = {
  children?: React.ReactNode
}

export const PageBlock = ({children}: PageBlockProps) => {
  const {enabled, actions} = useEditor(state => {
    // console.log('>>>pageblock')
    // console.log(JSON.parse(query.serialize()))
    return {
      enabled: state.options.enabled,
    }
  })
  const {
    connectors: {connect},
  } = useNode()
  const clazz = useClassNames(enabled, {empty: !children}, ['page-block'])
  const [pageRef, setPageRef] = useState<HTMLDivElement | null>(null)

  const handlePagekey = useCallback(
    (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        // @ts-expect-error (null is allowed)
        actions.selectNode(null)
      }
    },
    [actions]
  )

  useEffect(() => {
    pageRef?.addEventListener('keydown', handlePagekey)
    return () => {
      pageRef?.removeEventListener('keydown', handlePagekey)
    }
  }, [handlePagekey, pageRef])

  const handlePaste = useCallback((_e: React.ClipboardEvent<HTMLDivElement>) => {
    // Some day we should take what's on the clipboard and convert it into
    // the appropriate blocks.
    // console.log('>>> paste')
  }, [])

  return (
    <div
      className={clazz}
      data-placeholder="Drop a section here"
      ref={el => {
        el && connect(el)
        setPageRef(el)
      }}
      style={{
        background: 'transparent',
        padding: '16px',
        minHeight: '10rem',
      }}
      onPaste={handlePaste}
    >
      <a id="page-top" href="#page-top">
        <ScreenReaderContent>page top</ScreenReaderContent>
      </a>
      {children}
    </div>
  )
}

PageBlock.craft = {
  displayName: 'Page',
  rules: {
    canMoveIn: (incomingNodes: Node[]) => {
      // return incomingNodes.every((incomingNode: Node) => incomingNode.data.custom.isSection)
      return true
    },
  },
}
