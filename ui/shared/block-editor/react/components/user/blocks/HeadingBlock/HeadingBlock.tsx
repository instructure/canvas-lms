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

import React, {useCallback, useRef, useState} from 'react'
import ContentEditable from 'react-contenteditable'
import {useEditor, useNode, type Node} from '@craftjs/core'
import {Heading} from '@instructure/ui-heading'
import {TextBlock} from '../TextBlock/TextBlock'
import {useClassNames} from '../../../../utils'
import {HeadingBlockToolbar} from './HeadingBlockToolbar'

import {type HeadingBlockProps, type HeadingLevel} from './types'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

export const HeadingBlock = ({text = '', level, fontSize}: HeadingBlockProps) => {
  const {enabled} = useEditor(state => {
    return {
      enabled: state.options.enabled,
    }
  })
  const {
    connectors: {connect, drag},
    actions: {setProp},
    selected,
    node,
  } = useNode((n: Node) => ({
    selected: n.events.selected,
    node: n,
  }))
  const clazz = useClassNames(enabled, {empty: !text}, ['block', 'heading-block'])
  const focusableElem = useRef<HTMLElement | null>(null)
  const [editable, setEditable] = useState(true) // editable when first added

  const handleChange = useCallback(
    // @ts-expect-error
    e => {
      setProp((props: HeadingBlockProps) => {
        props.text = e.target.value.replace(/<\/?[^>]+(>|$)/g, '')
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
      } else if (!editable && (e.key === 'Enter' || e.key === ' ')) {
        e.preventDefault()
        setEditable(true)
      }
    },
    [editable],
  )

  // @ts-expect-error
  const handleClick = useCallback(_e => {
    setEditable(true)
  }, [])

  const styl: React.CSSProperties = {fontSize}
  if (node.data.props.width) {
    styl.width = `${node.data.props.width}px`
  }
  if (node.data.props.height) {
    styl.height = `${node.data.props.height}px`
  }

  const renderHeading = () => {
    switch (level) {
      case 'h2':
        return <Heading level="h2">{text}</Heading>
      case 'h3':
        return <Heading level="h3">{text}</Heading>
      case 'h4':
        return <Heading level="h4">{text}</Heading>
      default:
        return <Heading level="h2">{text}</Heading>
    }
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
        data-placeholder={`Heading ${level?.replace('h', '')}`}
        className={clazz}
        disabled={!editable}
        html={text}
        style={styl}
        tagName={level}
        onChange={handleChange}
        onClick={handleClick}
        onKeyDown={selected ? handleKey : undefined}
        onBlur={() => setEditable(false)}
      />
    )
  } else {
    return (
      <div
        role="treeitem"
        aria-label={TextBlock.craft.displayName}
        aria-selected={selected}
        tabIndex={-1}
      >
        {renderHeading()}
      </div>
    )
  }
}

HeadingBlock.craft = {
  displayName: I18n.t('Heading'),
  defaultProps: {
    text: '',
    level: 'h2' as HeadingLevel,
  },
  related: {
    toolbar: HeadingBlockToolbar,
  },
  custom: {
    isResizable: true,
    isBlock: true,
  },
}
