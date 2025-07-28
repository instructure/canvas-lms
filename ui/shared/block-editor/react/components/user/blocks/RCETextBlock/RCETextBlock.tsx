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
import {type RCETextBlockProps} from './types'
import {RCETextBlockPopup} from './RCETextBlockPopup'
import {RCETextBlockToolbar} from './RCETextBlockToolbar'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

export const RCETextBlock = ({text, width, height, sizeVariant = 'auto'}: RCETextBlockProps) => {
  const {enabled} = useEditor(state => ({
    enabled: state.options.enabled,
  }))
  const {
    connectors: {connect, drag},
    actions: {setProp},
    node,
  } = useNode((n: Node) => ({
    node: n,
    selected: n.events.selected,
  }))
  const [editable, setEditable] = useState(false)
  const [blockRef, setBlockRef] = useState<HTMLDivElement | null>(null)
  const [styl, setStyl] = useState<any>({})

  const clazz = useClassNames(enabled, {empty: !text}, ['block', 'rce-text-block'])

  const setSize = useCallback(() => {
    if (!blockRef) return

    if (sizeVariant === 'auto') {
      setStyl({
        width: 'auto',
        height: 'auto',
      })
      return
    }

    const sty: any = {}
    const unit = sizeVariant === 'percent' ? '%' : 'px'
    if (width) {
      sty.width = `${width}${unit}`
    }
    if (height) {
      sty.height = `${height}${unit}`
    }
    setStyl(sty)
  }, [blockRef, height, sizeVariant, width])

  useEffect(() => {
    setSize()
  }, [setSize])

  const handleCloseRCE = useCallback(() => {
    setEditable(false)
  }, [])

  const handleChange = useCallback(
    (content: string) => {
      setEditable(false)
      setProp((prps: RCETextBlockProps) => {
        prps.text = content
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

  const renderContent = () => {
    if (editable) {
      return (
        <RCETextBlockPopup
          nodeId={node.id}
          content={text || ''}
          onClose={handleCloseRCE}
          onSave={handleChange}
        />
      )
    } else if (text) {
      return <div dangerouslySetInnerHTML={{__html: text || ''}} />
    }
    return null
  }

  if (enabled) {
    return (
      <div
        data-placeholder={I18n.t('type <Enter> to edit rich text')}
        role="treeitem"
        aria-label={RCETextBlock.craft.displayName}
        aria-selected={node.events.selected}
        tabIndex={-1}
        ref={el => {
          el && connect(drag(el))
          setBlockRef(el)
        }}
        className={clazz}
        style={styl}
        onKeyDown={handleKey}
      >
        {renderContent()}
      </div>
    )
  } else {
    return (
      <div
        role="treeitem"
        aria-label={RCETextBlock.craft.displayName}
        tabIndex={-1}
        className={clazz}
        ref={el => setBlockRef(el)}
        style={styl}
        dangerouslySetInnerHTML={{__html: text || ''}}
      />
    )
  }
}

RCETextBlock.craft = {
  displayName: I18n.t('Text'),
  defaultProps: {
    text: '',
    sizeVariant: 'auto',
  },
  related: {
    toolbar: RCETextBlockToolbar,
  },
  custom: {
    isBlock: true,
    isResizable: true,
  },
}
