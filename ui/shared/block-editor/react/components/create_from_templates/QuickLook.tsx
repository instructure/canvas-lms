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
import type {BlockTemplate} from '../../types'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Modal} from '@instructure/ui-modal'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import BlockEditorView from '../../BlockEditorView'
import {LATEST_BLOCK_DATA_VERSION} from '../../utils/transformations'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('block-editor')

export default function QuickLook({
  template,
  close,
  customize,
}: {
  template?: BlockTemplate
  close: () => void
  customize: () => void
}) {
  const [quickLookWrapperRef, setQuickLookWrapperRef] = useState<HTMLDivElement | null>(null)
  const [quickLookRef, setQuickLookRef] = useState<HTMLDivElement | null>(null)

  const handleModalOpen = useCallback(() => {
    if (quickLookWrapperRef && quickLookRef) {
      requestAnimationFrame(() => {
        const {width, height} = quickLookRef.getBoundingClientRect()
        quickLookWrapperRef.style.height = `${height}px`
        quickLookWrapperRef.style.width = `${width}px`
      })
    }
  }, [quickLookRef, quickLookWrapperRef])

  if (!template) {
    return null
  }

  return (
    <Modal label={I18n.t('Template: Quick Look')} open={true} size="auto" onOpen={handleModalOpen}>
      <Modal.Header>
        <CloseButton placement="end" offset="small" onClick={close} screenReaderLabel="Close" />
        <Heading level="h3">
          {template.name}: {I18n.t('Quick Look')}
        </Heading>
      </Modal.Header>
      <Modal.Body padding="x-small medium medium">
        <Flex direction="column">
          {template.description && (
            <View as="div" margin="0 0 x-small 0">
              <Text size="small" weight="bold">
                {I18n.t('Description')}:
              </Text>
              <Text size="small"> {template.description}</Text>
            </View>
          )}
          <View
            as="div"
            position="relative"
            padding="small"
            borderWidth="small"
            borderRadius="large"
            width="743px" /* 1024 * 0.7 - 26 (margin+padding) */
          >
            <div ref={setQuickLookWrapperRef} style={{height: '100%'}}>
              <div
                ref={setQuickLookRef}
                style={{
                  position: 'relative',
                  width: '1024px',
                  height: 'auto',
                  transform: 'scale(0.7)',
                  transformOrigin: 'top left',
                }}
              >
                {template.node_tree && (
                  <BlockEditorView
                    content={{
                      version: LATEST_BLOCK_DATA_VERSION,
                      blocks: template.node_tree.nodes,
                    }}
                  />
                )}
              </div>
            </div>
          </View>
        </Flex>
      </Modal.Body>
      <Modal.Footer>
        <Button color="secondary" margin="none small" onClick={close}>
          {I18n.t('Close')}
        </Button>
        <Button color="primary" onClick={customize}>
          {I18n.t('Customize')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
