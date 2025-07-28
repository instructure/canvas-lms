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
import {Text} from '@instructure/ui-text'

const I18n = createI18nScope('account_settings')

interface Props {
  loginUrl: string
  closeModal: () => void
}

export default function OpenRegistrationWarning(props: Props) {
  const warningMessage = I18n.t(
    `An external identity provider is enabled, and users created via open registration may not be able to log in unless
      the external identity provider's login form has a link back to *%{url}*.`,
    {url: props.loginUrl, wrapper: `<a href="${props.loginUrl}" target="_blank">$1</a>`},
  )
  return (
    <Modal size="medium" open label={I18n.t('An External Identity Provider is Enabled')}>
      <Modal.Header>
        <Heading>{I18n.t('An External Identity Provider is Enabled')}</Heading>
        <CloseButton
          data-testid="close-button"
          placement="end"
          size="medium"
          onClick={props.closeModal}
          screenReaderLabel={I18n.t('Close')}
        />
      </Modal.Header>
      <Modal.Body>
        <Text
          data-testid="open_registration_warning"
          dangerouslySetInnerHTML={{__html: warningMessage}}
        ></Text>
      </Modal.Body>
    </Modal>
  )
}
