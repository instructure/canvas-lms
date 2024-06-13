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
import React, {useCallback, useEffect, useMemo, useState} from 'react'
import {useEditor} from '@craftjs/core'
import {CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {View} from '@instructure/ui-view'
import BlockEditorView from '../../BlockEditorView'

type ViewSize = 'desktop' | 'tablet' | 'mobile'

type PreviewModalProps = {
  open: boolean
  onDismiss: () => void
}
const PreviewModal = ({open, onDismiss}: PreviewModalProps) => {
  const {query} = useEditor()
  const [viewSize, setViewSize] = useState<ViewSize>('desktop')
  const [container, setContainer] = useState<Element | null>(null)

  const handleKey = useCallback(
    (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        onDismiss()
      }
    },
    [onDismiss]
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
    <Modal open={open} size="fullscreen" label="Preview">
      <Modal.Header>
        <Heading level="h2">Preview</Heading>
        <CloseButton placement="end" offset="small" onClick={onDismiss} screenReaderLabel="Close" />
      </Modal.Header>
      <Modal.Body>
        <View as="div">
          <div style={{position: 'sticky', top: 0}}>
            <RadioInputGroup
              layout="columns"
              name="uiVersion"
              value={viewSize}
              onChange={handleViewSizeChange}
              description="View Size"
            >
              <RadioInput value="desktop" label="Desktop" />
              <RadioInput value="tablet" label="Tablet" />
              <RadioInput value="mobile" label="Mobile" />
            </RadioInputGroup>
          </div>
          <View
            elementRef={el => setContainer(el)}
            as="div"
            className={`block-editor-view ${viewSize}`}
            maxWidth={getViewWidth()}
            shadow="resting"
            padding="0"
            margin="0 auto"
          >
            <BlockEditorView content={query.serialize()} />
          </View>
        </View>
      </Modal.Body>
    </Modal>
  )
}
export {PreviewModal}
