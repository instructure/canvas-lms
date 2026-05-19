/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import type {LockedDiff as LockedDiffType} from '../differ'
import {Diff} from './DiffHelpers'

const I18n = createI18nScope('lti_registrations')

export type LockedDiffProps = {
  diff: LockedDiffType
}

/**
 * Display lock state changes (Locked ↔ Unlocked)
 */
export const LockedDiff: React.FC<LockedDiffProps> = ({diff}) => {
  return (
    <View as="div" margin="large 0">
      <Diff
        label={I18n.t('Lock Status')}
        diff={diff}
        formatter={locked => (locked ? I18n.t('Locked') : I18n.t('Unlocked'))}
      />
    </View>
  )
}
