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

import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('external_tools')

export default function toolConfigurationError(error, clientId) {
  $.flashError(errorMessage(error, clientId))
}

function errorMessage(error, clientId) {
  const {status} = error.response

  if (status === 404) {
    return I18n.t('Could not find an LTI configuration for client ID %{clientId}', {clientId})
  } else if (status === 401) {
    return I18n.t('The client ID %{clientId} is disabled', {clientId})
  }

  return I18n.t('An error occured while trying to find the LTI configuration')
}
