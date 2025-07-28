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
import {useEditor, useNode, type Node} from '@craftjs/core'
import {useClassNames} from '../../../../utils'
import {TextBlockToolbar} from './TextBlockToolbar'
import {type TextBlockProps} from './types'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

const isAParagraph = (text: string) => /<p>[\s\S]*?<\/p>/s.test(text)

export const TextBlock = ({text = '', fontSize, textAlign, color}: TextBlockProps) => {
  const {enabled} = useEditor(state => ({
    enabled: state.options.enabled,
  }))
  const {
    connectors: {connect, drag},
    actions: {setProp},
    selected,
    node,
  } = useNode((n: Node) => ({
    selected: n.events.selected,
    node: n,
  }))
  const clazz = useClassNames(enabled, {empty: !text}, ['block', 'text-block'])
  const focusableElem = useRef<HTMLElement | null>(null)
  const [editable, setEditable] = useState(true)

  const handleChange = useCallback(
    // @ts-expect-error
    e => {
      let html = e.target.value
      if (!isAParagraph(html)) {
        html = `<p>${html}</p>`
      }

      setProp((prps: TextBlockProps) => {
        prps.text = html
      })
    },
    [setProp],
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

  const styl: React.CSSProperties = {fontSize, textAlign, color}
  if (node.data.props.width) {
    styl.width = `${node.data.props.width}px`
  }
  if (node.data.props.height) {
    styl.height = `${node.data.props.height}px`
  }

  if (enabled) {
    return (
      <ContentEditable
        role="treeitem"
        aria-label={TextBlock.craft.displayName}
        aria-selected={selected}
        tabIndex={-1}
        innerRef={(el: HTMLElement) => {
          if (el) {
            connect(drag(el))
          }
          focusableElem.current = el
        }}
        data-placeholder={I18n.t('Type something')}
        className={clazz}
        disabled={!editable}
        html={text}
        tagName="div"
        style={styl}
        onChange={handleChange}
        onClick={e => setEditable(true)}
        onKeyDown={selected ? handleKey : undefined}
        onBlur={() => {
          setEditable(false)
        }}
      />
    )
  } else {
    return (
      <div
        role="treeitem"
        aria-label={TextBlock.craft.displayName}
        aria-selected={selected}
        tabIndex={-1}
        className={clazz}
        style={styl}
        dangerouslySetInnerHTML={{__html: text}}
      />
    )
  }
}

TextBlock.craft = {
  displayName: I18n.t('Text'),
  defaultProps: {
    fontSize: '12pt',
    textAlign: 'initial' as React.CSSProperties['textAlign'],
    color: 'var(--ic-brand-font-color-dark)',
  },
  related: {
    toolbar: TextBlockToolbar,
  },
  custom: {
    isResizable: true,
    isBlock: true,
  },
}
