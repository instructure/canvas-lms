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
import {useClassNames} from '../../../../utils'
import {TextBlockToolbar} from './TextBlockToolbar'
import {type TextBlockProps} from './types'

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('block-editor/text-block')

const isAParagraph = (text: string) => /<p>[\s\S]*?<\/p>/s.test(text)

export const TextBlock = ({text = '', fontSize, textAlign, color}: TextBlockProps) => {
  const {enabled} = useEditor(state => ({
    enabled: state.options.enabled,
  }))
  const {
    connectors: {connect, drag},
    actions: {setProp},
    selected,
  } = useNode(state => ({
    id: state.id,
    selected: state.events.selected,
  }))
  const clazz = useClassNames(enabled, {empty: !text}, ['block', 'text-block'])
  const focusableElem = useRef<HTMLDivElement | null>(null)

  const [editable, setEditable] = useState(true)

  useEffect(() => {
    if (editable && selected) {
      focusableElem.current?.focus()
    }
    setEditable(selected)
  }, [editable, focusableElem, selected])

  const handleChange = useCallback(
    e => {
      let html = e.target.value
      if (!isAParagraph(html)) {
        html = `<p>${html}</p>`
      }

      setProp((prps: TextBlockProps) => {
        prps.text = html
      })
    },
    [setProp]
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
          data-placeholder={I18n.t('Type something')}
          className={clazz}
          disabled={!editable}
          html={text}
          onChange={handleChange}
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
  displayName: I18n.t('Text'),
  defaultProps: {
    fontSize: '12pt',
    textAlign: 'initial' as React.CSSProperties['textAlign'],
    color: 'var(--ic-brand-font-color-dark)',
  },
  related: {
    toolbar: TextBlockToolbar,
  },
}
