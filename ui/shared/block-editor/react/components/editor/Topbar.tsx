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
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

export type TopbarProps = {
  toolboxOpen: boolean
  onToolboxChange: (open: boolean) => void
}

export const Topbar = ({toolboxOpen, onToolboxChange}: TopbarProps) => {
  const {canUndo, canRedo, actions} = useEditor((state, qry) => ({
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
    [onToolboxChange],
  )

  return (
    <View as="div" background="secondary" className="topbar" tabIndex={-1}>
      <Flex justifyItems="space-between" padding="x-small">
        <Flex.Item>
          <Flex gap="small">
            <Button onClick={handleOpenPreview} size="small" data-testid="topbar-button-preview">
              Preview
            </Button>
            <IconButton
              screenReaderLabel={I18n.t('Undo')}
              title={I18n.t('Undo')}
              onClick={() => actions.history.undo()}
              disabled={!canUndo}
              size="small"
              data-testid="topbar-button-undo"
            >
              <IconUndo size="x-small" />
            </IconButton>
            <IconButton
              screenReaderLabel={I18n.t('Redo')}
              title={I18n.t('Redo')}
              onClick={() => actions.history.redo()}
              disabled={!canRedo}
              size="small"
              data-testid="topbar-button-redo"
            >
              <IconRedo size="x-small" />
            </IconButton>
          </Flex>
        </Flex.Item>
        <Flex.Item>
          <Checkbox
            id="toolbox-toggle"
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
      {previewOpen ? <PreviewModal open={previewOpen} onDismiss={handleClosePreview} /> : null}
    </View>
  )
}
