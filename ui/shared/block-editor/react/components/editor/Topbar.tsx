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

import {Button} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {PreviewModal} from './PreviewModal'

type TopbarProps = {
  onOpenToolbox: () => void
}

export const Topbar = ({onOpenToolbox}: TopbarProps) => {
  const {actions, query, enabled} = useEditor(state => ({
    enabled: state.options.enabled,
  }))
  const [previewOpen, setPreviewOpen] = useState(false)

  const handleOpenPreview = useCallback(() => {
    setPreviewOpen(true)
  }, [])

  const handleClosePreview = useCallback(() => {
    setPreviewOpen(false)
  }, [])

  return (
    <View as="div" background="secondary">
      <Flex justifyItems="space-between" padding="x-small">
        <Flex.Item>
          <Button onClick={handleOpenPreview} size="small">
            Preview
          </Button>
        </Flex.Item>
        <Flex.Item>
          <Button onClick={onOpenToolbox} margin="0 small 0 0" size="small" withBackground={false}>
            Open Toolbox
          </Button>
          <Button
            size="small"
            withBackground={false}
            onClick={() => {
              console.log(query.serialize())
            }}
          >
            Serialize JSON to console
          </Button>
        </Flex.Item>
      </Flex>
      <PreviewModal open={previewOpen} onDismiss={handleClosePreview} />
    </View>
  )
}
