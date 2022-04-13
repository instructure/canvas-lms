/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {Tooltip} from '@instructure/ui-tooltip'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {IconBlueprintLockSolid, IconBlueprintSolid} from '@instructure/ui-icons'

const I18n = useI18nScope('blueprint_coursesBlueprintLocks')

export const IconLock = () => (
  <Tooltip placement="start" color="primary" renderTip={I18n.t('Locked')}>
    <span>
      <IconBlueprintLockSolid />
      <ScreenReaderContent>{I18n.t('Locked')}</ScreenReaderContent>
    </span>
  </Tooltip>
)

export const IconUnlock = () => (
  <Tooltip placement="start" color="primary" renderTip={I18n.t('Unlocked')}>
    <span>
      <IconBlueprintSolid />
      <ScreenReaderContent>{I18n.t('Unlocked')}</ScreenReaderContent>
    </span>
  </Tooltip>
)
