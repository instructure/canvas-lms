// @ts-nocheck
/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {ReactElement} from 'react'

import {CloseButton} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'

import ErrorBoundary from '@canvas/error-boundary'
import GenericErrorPage from '@canvas/generic-error-page'
import errorShipUrl from '@canvas/images/ErrorShip.svg'

const I18n = useI18nScope('canvas_modal')

type Props = {
  children: ReactElement | ReactElement[]
  footer: ReactElement | null | (() => ReactElement) // render prop. usually to render the buttons for the footer.
  padding?: string
  label: string
  title?: string | null // specify this if the header text should be different than the modal's label
  // Optional props to pass to the GenericErrorPage in ErrorBoundary
  errorSubject?: string
  errorCategory?: string
  errorImageUrl?: string
  closeButtonSize?: 'small' | 'medium' | 'large' | undefined
  onDismiss?: () => void
  [key: string]: any
}

function CanvasModal({
  padding = 'small',
  errorSubject,
  errorCategory,
  errorImageUrl = errorShipUrl,
  label,
  title = null,
  onDismiss,
  children,
  footer = null,
  closeButtonSize,
  ...otherModalProps
}: Props): ReactElement {
  if (title == null) title = label

  return (
    <Modal label={label} onDismiss={onDismiss} {...otherModalProps}>
      <Modal.Header>
        <Heading>{title}</Heading>
        <CloseButton
          data-instui-modal-close-button="true"
          onClick={onDismiss}
          size={closeButtonSize}
          screenReaderLabel={I18n.t('Close')}
          placement="end"
          offset="medium"
        />
      </Modal.Header>
      <Modal.Body padding={padding}>
        <View as="div" height="100%">
          <ErrorBoundary
            errorComponent={
              <GenericErrorPage
                imageUrl={errorImageUrl}
                errorSubject={errorSubject}
                errorCategory={errorCategory}
              />
            }
          >
            {children}
          </ErrorBoundary>
        </View>
      </Modal.Body>
      {footer && <Modal.Footer>{typeof footer === 'function' ? footer() : footer}</Modal.Footer>}
    </Modal>
  )
}

export default CanvasModal
