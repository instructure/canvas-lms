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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {i18nLtiScope} from '@canvas/lti/model/i18nLtiScope'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import type {PermissionsDiff as PermissionsDiffType} from '../differ'
import {DiffList} from './DiffHelpers'

const I18n = createI18nScope('lti_registrations')

export type PermissionsDiffProps = {
  diff: NonNullable<PermissionsDiffType>
}

/**
 * Display permissions/scopes changes (additions/removals)
 */
export const PermissionsDiff: React.FC<PermissionsDiffProps> = ({diff}) => {
  if (diff.added.length === 0 && diff.removed.length === 0) {
    return null
  }

  return (
    <View as="div" margin="large 0">
      <Heading level="h3" margin="0 0 small 0">
        {I18n.t('Permissions')}
      </Heading>
      <DiffList
        label={I18n.t('Scopes')}
        additions={diff.added}
        removals={diff.removed}
        formatter={i18nLtiScope}
      />
    </View>
  )
}
