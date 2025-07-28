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
import {uid} from '@instructure/uid'
import CanvasRce from '@canvas/rce/react/CanvasRce'
import {useClassNames} from '../../../../utils'
import {type RCEBlockProps} from './types'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

export const RCEBlock = ({id, text, onContentChange}: RCEBlockProps) => {
  const {actions, enabled} = useEditor(state => ({
    enabled: state.options.enabled,
  }))
  const {
    connectors: {connect, drag},
    actions: {setProp},
    nodeid,
    selected,
  } = useNode(state => ({
    nodeid: state.id,
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
  }, [editable, focusableElem, selected, text])

  const handleRCEFocus = useCallback(() => {
    actions.selectNode(nodeid)
  }, [actions, nodeid])

  const handleChange = useCallback(
    (content: string) => {
      setProp((prps: RCEBlockProps) => {
        prps.text = content
      })
      onContentChange?.(content)
    },
    [onContentChange, setProp],
  )

  const handleKey = useCallback(
    (e: React.KeyboardEvent) => {
      if (editable) {
        if (e.key === 'Escape') {
          e.preventDefault()
          e.stopPropagation()
          setEditable(false)
        } else if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'].includes(e.key)) {
          e.stopPropagation()
        }
      } else if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault()
        setEditable(true)
      }
    },
    [editable],
  )

  if (enabled && selected) {
    return (
      <div
        id={id}
        role="treeitem"
        aria-label={RCEBlock.craft.displayName}
        tabIndex={-1}
        ref={el => {
          if (el) {
            connect(drag(el))
          }
        }}
        className={clazz}
        style={{minWidth: '50%'}}
        onClick={e => setEditable(true)}
        onKeyDown={handleKey}
      >
        <CanvasRce
          ref={rceRef}
          autosave={false}
          defaultContent={text}
          height={300}
          textareaId={`rceblock_text-${id}`}
          onFocus={handleRCEFocus}
          onContentChange={handleChange}
        />
      </div>
    )
  } else {
    return (
      <div
        id={id}
        role="treeitem"
        aria-label={RCEBlock.craft.displayName}
        tabIndex={-1}
        ref={el => {
          if (el) {
            connect(drag(el))
          }
        }}
        className={clazz}
        data-placeholder={I18n.t('Click to enter rich text')}
        dangerouslySetInnerHTML={{__html: text || ''}}
      />
    )
  }
}

RCEBlock.craft = {
  displayName: I18n.t('RCE'),
  defaultProps: {
    id: uid('rce-block', 2),
    text: '',
  },
}
