/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import * as React from 'react'
import type {LtiConfiguration} from '../model/lti_tool_configuration/LtiConfiguration'
import {Modal} from '@instructure/ui-modal'
import {Button} from '@instructure/ui-buttons'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {AccountId} from '../model/AccountId'
import type {UnifiedToolId} from '../model/UnifiedToolId'

const I18n = useI18nScope('lti_registrations')

export type Lti1p3RegistrationWizardProps = {
  accountId: AccountId
  configuration?: LtiConfiguration
  unregister: () => void
  unifiedToolId?: UnifiedToolId
  onSuccessfulRegistration: () => void
}

export const Lti1p3RegistrationWizard = (props: Lti1p3RegistrationWizardProps) => {
  return (
    <>
      <Modal.Body>
        <div>
          {/* todo: render the generalized form for manual configurations */}
          <pre>{JSON.stringify(props.configuration, null, 2)}</pre>
        </div>
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={props.unregister}>{I18n.t('Previous')}</Button>
      </Modal.Footer>
    </>
  )
}
