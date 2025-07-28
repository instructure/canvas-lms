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
  title: string
  closeModal: () => void
}

export default function ReportDescription(props: Props) {
  return (
    <Modal label={I18n.t('Report Description')} open size="medium">
      <Modal.Header>
        <Heading>{props.title}</Heading>
        <CloseButton
          data-testid="close-button"
          placement="end"
          size="medium"
          onClick={props.closeModal}
          screenReaderLabel={I18n.t('Close')}
        />
      </Modal.Header>
      <Modal.Body dangerouslySetInnerHTML={{__html: props.descHTML}} />
    </Modal>
  )
}
