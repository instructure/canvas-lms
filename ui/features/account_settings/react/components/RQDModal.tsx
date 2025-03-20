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

import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {useScope as createI18nScope} from '@canvas/i18n'
import {CloseButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'

const I18n = createI18nScope('account_settings')

interface Props {
  closeModal: () => void
}

export default function RQDModal(props: Props) {
  return (
    <Modal size="small" open label={I18n.t('Restrict Quantitative Data')}>
      <Modal.Header>
        <Heading>{I18n.t('Restrict Quantitative Data')}</Heading>
        <CloseButton
          data-testid="close-button"
          placement="end"
          size="medium"
          onClick={props.closeModal}
          screenReaderLabel={I18n.t('Close')}
        />
      </Modal.Header>
      <Modal.Body>
        <Text data-testid="rqd-modal-text">
          {I18n.t(
            "When selected, this setting will limit the view of new courses' quantitative (numeric) grading data. Students and observers will only see qualitative data, which includes letter grades and comments.",
          )}
        </Text>
      </Modal.Body>
    </Modal>
  )
}
