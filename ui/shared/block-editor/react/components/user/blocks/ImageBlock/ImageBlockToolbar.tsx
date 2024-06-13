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
import {Flex} from '@instructure/ui-flex'
import {Menu, type MenuItemProps, type MenuItem} from '@instructure/ui-menu'
import {Text} from '@instructure/ui-text'
import {IconArrowOpenDownLine, IconUploadLine} from '@instructure/ui-icons'
import {type ViewOwnProps} from '@instructure/ui-view'

import {UploadFileModal} from '../../../../FileUpload/UploadFileModal'
import {IconSizePopup} from './ImageSizePopup'

const ImageBlockToolbar = () => {
  const {
    actions: {setProp},
    props,
  } = useNode(node => ({
    props: node.data.props,
  }))
  const [showUploadModal, setShowUploadModal] = useState(false)

  const handleConstraintChange = useCallback(
    (
      e: React.MouseEvent<ViewOwnProps, MouseEvent>,
      value: MenuItemProps['value'] | MenuItemProps['value'][],
      _selected: MenuItemProps['selected'],
      _args: MenuItem
    ) => {
      setProp(prps => (prps.constraint = value))
    },
    [setProp]
  )

  const handleShowUploadModal = useCallback(() => {
    setShowUploadModal(true)
  }, [])

  const handleDismissModal = useCallback(() => {
    setShowUploadModal(false)
  }, [])

  const handleSave = useCallback(
    (imageURL: string | null) => {
      setProp(prps => (prps.src = imageURL))
      setShowUploadModal(false)
    },
    [setProp]
  )

  return (
    <Flex gap="small">
      <IconButton
        screenReaderLabel="Upload Image"
        withBackground={false}
        withBorder={false}
        onClick={handleShowUploadModal}
      >
        <IconUploadLine size="x-small" />
      </IconButton>
      <Menu
        label="Constraint"
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
          selected={props.constraint === 'cover'}
        >
          <Text size="small">Cover</Text>
        </Menu.Item>
        <Menu.Item
          type="checkbox"
          value="contain"
          onSelect={handleConstraintChange}
          selected={props.constraint === 'contain'}
        >
          <Text size="small">Contain</Text>
        </Menu.Item>
      </Menu>

      <IconSizePopup width={props.width} height={props.height} />

      <UploadFileModal
        imageUrl={null}
        open={showUploadModal}
        variant={props.variant}
        onDismiss={handleDismissModal}
        onSave={handleSave}
      />
    </Flex>
  )
}

export {ImageBlockToolbar}
