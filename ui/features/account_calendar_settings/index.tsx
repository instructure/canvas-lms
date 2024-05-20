/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'

import ready from '@instructure/ready'

import {AccountCalendarSettings} from './react/components/AccountCalendarSettings'
import type {EnvAccountsAdminTools} from '@canvas/global/env/EnvAccounts'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'

// Allow unchecked access to module-specific ENV variables
declare const ENV: GlobalEnv & EnvAccountsAdminTools

ready(() => {
  ReactDOM.render(
    <AccountCalendarSettings accountId={parseInt(ENV.ACCOUNT_ID, 10)} />,
    document.getElementById('account-calendar-settings-container')
  )
})
