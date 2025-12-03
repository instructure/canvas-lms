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
import type {NamingDiff as NamingDiffType} from '../differ'
import {Diff} from './DiffHelpers'

const I18n = createI18nScope('lti_registrations')

export type NamingDiffProps = {
  diff: NonNullable<NamingDiffType>
}

/**
 * Display naming changes including title, name, nickname, description,
 * and placement-specific text overrides
 */
export const NamingDiff: React.FC<NamingDiffProps> = ({diff}) => {
  const hasAdminNickname = diff.adminNickname !== null
  const hasDescription = diff.description !== null
  const hasPlacementTexts = diff.placementTexts.size > 0

  const hasAnyChanges = hasAdminNickname || hasDescription || hasPlacementTexts

  if (!hasAnyChanges) {
    return null
  }

  return (
    <View as="div" margin="large 0">
      <Heading level="h3" margin="0 0 small 0">
        {I18n.t('Naming')}
      </Heading>

      <Diff label={I18n.t('Admin Nickname')} diff={diff.adminNickname} />

      <Diff label={I18n.t('Description')} diff={diff.description} />

      {hasPlacementTexts && (
        <View as="div" margin="small 0">
          <Heading level="h4" margin="0 0 x-small 0">
            {I18n.t('Placement Labels')}
          </Heading>
          {Array.from(diff.placementTexts.entries()).map(([placement, textDiff]) => {
            if (!textDiff) return null

            return (
              <View key={placement} as="div" margin="small 0">
                <Diff label={i18nLtiPlacement(placement)} diff={textDiff} labelSize="h5" />
              </View>
            )
          })}
        </View>
      )}
    </View>
  )
}
