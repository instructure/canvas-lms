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

import I18n from 'i18n!canvas_modal'
import React from 'react'
import {string, node, func, oneOfType} from 'prop-types'

import {CloseButton} from '@instructure/ui-buttons'
import {Flex, View} from '@instructure/ui-layout'
import {Heading} from '@instructure/ui-elements'
import {Modal} from '@instructure/ui-overlays'

import ErrorBoundary from './ErrorBoundary'
import GenericErrorPage from './GenericErrorPage'
import errorShipUrl from '../svg/ErrorShip.svg'

CanvasModal.propTypes = {
  ...Modal.propTypes,
  children: node.isRequired,
  footer: oneOfType([node, func]), // render prop. usually to render the buttons for the footer.
  padding: View.propTypes.padding,

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
  closeButtonSize: 'small'
}

export default function CanvasModal({
  padding,
  errorSubject,
  errorCategory,
  errorImageUrl,
  label,
  onDismiss,
  children,
  footer,
  closeButtonSize,
  ...otherModalProps
}) {
  return (
    <Modal label={label} onDismiss={onDismiss} {...otherModalProps}>
      <Modal.Header>
        <Flex>
          <Flex.Item grow>
            <Heading>{label}</Heading>
          </Flex.Item>
          <Flex.Item>
            <CloseButton onClick={onDismiss} size={closeButtonSize}>
              {I18n.t('Close')}
            </CloseButton>
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
      <Modal.Footer>{typeof footer === 'function' ? footer() : footer}</Modal.Footer>
    </Modal>
  )
}
