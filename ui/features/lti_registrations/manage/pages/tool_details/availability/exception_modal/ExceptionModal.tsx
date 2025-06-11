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

import React from 'react'
import {LtiDeployment} from '../../../../model/LtiDeployment'
import {Modal} from '@instructure/ui-modal'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('lti_registrations')

export type ExceptionModalOpenState =
  | {
      open: false
    }
  | {
      open: true
      deployment: LtiDeployment
    }

export type ExceptionModalProps = {
  openState: ExceptionModalOpenState
  onClose: () => void
}

export const ExceptionModal = ({openState, onClose}: ExceptionModalProps) => {
  return (
    <Modal open={openState.open} label={I18n.t('Add Availability and Exceptions')} size="medium">
      <Modal.Header>
        <CloseButton placement="end" offset="small" onClick={onClose} screenReaderLabel="Close" />
        <Heading>{I18n.t('Add Availability and Exceptions')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <View minHeight="20em" as="div">
          <Heading level="h4" margin="0 0 x-small 0">
            {I18n.t('Availability and Exceptions')}
          </Heading>
          <Text>
            {I18n.t(
              'You have not added any availability or exceptions. Search or browse to add one.',
            )}
          </Text>
        </View>
      </Modal.Body>
      <Modal.Footer>
        <Button color="primary" type="submit">
          {I18n.t('Done')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}
