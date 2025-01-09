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

import {Button, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {View, type ViewOwnProps} from '@instructure/ui-view'
import {Menu, type MenuItemProps, type MenuItem} from '@instructure/ui-menu'
import {Text} from '@instructure/ui-text'
import {IconArrowOpenDownLine, IconTextareaLine, IconUploadLine} from '@instructure/ui-icons'
import {IconResize} from '../../../../assets/internal-icons'

import {type ImageBlockProps, type ImageConstraint} from './types'
import {type SizeVariant} from '../../../editor/types'
import {AddImageModal} from '../../../editor/AddImageModal'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Popover} from '@instructure/ui-popover'
import {TextArea} from '@instructure/ui-text-area'

import {changeSizeVariant} from '../../../../utils/resizeHelpers'

const I18n = createI18nScope('block-editor')

const ImageBlockToolbar = () => {
  const {
    actions: {setProp},
    node,
    props,
  } = useNode((n: Node) => ({
    node: n,
    props: n.data.props,
  }))
  const [showUploadModal, setShowUploadModal] = useState(false)

  const handleConstraintChange = useCallback(
    (
      _e: any,
      value: MenuItemProps['value'] | MenuItemProps['value'][],
      _selected: MenuItemProps['selected'],
      _args: MenuItem,
    ) => {
      const constraint = value as ImageConstraint | 'aspect-ratio'
      if (constraint === 'aspect-ratio') {
        setProp((prps: ImageBlockProps) => {
          prps.constraint = 'cover'
          prps.maintainAspectRatio = true
        })
      } else {
        setProp((prps: ImageBlockProps) => {
          prps.constraint = constraint
          prps.maintainAspectRatio = false
        })
      }
    },
    [setProp],
  )

  const handleChangeSzVariant = useCallback(
    (
      _e: any,
      value: MenuItemProps['value'] | MenuItemProps['value'][],
      _selected: MenuItemProps['selected'],
      _args: MenuItem,
    ) => {
      setProp((prps: ImageBlockProps) => {
        prps.sizeVariant = value as SizeVariant

        if (node.dom) {
          const {width, height} = changeSizeVariant(node.dom, value as SizeVariant)
          prps.width = width
          prps.height = height
        }
      })
    },
    [node.dom, setProp],
  )

  const handleShowUploadModal = useCallback(() => {
    setShowUploadModal(true)
  }, [])

  const handleDismissModal = useCallback(() => {
    setShowUploadModal(false)
  }, [])

  const handleSave = useCallback(
    (imageURL: string | null, alt: string) => {
      setProp((prps: ImageBlockProps) => {
        prps.src = imageURL || undefined
        prps.alt = alt
      })
      setShowUploadModal(false)
    },
    [setProp],
  )

  const handleAltChange = useCallback(
    (e: React.ChangeEvent<HTMLTextAreaElement>) => {
      setProp((prps: ImageBlockProps) => {
        prps.alt = e.target.value
      })
    },
    [setProp],
  )

  const [showingAltTextMenu, setShowingAltTextMenu] = useState(false)

  return (
    <Flex gap="small">
      <IconButton
        screenReaderLabel={I18n.t('Upload Image')}
        title={I18n.t('Upload Image')}
        withBackground={false}
        withBorder={false}
        onClick={handleShowUploadModal}
        data-testid="upload-image-button"
      >
        <IconUploadLine />
      </IconButton>
      <Menu
        label={I18n.t('Constraint')}
        trigger={
          <Button size="small">
            <Flex gap="small">
              <Text size="small">Constraint</Text>
              <IconArrowOpenDownLine size="x-small" />
            </Flex>
          </Button>
        }
      >
        <Menu.Item
          type="checkbox"
          value="cover"
          onSelect={handleConstraintChange}
          selected={!props.maintainAspectRatio && props.constraint === 'cover'}
        >
          <Text size="small">{I18n.t('Cover')}</Text>
        </Menu.Item>
        <Menu.Item
          type="checkbox"
          value="contain"
          onSelect={handleConstraintChange}
          selected={!props.maintainAspectRatio && props.constraint === 'contain'}
        >
          <Text size="small">{I18n.t('Contain')}</Text>
        </Menu.Item>
        <Menu.Item
          type="checkbox"
          value="aspect-ratio"
          onSelect={handleConstraintChange}
          selected={props.maintainAspectRatio}
        >
          <Text size="small">{I18n.t('Match Aspect Ratio')}</Text>
        </Menu.Item>
      </Menu>

      <Menu
        label={I18n.t('Sizing')}
        trigger={
          <IconButton
            size="small"
            withBackground={false}
            withBorder={false}
            screenReaderLabel={I18n.t('Image Size')}
            title={I18n.t('Image Size')}
          >
            <IconResize size="x-small" />
          </IconButton>
        }
      >
        <Menu.Item
          type="checkbox"
          value="auto"
          selected={props.sizeVariant === 'auto' || props.sizeVariant === undefined}
          onSelect={handleChangeSzVariant}
        >
          <Text size="small">{I18n.t('Auto')}</Text>
        </Menu.Item>
        <Menu.Item
          type="checkbox"
          value="pixel"
          selected={props.sizeVariant === 'pixel'}
          onSelect={handleChangeSzVariant}
        >
          <Text size="small">{I18n.t('Fixed size')}</Text>
        </Menu.Item>
        <Menu.Item
          type="checkbox"
          value="percent"
          selected={props.sizeVariant === 'percent'}
          onSelect={handleChangeSzVariant}
        >
          <Text size="small">{I18n.t('Percent size')}</Text>
        </Menu.Item>
      </Menu>

      <Popover
        isShowingContent={showingAltTextMenu}
        onShowContent={_e => {
          setShowingAltTextMenu(true)
        }}
        onHideContent={_e => {
          setShowingAltTextMenu(false)
        }}
        on="click"
        renderTrigger={
          <IconButton
            data-testid="alt-text-button"
            size="small"
            withBackground={false}
            withBorder={false}
            screenReaderLabel={I18n.t('Image Description')}
            title={I18n.t('Image Description')}
          >
            <IconTextareaLine size="x-small" />
          </IconButton>
        }
      >
        <View padding="small" as="div">
          <TextArea
            label={I18n.t('Alt Text')}
            placeholder={I18n.t('Image Description')}
            value={props.alt}
            onChange={handleAltChange}
          />
        </View>
      </Popover>

      <AddImageModal open={showUploadModal} onSubmit={handleSave} onDismiss={handleDismissModal} />
    </Flex>
  )
}

export {ImageBlockToolbar}
