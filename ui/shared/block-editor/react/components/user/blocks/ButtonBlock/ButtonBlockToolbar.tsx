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
import {useNode, type Node} from '@craftjs/core'

import {Button, CondensedButton, IconButton} from '@instructure/ui-buttons'
import {Menu, type MenuItemProps, type MenuItem} from '@instructure/ui-menu'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {IconArrowOpenDownLine, IconBoxLine} from '@instructure/ui-icons'
import {type ColorSpec} from '@instructure/canvas-rce'

import {LinkModal} from '../../../editor/LinkModal'
import {ToolbarColor} from '../../common/ToolbarColor'
import type {ButtonBlockProps, ButtonSize, ButtonVariant} from './types'
import {white, black, getContrastingColor, getEffectiveBackgroundColor} from '../../../../utils'
import {IconPopup} from '../../common/IconPopup'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

const ButtonBlockToolbar = () => {
  const {
    actions: {setProp},
    node,
    props,
  } = useNode((n: Node) => ({
    node: n,
    props: n.data.props,
  }))
  const [linkModalOpen, setLinkModalOpen] = useState(false)

  const handleSizeChange = useCallback(
    (
      _e: React.MouseEvent,
      value: MenuItemProps['value'] | MenuItemProps['value'][],
      _selected: MenuItemProps['selected'],
      _args: MenuItem,
    ) => {
      setProp((prps: ButtonBlockProps) => (prps.size = value as ButtonSize))
    },
    [setProp],
  )

  const handleVariantChange = useCallback(
    (
      _e: React.MouseEvent,
      value: MenuItemProps['value'] | MenuItemProps['value'][],
      _selected: MenuItemProps['selected'],
      _args: MenuItem,
    ) => {
      if (value === 'text') {
        setProp((prps: ButtonBlockProps) => {
          prps.background = undefined
          prps.borderColor = undefined
        })
      } else if (value === 'outlined') {
        setProp((prps: ButtonBlockProps) => {
          prps.background = undefined
        })
      }
      setProp((prps: ButtonBlockProps) => (prps.variant = value as ButtonVariant))
    },
    [setProp],
  )

  const handleColorChange = useCallback(
    (newcolors: ColorSpec) => {
      setProp((prps: ButtonBlockProps) => {
        prps.color = newcolors.fgcolor
        prps.background = newcolors.bgcolor
        prps.borderColor = newcolors.bordercolor
      })
    },
    [setProp],
  )

  const handleLinkButtonClick = useCallback(() => {
    setLinkModalOpen(true)
  }, [])

  const handleCloseLinkModal = useCallback(() => {
    setLinkModalOpen(false)
  }, [])

  const handleLinkChange = useCallback(
    (text: string, url: string) => {
      setProp((prps: ButtonBlockProps) => {
        prps.text = text
        prps.href = url
      })
    },
    [setProp],
  )

  const getButtonStyleName = useCallback(() => {
    switch (props.variant) {
      case 'text':
        return I18n.t('Text')
      case 'outlined':
        return I18n.t('Outlined')
      case 'filled':
        return I18n.t('Filled')
      default:
        return ''
    }
  }, [props.variant])

  const getTabsForVariant = useCallback(() => {
    const effbg = getEffectiveBackgroundColor(node.dom)
    const clr = getContrastingColor(props.background || effbg)
    switch (props.variant) {
      case 'outlined':
        return {
          foreground: {
            color: props.color || clr,
            default: clr,
          },
          border: {
            color: props.borderColor,
            default: '#00000000',
          },
          effectiveBgColor: effbg,
        }
      case 'text':
        return {
          foreground: {
            color: props.color || clr,
            default: clr,
          },
          effectiveBgColor: effbg,
        }
      case 'filled':
      default:
        return {
          foreground: {
            color: props.color,
            default: white,
          },
          background: {
            color: props.background,
            default: black,
          },
          border: {
            color: props.borderColor,
            default: '#00000000',
          },
          effectiveBgColor: black,
        }
    }
  }, [node.dom, props.background, props.borderColor, props.color, props.variant])

  return (
    <Flex gap="small">
      <Menu
        placement="bottom"
        trigger={
          <Button
            size="small"
            color="secondary"
            title={I18n.t('Style')}
            themeOverride={{secondaryBackground: '#fff'}}
          >
            <Flex gap="medium">
              <Text>{getButtonStyleName()}</Text>
              <IconArrowOpenDownLine size="x-small" />
            </Flex>
          </Button>
        }
        onSelect={handleVariantChange}
      >
        <Menu.Item value="text" type="checkbox" defaultSelected={props.variant === 'text'}>
          {I18n.t('Text')}
        </Menu.Item>
        <Menu.Item value="outlined" type="checkbox" defaultSelected={props.variant === 'outlined'}>
          {I18n.t('Outlined')}
        </Menu.Item>
        <Menu.Item value="filled" type="checkbox" defaultSelected={props.variant === 'filled'}>
          {I18n.t('Filled')}
        </Menu.Item>
      </Menu>

      <div className="toolbar-separator" />

      <CondensedButton size="small" color="primary" onClick={handleLinkButtonClick}>
        {I18n.t('Button Text/Link*')}
      </CondensedButton>

      <div className="toolbar-separator" />

      <ToolbarColor tabs={getTabsForVariant()} onChange={handleColorChange} />

      <Menu
        placement="bottom"
        trigger={
          <IconButton
            size="small"
            withBackground={false}
            withBorder={false}
            screenReaderLabel={I18n.t('Size')}
            title={I18n.t('Size')}
          >
            <IconBoxLine />
          </IconButton>
        }
        onSelect={handleSizeChange}
      >
        <Menu.Item value="small" type="checkbox" defaultSelected={props.size === 'small'}>
          {I18n.t('Small')}
        </Menu.Item>
        <Menu.Item value="medium" type="checkbox" defaultSelected={props.size === 'medium'}>
          {I18n.t('Medium')}
        </Menu.Item>
        <Menu.Item value="large" type="checkbox" defaultSelected={props.size === 'large'}>
          {I18n.t('Large')}
        </Menu.Item>
      </Menu>

      <IconPopup iconName={props.iconName} />

      <div className="toolbar-separator" />

      <LinkModal
        open={linkModalOpen}
        text={props.text}
        url={props.href}
        onClose={handleCloseLinkModal}
        onSubmit={handleLinkChange}
      />
    </Flex>
  )
}

export {ButtonBlockToolbar}
