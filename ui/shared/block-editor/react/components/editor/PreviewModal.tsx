/*
//  * Copyright (C) 2024 - present Instructure, Inc.
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
import {useEditor} from '@craftjs/core'
import {CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {View} from '@instructure/ui-view'
import BlockEditorView from '../../BlockEditorView'
import {LATEST_BLOCK_DATA_VERSION} from '../../utils/transformations'

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('block-editor')

type ViewSize = 'desktop' | 'tablet' | 'mobile'

type PreviewModalProps = {
  open: boolean
  onDismiss: () => void
}
const PreviewModal = ({open, onDismiss}: PreviewModalProps) => {
  const {query} = useEditor()
  const [viewSize, setViewSize] = useState<ViewSize>('desktop')

  const handleKey = useCallback(
    (event: KeyboardEvent) => {
      if (open && event.key === 'Escape') {
        onDismiss()
      }
    },
    [onDismiss, open]
  )

  useEffect(() => {
    document.addEventListener('keydown', handleKey)
    return () => {
      document.removeEventListener('keydown', handleKey)
    }
  }, [handleKey])
  const handleViewSizeChange = useCallback((_: unknown, value: string) => {
    setViewSize(value as ViewSize)
  }, [])
  const getViewWidth = () => {
    switch (viewSize) {
      case 'desktop':
        return '1026px'
      case 'tablet':
        return '768px'
      case 'mobile':
        return '320px'
    }
  }
  return (
    <Modal open={open} size="fullscreen" label={I18n.t('Preview')}>
      <Modal.Header>
        <Heading level="h2">{I18n.t('Preview')}</Heading>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onDismiss}
          screenReaderLabel={I18n.t('Close')}
        />
      </Modal.Header>
      <Modal.Body>
        <View as="div">
          <div style={{position: 'sticky', top: 0}}>
            <RadioInputGroup
              layout="columns"
              name="uiVersion"
              value={viewSize}
              onChange={handleViewSizeChange}
              description={I18n.t('View Size')}
            >
              <RadioInput value="desktop" label={I18n.t('Desktop')} />
              <RadioInput value="tablet" label={I18n.t('Tablet')} />
              <RadioInput value="mobile" label={I18n.t('Mobile')} />
            </RadioInputGroup>
          </div>
          <View
            as="div"
            className={`block-editor-view ${viewSize}`}
            width={getViewWidth()}
            shadow="resting"
            padding="0"
            margin="0 auto"
          >
            <BlockEditorView
              content={{version: LATEST_BLOCK_DATA_VERSION, blocks: query.serialize()}}
            />
          </View>
        </View>
      </Modal.Body>
    </Modal>
  )
}
export {PreviewModal}
