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

import {useOutletContext} from 'react-router-dom'
import type {ToolDetailsOutletContext} from '../ToolDetails'
import type {AccountId} from '../../../model/AccountId'
import {OverlayHistoryView} from './OverlayHistoryView'
import {RegistrationHistoryView} from './RegistrationHistoryView'

export type ToolHistoryProps = {
  accountId: AccountId
}

export const ToolHistory = (props: ToolHistoryProps) => {
  const {registration} = useOutletContext<ToolDetailsOutletContext>()

  const useNewHistory = window.ENV?.LTI_REGISTRATIONS_HISTORY || false

  if (useNewHistory) {
    return <RegistrationHistoryView accountId={props.accountId} registrationId={registration.id} />
  } else {
    return <OverlayHistoryView accountId={props.accountId} registrationId={registration.id} />
  }
}
