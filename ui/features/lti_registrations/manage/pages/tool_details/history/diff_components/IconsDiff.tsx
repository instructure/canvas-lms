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
import {i18nLtiPlacement} from '../../../../model/i18nLtiPlacement'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import type {IconDiff as IconDiffType} from '../differ'
import {Diff} from './DiffHelpers'

const I18n = createI18nScope('lti_registrations')

export type IconsDiffProps = {
  diff: NonNullable<IconDiffType>
}

/**
 * Display icon changes including global icon URL and placement-specific icon overrides
 */
export const IconsDiff: React.FC<IconsDiffProps> = ({diff}) => {
  if (!(diff.iconUrl !== null || diff.placementIcons.size > 0)) {
    return null
  }

  return (
    <View as="div" margin="large 0">
      <Heading level="h3" margin="0 0 small 0">
        {I18n.t('Icon Changes')}
      </Heading>

      <Diff label={I18n.t('Default Icon URL')} diff={diff.iconUrl} />

      {diff.placementIcons.size > 0 && (
        <View as="div" margin="small 0">
          {Array.from(diff.placementIcons.entries()).map(([placement, iconDiff]) => {
            if (!iconDiff) return null

            return (
              <View key={placement} as="div" margin="small 0">
                <Diff label={i18nLtiPlacement(placement)} diff={iconDiff} />
              </View>
            )
          })}
        </View>
      )}
    </View>
  )
}
