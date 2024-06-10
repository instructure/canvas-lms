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

// components/Topbar.js
import React, {useCallback, useState} from 'react'
import {useEditor} from '@craftjs/core'

import {Button, IconButton} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {PreviewModal} from './PreviewModal'
import {IconUndo, IconRedo} from '../../assets/internal-icons'

type TopbarProps = {
  toolboxOpen: boolean
  onToolboxChange: (open: boolean) => void
}

export const Topbar = ({toolboxOpen, onToolboxChange}: TopbarProps) => {
  const {canUndo, canRedo, actions, query} = useEditor((state, qry) => ({
    canUndo: qry.history.canUndo(),
    canRedo: qry.history.canRedo(),
    query: qry,
  }))
  const [previewOpen, setPreviewOpen] = useState(false)

  const handleOpenPreview = useCallback(() => {
    setPreviewOpen(true)
  }, [])

  const handleClosePreview = useCallback(() => {
    setPreviewOpen(false)
  }, [])

  const handleToggleToolbox = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      onToolboxChange(e.target.checked)
    },
    [onToolboxChange]
  )

  return (
    <View as="div" background="secondary">
      <Flex justifyItems="space-between" padding="x-small">
        <Flex.Item>
          <Flex gap="small">
            <Button onClick={handleOpenPreview} size="small">
              Preview
            </Button>
            <IconButton
              screenReaderLabel="Undo"
              onClick={() => actions.history.undo()}
              disabled={!canUndo}
              size="small"
            >
              <IconUndo size="x-small" />
            </IconButton>
            <IconButton
              screenReaderLabel="Redo"
              onClick={() => actions.history.redo()}
              disabled={!canRedo}
              size="small"
            >
              <IconRedo size="x-small" />
            </IconButton>
          </Flex>
        </Flex.Item>
        <Flex.Item>
          <Checkbox
            label="Block Toolbox"
            variant="toggle"
            size="small"
            checked={toolboxOpen}
            onChange={handleToggleToolbox}
          />
          {/* <Button
            size="small"
            withBackground={false}
            onClick={() => {
              console.log(query.serialize())
            }}
          >
            Serialize JSON to console
          </Button> */}
        </Flex.Item>
      </Flex>
      <PreviewModal open={previewOpen} onDismiss={handleClosePreview} />
    </View>
  )
}
