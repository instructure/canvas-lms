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
import ContentEditable from 'react-contenteditable'
import {useEditor, useNode} from '@craftjs/core'
import {
  useClassNames,
  shouldAddNewNode,
  shouldDeleteNode,
  addNewNodeAsNextSibling,
  deleteNodeAndSelectPrevSibling,
  removeLastParagraphTag,
} from '../../../../utils'
import {TextBlockToolbar} from './TextBlockToolbar'
import {type TextBlockProps} from './common'

export const TextBlock = ({
  text = '',
  fontSize = TextBlock.craft.defaultProps.fontSize,
  textAlign = TextBlock.craft.defaultProps.textAlign,
  color = TextBlock.craft.defaultProps.color,
}: TextBlockProps) => {
  const {actions, enabled, query} = useEditor(state => ({
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
  const clazz = useClassNames(enabled, {empty: !text}, 'text-block')
  const focusableElem = useRef<HTMLDivElement | null>(null)

  const [editable, setEditable] = useState(true)
  const lastChar = useRef<string>('')

  useEffect(() => {
    if (editable && selected) {
      focusableElem.current?.focus()
    }
    setEditable(selected)
  }, [editable, focusableElem, selected])

  const handleChange = useCallback(
    e => {
      let html = e.target.value
      // TODO: this does not work as expected in firefox.
      // maybe it's not such a good idea.
      if (html.length === 1) {
        html = `<p>${html}</p>`
      }

      setProp(props => {
        props.text = html
      })
    },
    [setProp]
  )

  const handleKey = useCallback(
    e => {
      if (shouldAddNewNode(e, lastChar.current)) {
        e.preventDefault()
        removeLastParagraphTag(e.currentTarget)
        setProp(props => {
          props.text = e.currentTarget.innerHTML
        })
        addNewNodeAsNextSibling(<TextBlock text="" />, id, actions, query)
      } else if (shouldDeleteNode(e)) {
        e.preventDefault()
        deleteNodeAndSelectPrevSibling(id, actions, query)
      }
      lastChar.current = e.key
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [actions, id, lastChar.current, query]
  )

  if (enabled) {
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
        <ContentEditable
          innerRef={focusableElem}
          data-placeholder="Type something"
          className={clazz}
          disabled={!editable}
          html={text}
          onChange={handleChange}
          onKeyUp={handleKey}
          tagName="div"
          style={{fontSize, textAlign, color}}
        />
      </div>
    )
  } else {
    return (
      <div
        className={clazz}
        style={{fontSize, textAlign, color}}
        dangerouslySetInnerHTML={{__html: text}}
      />
    )
  }
}

TextBlock.craft = {
  displayName: 'Text',
  defaultProps: {
    fontSize: '12pt',
    textAlign: 'start',
    color: 'var(--ic-brand-font-color-dark)',
  },
  related: {
    toolbar: TextBlockToolbar,
  },
}
