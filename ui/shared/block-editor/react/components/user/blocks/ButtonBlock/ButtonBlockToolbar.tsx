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

import {IconButton} from '@instructure/ui-buttons'
import {Menu, type MenuItemProps, type MenuItem} from '@instructure/ui-menu'
import {Flex} from '@instructure/ui-flex'
import {
  IconLinkLine,
  IconTextBackgroundColorLine,
  IconButtonAndIconMakerLine,
  IconBoxLine,
} from '@instructure/ui-icons'

import {IconBlockSettings} from '../IconBlock'
import {LinkModal} from '../../../editor/LinkModal'
import {ColorModal} from './ColorModal'

import {isInstuiButtonColor} from './common'
import type {ButtonBlockProps, ButtonSize, ButtonVariant} from './common'

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
    (
      _e: React.MouseEvent,
      value: MenuItemProps['value'] | MenuItemProps['value'][],
      _selected: MenuItemProps['selected'],
      _args: MenuItem
    ) => {
      if (value === 'custom') {
        setColorModalOpen(true)
      } else {
        setProp((prps: ButtonBlockProps) => (prps.color = value as string))
      }
    },
    [setProp]
  )

  const handleCustomColorChange = useCallback(
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

      <Menu
        placement="bottom"
        trigger={
          <IconButton
            size="small"
            withBackground={false}
            withBorder={false}
            screenReaderLabel="Color"
            disabled={props.variant === 'condensed'}
          >
            <IconTextBackgroundColorLine size="x-small" />
          </IconButton>
        }
        onSelect={handleColorChange}
      >
        <Menu.Item value="primary" type="checkbox" defaultSelected={props.color === 'primary'}>
          Primary
        </Menu.Item>
        <Menu.Item value="secondary" type="checkbox" defaultSelected={props.color === 'secondary'}>
          Secondary
        </Menu.Item>
        <Menu.Item value="success" type="checkbox" defaultSelected={props.color === 'success'}>
          Success
        </Menu.Item>
        <Menu.Item value="danger" type="checkbox" defaultSelected={props.color === 'danger'}>
          Danger
        </Menu.Item>
        <Menu.Item
          value="primary-inverse"
          type="checkbox"
          defaultSelected={props.color === 'primary-inverse'}
        >
          Primary Inverse
        </Menu.Item>
        <Menu.Item
          value="custom"
          type="checkbox"
          defaultSelected={!isInstuiButtonColor(props.color)}
        >
          Custom
        </Menu.Item>
      </Menu>

      {/*
      <View as="div" margin="small">
        <RadioInputGroup
          disabled={props.variant === 'condensed'}
          name="color"
          defaultValue={isInstuiButtonColor(props.color) ? props.color : 'custom'}
          description="Color"
          onChange={handleButtonColorChange}
        >
          <RadioInput value="primary" label="Primary" />
          <RadioInput value="secondary" label="Secondary" />
          <RadioInput value="success" label="Success" />
          <RadioInput value="danger" label="Danger" />
          <RadioInput value="primary-inverse" label="Primary Inverse" />
          <RadioInput value="custom" label="Custom" />
        </RadioInputGroup>
      </View>


      {!isInstuiButtonColor(props.color) && (
        <View as="div" margin="small">

        </View>

      )}
      <IconBlockSettings />
                          */}
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
        onClose={handleCloseColorModal}
        onSubmit={handleCustomColorChange}
      />
    </Flex>
  )
}

export {ButtonBlockToolbar}
