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

import React, {useCallback, useEffect, useRef, useState} from 'react'
import {useEditor, useNode} from '@craftjs/core'
import CanvasRce from '@canvas/rce/react/CanvasRce'
import {useClassNames} from '../../../../utils'

type RCEBlockProps = {
  text?: string
}

export const RCEBlock = ({text = ''}: RCEBlockProps) => {
  const {actions, enabled} = useEditor(state => ({
    enabled: state.options.enabled,
  }))
  const {
    connectors: {connect, drag},
    actions: {setProp},
    id,
    selected,
  } = useNode(state => ({
    id: state.id,
    selected: state.events.selected,
  }))
  const clazz = useClassNames(enabled, {empty: !text}, ['block', 'rce-text-block'])
  const focusableElem = useRef<HTMLDivElement | null>(null)

  const [editable, setEditable] = useState(true)
  const rceRef = useRef(null)

  useEffect(() => {
    if (editable && selected) {
      focusableElem.current?.focus()
    }
    setEditable(selected)
  }, [editable, focusableElem, selected])

  const handleRCEFocus = useCallback(() => {
    actions.selectNode(id)
  }, [actions, id])

  const handleChange = useCallback(
    (content: string) => {
      setProp(props => {
        props.text = content
      })
    },
    [setProp]
  )

  if (enabled && selected) {
    return (
      // eslint-disable-next-line jsx-a11y/interactive-supports-focus, jsx-a11y/click-events-have-key-events
      <div
        ref={el => {
          if (el) {
            connect(drag(el))
          }
        }}
        role="textbox"
        onClick={e => setEditable(true)}
      >
        <CanvasRce
          ref={rceRef}
          autosave={false}
          defaultContent={text}
          editorOptions={{
            focus: false,
          }}
          height={300}
          textareaId="rceblock_text"
          onFocus={handleRCEFocus}
          onBlur={() => {}}
          onContentChange={handleChange}
        />
      </div>
    )
  } else {
    return <div className={clazz} dangerouslySetInnerHTML={{__html: text}} />
  }
}

RCEBlock.craft = {
  displayName: 'Rich Text',
}
