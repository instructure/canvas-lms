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
import {useNode, type Node} from '@craftjs/core'
import {Button, IconButton} from '@instructure/ui-buttons'
import {
  IconBoldLine,
  IconItalicLine,
  IconUnderlineLine,
  IconStrikethroughLine,
  IconMiniArrowDownLine,
  IconTextColorLine,
} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import {Menu, type MenuItemProps, type MenuItem} from '@instructure/ui-menu'
import {Text} from '@instructure/ui-text'
import {type ViewOwnProps} from '@instructure/ui-view'
import {isCaretAtBoldText, isCaretAtStyledText, getCaretPosition} from '../../../../utils'
import {ColorModal} from '../../common/ColorModal'
import {type TextBlockProps} from './types'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

// NOTE: This component uses document.execCommand which is deprecated, but there
//       (1) is still supported by browsers, and
//       (2) no reasonable alternative exists for the functionality it provides.
// Should it ever go away, we'll deal with the consequences then (which will mean writing
// a boatload of code to replace a 1-liner.)

const TextBlockToolbar = () => {
  const {
    actions: {setProp},
    node,
    props,
  } = useNode((n: Node) => ({
    node: n,
    props: n.data.props as TextBlockProps,
  }))
  const [colorModalOpen, setColorModalOpen] = useState(false)
  const [editableNode, setEditableNode] = useState(node.dom?.querySelector('[contenteditable]'))
  const [caretPos, setCaretPos] = useState(() => {
    return editableNode ? getCaretPosition(editableNode) : 0
  })
  const [isBold, setIsBold] = useState(isCaretAtBoldText())
  const [isItalic, setIsItalic] = useState(isCaretAtStyledText('font-style', 'italic'))
  const [isUnderline, setIsUnderline] = useState(
    isCaretAtStyledText('text-decoration-line', 'underline'),
  )
  const [isStrikeThrough, setIsStrikeThrough] = useState(
    isCaretAtStyledText('text-decoration-line', 'line-through'),
  )

  useEffect(() => {
    setEditableNode(node.dom?.querySelector('[contenteditable]'))
  }, [node.dom])

  useEffect(() => {
    const handleSelectionChange = () => {
      if (editableNode) setCaretPos(getCaretPosition(editableNode))
    }

    document.addEventListener('selectionchange', handleSelectionChange)
    return () => {
      document.removeEventListener('selectionchange', handleSelectionChange)
    }
  }, [editableNode])

  useEffect(() => {
    setIsBold(isCaretAtBoldText())
    setIsItalic(isCaretAtStyledText('font-style', 'italic'))
    setIsUnderline(isCaretAtStyledText('text-decoration-line', 'underline'))
    setIsStrikeThrough(isCaretAtStyledText('text-decoration-line', 'line-through'))
  }, [caretPos])

  const handleBold = useCallback(() => {
    document.execCommand('bold')
    setIsBold(isCaretAtBoldText())
  }, [])

  const handleItalic = useCallback(() => {
    document.execCommand('italic')
    setIsItalic(isCaretAtStyledText('font-style', 'italic'))
  }, [])

  const handleUnderline = useCallback(() => {
    document.execCommand('underline')
    setIsUnderline(isCaretAtStyledText('text-decoration-line', 'underline'))
  }, [])

  const handleStrikeThrough = useCallback(() => {
    document.execCommand('strikeThrough')
    setIsStrikeThrough(isCaretAtStyledText('text-decoration-line', 'line-through'))
  }, [])

  const handleFontSizeChange = useCallback(
    (
      _e: any,
      value: MenuItemProps['value'] | MenuItemProps['value'][],
      _selected: MenuItemProps['selected'],
      _args: MenuItem,
    ) => {
      setProp((prps: TextBlockProps) => (prps.fontSize = value as string))
    },
    [setProp],
  )

  const handleColorChange = useCallback(
    (color: string) => {
      setProp((prps: TextBlockProps) => (prps.color = color))
      setColorModalOpen(false)
    },
    [setProp],
  )

  const handleColorButtonClick = useCallback(() => {
    setColorModalOpen(true)
  }, [])

  const handleCloseColorModal = useCallback(() => {
    setColorModalOpen(false)
  }, [])

  return (
    <>
      <IconButton
        screenReaderLabel={I18n.t('Bold')}
        title={I18n.t('Bold')}
        size="small"
        withBackground={false}
        withBorder={isBold}
        onClick={handleBold}
      >
        <IconBoldLine />
      </IconButton>
      <IconButton
        screenReaderLabel={I18n.t('Italic')}
        title={I18n.t('Italic')}
        size="small"
        withBackground={false}
        withBorder={isItalic}
        onClick={handleItalic}
      >
        <IconItalicLine />
      </IconButton>
      <IconButton
        screenReaderLabel={I18n.t('Underline')}
        title={I18n.t('Underline')}
        size="small"
        withBackground={false}
        withBorder={isUnderline}
        onClick={handleUnderline}
      >
        <IconUnderlineLine />
      </IconButton>
      <IconButton
        screenReaderLabel={I18n.t('Strikethrough')}
        title={I18n.t('Strikethrough')}
        size="small"
        withBackground={false}
        withBorder={isStrikeThrough}
        onClick={handleStrikeThrough}
      >
        <IconStrikethroughLine />
      </IconButton>
      <Menu
        label="Font size"
        trigger={
          <Button size="small">
            <Flex gap="x-small">
              <Text size="small">{props.fontSize || I18n.t('Size')}</Text>
              <IconMiniArrowDownLine />
            </Flex>
          </Button>
        }
      >
        {['8pt', '10pt', '12pt', '14pt', '18pt', '24pt', '36pt'].map(size => (
          <Menu.Item
            type="checkbox"
            key={size}
            value={size}
            onSelect={handleFontSizeChange}
            selected={props.fontSize === size}
          >
            <Text size="small">{size}</Text>
          </Menu.Item>
        ))}
      </Menu>

      <IconButton
        size="small"
        withBackground={false}
        withBorder={false}
        screenReaderLabel={I18n.t('Color')}
        title={I18n.t('Color')}
        onClick={handleColorButtonClick}
      >
        <IconTextColorLine />
      </IconButton>

      <ColorModal
        open={colorModalOpen}
        color={props.color || 'var(--ic-brand-font-color-dark)'}
        variant="textcolor"
        onClose={handleCloseColorModal}
        onSubmit={handleColorChange}
      />
    </>
  )
}

export {TextBlockToolbar}
