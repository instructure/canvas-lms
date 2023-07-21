/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import React from 'react'

const I18n = useI18nScope('feature_flags')

export function buildTransitions(flag, allowsDefaults) {
  const ret = {}
  if (flag.state.includes('allowed') && allowsDefaults) {
    ret.enabled = 'allowed_on'
    ret.disabled = 'allowed'
  } else {
    ret.enabled = 'on'
    ret.disabled = 'off'
  }
  switch (flag.state) {
    case 'allowed_on':
      ret.lock = 'on'
      break
    case 'allowed':
      ret.lock = 'off'
      break
    case 'on':
      ret.lock = 'allowed_on'
      break
    case 'off':
      ret.lock = 'allowed'
      break
  }
  return ret
}

export function buildDescription(flag, allowsDefaults) {
  let description = ''
  if (allowsDefaults) {
    switch (flag.state) {
      case 'on':
        description = I18n.t('Enabled for all subaccounts/courses')
        break
      case 'off':
      case 'hidden':
        description = I18n.t('Disabled for all subaccounts/courses')
        break
      case 'allowed':
        description = I18n.t('Allowed for subaccounts/courses, default off')
        break
      case 'allowed_on':
        description = I18n.t('Allowed for subaccounts/courses, default on')
        break
    }
  } else {
    switch (flag.state) {
      case 'on':
      case 'allowed_on':
        description = I18n.t('Enabled')
        break
      case 'off':
      case 'hidden':
      case 'allowed':
        description = I18n.t('Disabled')
        break
    }
  }

  return description
}

export function shouldDelete(flag, allowsDefaults, state) {
  // Easy case
  if (flag.parent_state === state) {
    return true
  }
  // Awkward hidden case
  if (flag.parent_state === 'hidden' && state === 'off') {
    return true
  }
  // Revert to inheriting when reasonable
  if (!allowsDefaults && flag.parent_state === 'allowed_on' && state === 'on') {
    return true
  }
  if (!allowsDefaults && flag.parent_state === 'allowed' && state === 'off') {
    return true
  }
  return false
}

export function doesAllowDefaults(flag, disableDefaults) {
  let allowsDefaults = false
  if (flag.transitions.allowed && !flag.transitions.allowed.locked) {
    allowsDefaults = true
  }
  if (flag.transitions.allowed_on && !flag.transitions.allowed_on.locked) {
    allowsDefaults = true
  }
  if (disableDefaults) {
    allowsDefaults = false
  }
  return allowsDefaults
}

export function transitionLocked(flag, name) {
  if (flag.transitions[name] || flag.state === name) {
    return flag.transitions[name]?.locked
  }

  return null
}

export function transitionMessage(flag, name) {
  let message = null
  if (flag.transitions[name]) {
    message = flag.transitions[name].message
  }

  if (ENV.ACCOUNT?.site_admin && ENV.RAILS_ENVIRONMENT !== 'development') {
    message = (
      <div>
        <p>
          {I18n.t(
            `You are currently in the %{environment} environment. This will affect every customer. Are you sure?`,
            {environment: ENV.RAILS_ENVIRONMENT}
          )}
        </p>
        <p>{message}</p>
      </div>
    )
  }

  return message
}

export function isEnabled(flag) {
  return flag.state === 'on' || flag.state === 'allowed_on'
}

export function isLocked(flag) {
  return flag.state !== 'allowed' && flag.state !== 'allowed_on'
}
