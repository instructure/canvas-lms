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

import {Modal} from '@instructure/ui-modal'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useEffect, useState} from 'react'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {CloseButton} from '@instructure/ui-buttons'

const I18n = createI18nScope('catalog')

const DEFAULT_IFRAME_HEIGHT = '300px'
const ADDITIONAL_PADDING = 30

interface Props {
  embeddedLink: string
  onClose: () => void
  isOpen: boolean
}

export default function AllCoursesDialog(props: Props) {
  const {embeddedLink, onClose, isOpen} = props
  const [modalHeight, setModalHeight] = useState(DEFAULT_IFRAME_HEIGHT)
  const [loadingFrame, setLoadingFrame] = useState(true)
  const style: React.CSSProperties = {
    border: 'none',
    height: loadingFrame ? 0 : modalHeight,
    width: loadingFrame ? 0 : '100%',
  }

  useEffect(() => {
    if (!loadingFrame) {
      let totalHeight = 0
      const iframe = document.querySelector<HTMLIFrameElement>('#self-enroll-modal-iframe')
      if (iframe) {
        const iframeContent = iframe.contentDocument?.body
        const body = iframeContent?.querySelector('.ic-Self-enrollment-form')
        if (body) {
          totalHeight += (body as HTMLElement).offsetHeight
        }
        const footer = iframeContent?.querySelector('.ic-Self-enrollment-footer-modal-layout')
        if (footer) {
          totalHeight += (footer as HTMLElement).offsetHeight
        }
        if (totalHeight > 0) {
          setModalHeight(`${totalHeight + ADDITIONAL_PADDING}px`)
        }
      }
    }
  }, [loadingFrame])

  const stopLoading = () => {
    setLoadingFrame(false)
  }

  const enrollLabel = I18n.t('Enroll in a Course')
  return (
    <Modal
      data-testid="all-courses-dialog"
      title={enrollLabel}
      size="small"
      open={isOpen}
      label={enrollLabel}
      onDismiss={onClose}
    >
      <Modal.Header>
        <Flex justifyItems="space-between" alignItems="center">
          <Heading variant="titleModule">{enrollLabel}</Heading>
          <CloseButton
            onClick={() => {
              onClose()
              setLoadingFrame(true)
            }}
            screenReaderLabel={I18n.t('Close enrollment dialog')}
          />
        </Flex>
      </Modal.Header>
      {loadingFrame ? (
        <View textAlign="center" margin="medium">
          <Spinner
            data-testid="all-courses-loading"
            renderTitle={I18n.t('Loading enrollment form')}
          />
        </View>
      ) : null}
      <iframe
        id="self-enroll-modal-iframe"
        data-testid="all-courses-iframe"
        style={style}
        src={embeddedLink}
        title={I18n.t('Course Catalog')}
        onLoad={stopLoading}
      />
    </Modal>
  )
}
