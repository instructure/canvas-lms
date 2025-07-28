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

import React, {useCallback, useRef, useState} from 'react'
import CanvasRce from '@canvas/rce/react/CanvasRce'
import {CloseButton, Button, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {type ViewProps} from '@instructure/ui-view'
import {px} from '@instructure/ui-utils'
import {IconFullScreenLine, IconExitFullScreenLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

type RCETextBlockPopupProps = {
  nodeId: string
  content: string
  onClose: () => void
  onSave: (content: string) => void
}

const RCETextBlockPopup = ({nodeId, content, onClose, onSave}: RCETextBlockPopupProps) => {
  const [mountNode] = useState<HTMLElement | null>(() => {
    let elem = document.getElementById('rce-text-block-popup')
    if (elem === null) {
      elem = document.createElement('div')
      elem.id = 'rce-text-block-popup'
      document.body.appendChild(elem)
    }
    return elem
  })
  const rceRef = useRef<any | null>(null) // the RceWrapper
  const [isFullscreen, setFullscreen] = useState(false)
  const [rceHeight, setRceHeight] = useState('300px')
  const [currentContent, setCurrentContent] = useState(content)
  const modalBodyRef = useRef<HTMLElement | null>(null)

  const handleSave = useCallback(
    (e: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps>) => {
      e.stopPropagation()
      const html = rceRef.current?.getCode()
      onSave(html)
    },
    [onSave],
  )

  const handleClose = useCallback(
    (
      e:
        | React.UIEvent
        | React.FocusEvent
        | React.KeyboardEvent<ViewProps>
        | React.MouseEvent<ViewProps>,
    ) => {
      e.stopPropagation()
      // The RCE may open popups (e.g. ColorPopup) that need to know to close
      const evt = new CustomEvent('rce-text-block-popup-close', {})
      document.dispatchEvent(evt)
      onClose()
    },
    [onClose],
  )

  const handleFullscreen = useCallback(() => {
    const newFS = !isFullscreen
    setFullscreen(newFS)
    requestAnimationFrame(() => {
      let newHt = 300
      if (newFS && modalBodyRef.current?.clientHeight) {
        newHt = modalBodyRef.current.clientHeight
        const padding = window
          .getComputedStyle(modalBodyRef.current)
          .getPropertyValue('padding-top')
        const pxpadding = px(padding)
        newHt -= 2 * pxpadding
      }
      const pxHt = `${newHt}px`
      setRceHeight(pxHt)
      // Add null check to prevent errors in test environment
      if (rceRef.current && typeof rceRef.current.mceInstance === 'function') {
        try {
          const ed = rceRef.current.mceInstance()
          if (ed) {
            ed.getContainer().style.height = pxHt
            ed.fire('ResizeEditor')
          }
        } catch (error) {
          // Silently handle errors in test environment
          console.debug('Failed to resize RCE editor:', error)
        }
      }
    })
  }, [isFullscreen])

  const handleKey = useCallback(
    (e: any) => {
      if (e.key === 'Escape') {
        if (!mountNode?.contains(e.target)) {
          e.stopPropagation()
        } else if (isFullscreen) {
          handleFullscreen()
          e.stopPropagation()
        }
      }
    },
    [handleFullscreen, isFullscreen, mountNode],
  )

  const handleContentChange = useCallback((newcontent: string) => {
    setCurrentContent(newcontent)
  }, [])

  const renderFullscreenButton = () => {
    const fullscreen = isFullscreen ? I18n.t('Exit Fullscreen') : I18n.t('Fullscreen')
    return (
      <IconButton
        data-testid="rce-fullscreen-btn"
        color="secondary"
        title={fullscreen}
        onClick={_event => {
          handleFullscreen()
        }}
        screenReaderLabel={fullscreen}
        withBackground={false}
        withBorder={false}
      >
        {isFullscreen ? <IconExitFullScreenLine /> : <IconFullScreenLine />}
      </IconButton>
    )
  }

  return (
    <Modal
      open={true}
      mountNode={mountNode}
      shouldCloseOnDocumentClick={false}
      size={isFullscreen ? 'fullscreen' : 'auto'}
      label={I18n.t('Edit Text')}
      onKeyDown={handleKey}
    >
      <Modal.Header>
        <Heading level="h2">{I18n.t('Edit Text')}</Heading>
        <CloseButton
          placement="end"
          screenReaderLabel={I18n.t('Close Editor')}
          onClick={handleClose}
        />
      </Modal.Header>
      <Modal.Body elementRef={el => (modalBodyRef.current = el as HTMLElement)}>
        <CanvasRce
          key={isFullscreen ? 'fullscreen' : 'normal'}
          ref={rceRef}
          autosave={false}
          defaultContent={currentContent}
          onContentChange={handleContentChange}
          height={rceHeight}
          textareaId={`RCETextBlock_text__${nodeId}`}
          variant="text-block"
        />
      </Modal.Body>
      <Modal.Footer>
        <Flex gap="small" justifyItems="space-between">
          {renderFullscreenButton()}
          <div>
            <Button onClick={handleClose}>{I18n.t('Cancel')}</Button>
            <Button color="primary" margin="0 0 0 small" onClick={handleSave}>
              {I18n.t('Save')}
            </Button>
          </div>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}

export {RCETextBlockPopup}
