/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import React from 'react'
import {Alert} from '@instructure/ui-alerts'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('react_developer_keys')

interface OverlayAlertProps {
  contextId: string
  ltiRegistrationId: string
}

export const OverlayAlert = ({contextId, ltiRegistrationId}: OverlayAlertProps) => {
  return (
    <View as="div" margin="0 0 medium 0">
      <Alert variant="warning" renderCloseButtonLabel={I18n.t('Close')} margin="0 0 medium 0">
        <Text>
          {I18n.t(
            'This key includes settings that are only supported in Canvas Apps. Changes cannot be saved on this page.',
          )}{' '}
          <Link href={`/accounts/${contextId}/apps/manage/${ltiRegistrationId}/configuration`}>
            {I18n.t('Edit in Canvas Apps.')}
          </Link>
        </Text>
      </Alert>
    </View>
  )
}
