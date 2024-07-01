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

import React, {useCallback, useState} from 'react'
import {useNode} from '@craftjs/core'
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
import {
  isSelectionAllStyled,
  isElementBold,
  makeSelectionBold,
  unstyleSelection,
  unboldElement,
} from '../../../../utils'
import {ColorModal} from '../../common/ColorModal'
import {type TextBlockProps} from './common'

const TextBlockToolbar = () => {
  const {
    actions: {setProp},
    node,
    props,
  } = useNode(node => ({
    node,
    props: node.data.props,
  }))
  const [colorModalOpen, setColorModalOpen] = useState(false)

  const handleBold = useCallback(() => {
    if (isSelectionAllStyled(isElementBold)) {
      unstyleSelection(isElementBold, unboldElement)
    } else {
      makeSelectionBold()
    }
    setProp((prps: TextBlockProps) => (prps.text = node.dom?.firstElementChild?.innerHTML))
  }, [node.dom, setProp])

  const handleFontSizeChange = useCallback(
    (
      e: React.MouseEvent<ViewOwnProps, MouseEvent>,
      value: MenuItemProps['value'] | MenuItemProps['value'][],
      _selected: MenuItemProps['selected'],
      _args: MenuItem
    ) => {
      setProp((prps: TextBlockProps) => (prps.fontSize = value as string))
    },
    [setProp]
  )

  const handleColorChange = useCallback(
    (color: string) => {
      setProp((prps: TextBlockProps) => (prps.color = color))
      setColorModalOpen(false)
    },
    [setProp]
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
        screenReaderLabel="Bold"
        withBackground={false}
        withBorder={false}
        onClick={handleBold}
      >
        <IconBoldLine size="x-small" />
      </IconButton>
      <IconButton screenReaderLabel="Italic" withBackground={false} withBorder={false}>
        <IconItalicLine size="x-small" />
      </IconButton>
      <IconButton screenReaderLabel="Underline" withBackground={false} withBorder={false}>
        <IconUnderlineLine size="x-small" />
      </IconButton>
      <IconButton screenReaderLabel="Strikethrough" withBackground={false} withBorder={false}>
        <IconStrikethroughLine size="x-small" />
      </IconButton>
      <Menu
        label="Font size"
        trigger={
          <Button size="small">
            <Flex gap="x-small">
              <Text size="small">{props.fontSize || 'Size'}</Text>
              <IconMiniArrowDownLine size="x-small" />
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
        screenReaderLabel="Color"
        disabled={props.variant === 'condensed'}
        onClick={handleColorButtonClick}
      >
        <IconTextColorLine size="x-small" />
      </IconButton>

      <ColorModal
        open={colorModalOpen}
        color={props.color}
        variant="textcolor"
        onClose={handleCloseColorModal}
        onSubmit={handleColorChange}
      />
    </>
  )
}

export {TextBlockToolbar}
