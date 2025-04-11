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
import {Heading} from '@instructure/ui-heading'
import {CloseButton} from '@instructure/ui-buttons'

const I18n = createI18nScope('account_reports')

interface Props {
  descHTML: string
  serviceTitle: string
  closeModal: () => void
}

export default function ServiceDescriptionModal(props: Props) {
  return (
    <Modal size="medium" open label={I18n.t('About the service')}>
      <Modal.Header>
        <Heading data-testid="about-google-docs">{props.serviceTitle}</Heading>
        <CloseButton
          onClick={props.closeModal}
          placement="end"
          offset="medium"
          screenReaderLabel={I18n.t('Close')}
        />
      </Modal.Header>
      <Modal.Body dangerouslySetInnerHTML={{__html: props.descHTML}}></Modal.Body>
    </Modal>
  )
}
