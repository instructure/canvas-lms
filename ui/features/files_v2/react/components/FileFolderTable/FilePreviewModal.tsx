/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {useState, useEffect, useRef} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {IconButton, Button} from '@instructure/ui-buttons'
import {Modal} from '@instructure/ui-modal'
import {FilePreviewTray} from './FilePreviewTray'
import {DrawerLayout} from '@instructure/ui-drawer-layout'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Tooltip} from '@instructure/ui-tooltip'
import {TruncateText} from '@instructure/ui-truncate-text'
import {IconImageSolid, IconInfoSolid, IconDownloadSolid, IconXSolid} from '@instructure/ui-icons'
import {type File} from '../../../interfaces/File'
import {generatePreviewUrlPath} from '../../../utils/fileUtils'
import {FilePreview} from './FilePreview'
import {FilePreviewNavigationButtons} from './FilePreviewNavigationButtons'
import {FileNotFound} from './FileNotFound'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {getFilesEnv} from '../../../utils/filesEnvUtils'

const I18n = createI18nScope('files_v2')

export interface FilePreviewModalProps {
  isOpen: boolean
  onClose: () => void
  item: File | null
  collection: File[]
  showNavigationButtons?: boolean
  error?: string | null
}

export const FilePreviewModal = ({
  isOpen,
  onClose,
  item,
  collection,
  showNavigationButtons = true,
  error = null,
}: FilePreviewModalProps) => {
  const modalBody = useRef<HTMLElement | null>(null)
  const fileInfoButton = useRef<HTMLElement | null>(null)
  const shouldPreventDismiss = useRef<boolean>(false)
  const [currentItem, setCurrentItem] = useState<File | null>(item)
  const [currentIndex, setCurrentIndex] = useState<number>(
    item && collection ? collection.indexOf(item) : 0,
  )
  const [isTrayOpen, setIsTrayOpen] = useState(false)
  const name = currentItem?.display_name || I18n.t('File')
  const isAccessRestricted = getFilesEnv().userFileAccessRestricted

  // Reset state when the modal is opened or item changes
  useEffect(() => {
    if (isOpen) {
      setCurrentItem(item)
      setCurrentIndex(item && collection ? collection.indexOf(item) : 0)
    }
  }, [isOpen, item, collection])

  const handleOverlayTrayChange = (isTrayOpen: boolean) => {
    setIsTrayOpen(isTrayOpen)
  }

  useEffect(() => {
    const timeoutID = isOpen
      ? setTimeout(() => {
          fileInfoButton.current?.focus()
          modalBody.current?.removeAttribute('tabindex')
        }, 50)
      : undefined
    return timeoutID ? () => clearTimeout(timeoutID) : undefined
  }, [isOpen])

  useEffect(() => {
    if (isOpen) {
      showFlashAlert({
        message: I18n.t('Previewing file %{name}', {name}),
        srOnly: true,
        politeness: 'assertive',
      })
    }
  }, [isOpen, name])

  // Intercept Escape key to check if it originated from within Studio player
  useEffect(() => {
    if (!isOpen) return

    const handleEscapeCapture = (event: KeyboardEvent) => {
      if (event.key !== 'Escape') return

      const studioPlayer = document.querySelector('[data-media-player]')
      if (!studioPlayer) {
        shouldPreventDismiss.current = false
        return
      }

      const target = event.target as HTMLElement
      if (studioPlayer.contains(target)) {
        shouldPreventDismiss.current = true

        // Find the open menu trigger button and restore focus to it after menu closes
        const openMenuButton = studioPlayer.querySelector(
          '[aria-expanded="true"][aria-haspopup="true"]',
        ) as HTMLElement | null
        if (openMenuButton) {
          setTimeout(() => {
            openMenuButton.focus()
          }, 0)
        }
      } else {
        shouldPreventDismiss.current = false
      }
    }

    document.addEventListener('keydown', handleEscapeCapture, true)

    return () => {
      document.removeEventListener('keydown', handleEscapeCapture, true)
    }
  }, [isOpen])

  useEffect(() => {
    const handlePopState = () => {
      const searchParams = new URLSearchParams(window.location.search)
      const previewId = searchParams.get('preview')

      // If there's no preview ID and the modal is open, close it
      if (!previewId && isOpen) {
        onClose()
        return
      }

      // Only update state if we have a different preview ID
      if (currentItem && previewId !== currentItem.id && collection) {
        const newItem = collection.find(item => item.id === previewId)
        if (newItem) {
          setCurrentItem(newItem as File)
          setCurrentIndex(collection.indexOf(newItem))
        }
      }
    }

    window.addEventListener('popstate', handlePopState)
    // Call handlePopState on mount to handle initial URL state
    handlePopState()

    return () => {
      window.removeEventListener('popstate', handlePopState)
    }
  }, [onClose, currentItem?.id, collection, isOpen])

  const handleNext = () => {
    if (!currentItem || !collection.length) return
    const nextIndex = currentIndex + 1 >= collection.length ? 0 : currentIndex + 1
    setCurrentIndex(nextIndex)
    setCurrentItem(collection[nextIndex] as File)
    window.history.replaceState(null, '', generatePreviewUrlPath(collection[nextIndex] as File))
  }

  const handlePrevious = () => {
    if (!currentItem || !collection.length) return
    const previousIndex = currentIndex - 1 < 0 ? collection.length - 1 : currentIndex - 1
    setCurrentIndex(previousIndex)
    setCurrentItem(collection[previousIndex] as File)
    window.history.replaceState(null, '', generatePreviewUrlPath(collection[previousIndex] as File))
  }

  const handleKeyboardNavigation = (event: React.KeyboardEvent) => {
    if (ENV.disable_keyboard_shortcuts || !currentItem || !showNavigationButtons) return

    const {key} = event
    if (key === 'ArrowRight') {
      handleNext()
    } else if (key === 'ArrowLeft') {
      handlePrevious()
    }
  }

  const handleDismiss = () => {
    if (shouldPreventDismiss.current) {
      shouldPreventDismiss.current = false
      return
    }
    onClose()
  }

  return (
    <Modal
      open={isOpen}
      onDismiss={handleDismiss}
      size={'fullscreen'}
      label={name}
      shouldCloseOnDocumentClick={false}
      variant="inverse"
      overflow="fit"
      onKeyDown={handleKeyboardNavigation}
      data-testid="file-preview-modal"
    >
      <Modal.Header>
        <Flex>
          <Flex.Item shouldGrow shouldShrink>
            <Flex alignItems="center">
              <Flex.Item margin="0 medium 0 0">
                <IconImageSolid size="x-small" />
              </Flex.Item>
              <Flex.Item shouldGrow shouldShrink>
                <Tooltip renderTip={name}>
                  <Heading level="h2" data-testid="file-header" width="30%">
                    <TruncateText>{name}</TruncateText>
                  </Heading>
                </Tooltip>
              </Flex.Item>
            </Flex>
          </Flex.Item>
          <Flex.Item>
            <div style={{display: 'grid', gridTemplate: "'info download close'"}}>
              <div style={{gridArea: 'info'}}>
                <IconButton
                  color="primary-inverse"
                  withBackground={false}
                  withBorder={false}
                  renderIcon={IconInfoSolid}
                  screenReaderLabel={I18n.t('Open file info panel')}
                  margin="0 x-small 0 0"
                  id="file-info-button"
                  onClick={() => handleOverlayTrayChange(true)}
                  ref={e => (fileInfoButton.current = e as HTMLElement | null)}
                  disabled={!currentItem}
                />
              </div>
              {!isAccessRestricted && (
                <div style={{gridArea: 'download'}}>
                  <IconButton
                    color="primary-inverse"
                    withBackground={false}
                    withBorder={false}
                    renderIcon={IconDownloadSolid}
                    screenReaderLabel={I18n.t('Download')}
                    margin="0 x-small 0 0"
                    id="download-icon-button"
                    href={currentItem?.url}
                    disabled={!currentItem}
                  />
                </div>
              )}
              <div style={{gridArea: 'close'}}>
                <IconButton
                  color="primary-inverse"
                  withBackground={false}
                  withBorder={false}
                  renderIcon={IconXSolid}
                  screenReaderLabel={I18n.t('Close')}
                  onClick={onClose}
                  id="close-button"
                  data-testid="close-button"
                />
              </div>
            </div>
          </Flex.Item>
        </Flex>
      </Modal.Header>
      <Modal.Body padding="none" id="file-preview-modal-alert">
        {error || !currentItem ? (
          <FileNotFound />
        ) : (
          <DrawerLayout onOverlayTrayChange={handleOverlayTrayChange}>
            <DrawerLayout.Content
              id="file-preview-modal-drawer-layout"
              label={I18n.t('File Preview')}
            >
              <FilePreview item={currentItem} />
            </DrawerLayout.Content>
            <DrawerLayout.Tray
              open={isTrayOpen}
              onClose={() => setIsTrayOpen(false)}
              placement="end"
              label={I18n.t('File Information')}
            >
              {currentItem && (
                <FilePreviewTray onDismiss={() => setIsTrayOpen(false)} item={currentItem} />
              )}
            </DrawerLayout.Tray>
          </DrawerLayout>
        )}
      </Modal.Body>
      <Modal.Footer>
        <Flex justifyItems="space-between" width="100%">
          <Flex.Item>
            {showNavigationButtons && collection.length > 1 && currentItem && (
              <FilePreviewNavigationButtons
                handleNext={handleNext}
                handlePrevious={handlePrevious}
              />
            )}
          </Flex.Item>
          <Flex.Item>
            <Button onClick={onClose} withBackground={false} color="primary-inverse">
              {I18n.t('Close')}
            </Button>
          </Flex.Item>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}
