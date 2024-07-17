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
import {useNode} from '@craftjs/core'

import {IconButton} from '@instructure/ui-buttons'
import {Menu, type MenuItemProps, type MenuItem} from '@instructure/ui-menu'
import {Flex} from '@instructure/ui-flex'
import {IconLinkLine, IconButtonAndIconMakerLine, IconBoxLine} from '@instructure/ui-icons'

import {LinkModal} from '../../../editor/LinkModal'
import {ColorModal} from '../../common/ColorModal'
import {IconBackgroundColor} from '../../../../assets/internal-icons'
import {isInstuiButtonColor} from './common'
import type {ButtonBlockProps, ButtonSize, ButtonVariant} from './common'
import {IconPopup} from '../../common/IconPopup'

const ButtonBlockToolbar = () => {
  const {
    actions: {setProp},
    props,
  } = useNode(node => ({
    props: node.data.props,
  }))
  const [linkModalOpen, setLinkModalOpen] = useState(false)
  const [colorModalOpen, setColorModalOpen] = useState(false)

  const handleSizeChange = useCallback(
    (
      _e: React.MouseEvent,
      value: MenuItemProps['value'] | MenuItemProps['value'][],
      _selected: MenuItemProps['selected'],
      _args: MenuItem
    ) => {
      setProp((prps: ButtonBlockProps) => (prps.size = value as ButtonSize))
    },
    [setProp]
  )

  const handleVariantChange = useCallback(
    (
      _e: React.MouseEvent,
      value: MenuItemProps['value'] | MenuItemProps['value'][],
      _selected: MenuItemProps['selected'],
      _args: MenuItem
    ) => {
      if (value === 'condensed' && !isInstuiButtonColor(props.color)) {
        setProp((prps: ButtonBlockProps) => (prps.color = 'primary'))
      }
      setProp((prps: ButtonBlockProps) => (prps.variant = value as ButtonVariant))
    },
    [props.color, setProp]
  )

  const handleColorChange = useCallback(
    (color: string) => {
      setProp((prps: ButtonBlockProps) => (prps.color = color))
      setColorModalOpen(false)
    },
    [setProp]
  )

  const handleLinkButtonClick = useCallback(() => {
    setLinkModalOpen(true)
  }, [])

  const handleCloseLinkModal = useCallback(() => {
    setLinkModalOpen(false)
  }, [])

  const handleColorButtonClick = useCallback(() => {
    setColorModalOpen(true)
  }, [])

  const handleCloseColorModal = useCallback(() => {
    setColorModalOpen(false)
  }, [])

  const handleLinkChange = useCallback(
    (text: string, url: string) => {
      setProp((prps: ButtonBlockProps) => {
        prps.text = text
        prps.href = url
      })
    },
    [setProp]
  )

  return (
    <Flex gap="small">
      <IconButton
        size="small"
        withBackground={false}
        withBorder={false}
        screenReaderLabel="Link"
        onClick={handleLinkButtonClick}
      >
        <IconLinkLine />
      </IconButton>

      <Menu
        placement="bottom"
        trigger={
          <IconButton
            size="small"
            withBackground={false}
            withBorder={false}
            screenReaderLabel="Size"
          >
            <IconBoxLine size="x-small" />
          </IconButton>
        }
        onSelect={handleSizeChange}
      >
        <Menu.Item value="small" type="checkbox" defaultSelected={props.size === 'small'}>
          Small
        </Menu.Item>
        <Menu.Item value="medium" type="checkbox" defaultSelected={props.size === 'medium'}>
          Medium
        </Menu.Item>
        <Menu.Item value="large" type="checkbox" defaultSelected={props.size === 'large'}>
          Large
        </Menu.Item>
      </Menu>

      <Menu
        placement="bottom"
        trigger={
          <IconButton
            size="small"
            withBackground={false}
            withBorder={false}
            screenReaderLabel="Style"
          >
            <IconButtonAndIconMakerLine size="x-small" />
          </IconButton>
        }
        onSelect={handleVariantChange}
      >
        <Menu.Item
          value="condensed"
          type="checkbox"
          defaultSelected={props.variant === 'condensed'}
        >
          Text
        </Menu.Item>
        <Menu.Item value="outlined" type="checkbox" defaultSelected={props.variant === 'outlined'}>
          Outlined
        </Menu.Item>
        <Menu.Item value="filled" type="checkbox" defaultSelected={props.variant === 'filled'}>
          Filled
        </Menu.Item>
      </Menu>

      <IconButton
        size="small"
        withBackground={false}
        withBorder={false}
        screenReaderLabel="Color"
        disabled={props.variant === 'condensed'}
        onClick={handleColorButtonClick}
      >
        <IconBackgroundColor size="x-small" />
      </IconButton>

      <IconPopup />

      <LinkModal
        open={linkModalOpen}
        text={props.text}
        url={props.href}
        onClose={handleCloseLinkModal}
        onSubmit={handleLinkChange}
      />
      <ColorModal
        open={colorModalOpen}
        color={props.color}
        variant="button"
        onClose={handleCloseColorModal}
        onSubmit={handleColorChange}
      />
    </Flex>
  )
}

export {ButtonBlockToolbar}
