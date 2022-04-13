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
import React from 'react'
import {string, node, func, oneOfType} from 'prop-types'

import {CloseButton} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'

import ErrorBoundary from '@canvas/error-boundary'
import GenericErrorPage from '@canvas/generic-error-page'
import errorShipUrl from '@canvas/images/ErrorShip.svg'

const I18n = useI18nScope('canvas_modal')

CanvasModal.propTypes = {
  ...Modal.propTypes,
  children: node.isRequired,
  footer: oneOfType([node, func]), // render prop. usually to render the buttons for the footer.
  padding: View.propTypes.padding,

  title: string, // specify this if the header text should be different than the modal's label

  // Optional props to pass to the GenericErrorPage in ErrorBoundary
  errorSubject: string,
  errorCategory: string,
  errorImageUrl: string,

  closeButtonSize: string
}

CanvasModal.defaultProps = {
  padding: 'small',
  errorImageUrl: errorShipUrl,
  footer: null,
  title: null,
  closeButtonSize: 'small'
}

export default function CanvasModal({
  padding,
  errorSubject,
  errorCategory,
  errorImageUrl,
  label,
  title,
  onDismiss,
  children,
  footer,
  closeButtonSize,
  ...otherModalProps
}) {
  if (title == null) title = label

  return (
    <Modal label={label} onDismiss={onDismiss} {...otherModalProps}>
      <Modal.Header>
        <Flex>
          <Flex.Item grow>
            <Heading>{title}</Heading>
          </Flex.Item>
          <Flex.Item>
            <CloseButton
              onClick={onDismiss}
              size={closeButtonSize}
              screenReaderLabel={I18n.t('Close')}
            />
          </Flex.Item>
        </Flex>
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
