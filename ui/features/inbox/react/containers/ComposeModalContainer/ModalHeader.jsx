/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import PropTypes from 'prop-types'
import React from 'react'

import {CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'

const I18n = useI18nScope('conversations_2')

const ModalHeader = props => (
  <Modal.Header>
    <CloseButton
      placement="end"
      offset="small"
      onClick={props.onDismiss}
      screenReaderLabel={I18n.t('Close')}
    />
    <Heading>{props?.headerTitle ? props.headerTitle : I18n.t('Compose Message')}</Heading>
  </Modal.Header>
)

ModalHeader.propTypes = {
  onDismiss: PropTypes.func,
  headerTitle: PropTypes.string,
}

export default ModalHeader
