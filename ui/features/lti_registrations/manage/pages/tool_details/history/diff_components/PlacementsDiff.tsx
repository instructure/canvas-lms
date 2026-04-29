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
import type {PlacementsDiff as PlacementsDiffType} from '../differ'
import {Diff, DiffList} from './DiffHelpers'
import {List} from '@instructure/ui-list'

const I18n = createI18nScope('lti_registrations')

export type PlacementsDiffProps = {
  diff: NonNullable<PlacementsDiffType>
}

/**
 * Display placement changes including added/removed placements,
 * course navigation default, and placement-specific overrides
 */
export const PlacementsDiff: React.FC<PlacementsDiffProps> = ({diff}) => {
  const hasAddedOrRemoved = diff.added.length > 0 || diff.removed.length > 0
  const hasCourseNavDefault = diff.courseNavigationDefault !== null
  const hasPlacementChanges = diff.placementChanges.size > 0

  const hasAnyChanges = hasAddedOrRemoved || hasCourseNavDefault || hasPlacementChanges

  if (!hasAnyChanges) {
    return null
  }

  return (
    <View as="div" margin="large 0">
      <DiffList
        label={I18n.t('Placements')}
        labelSize="h3"
        additions={diff.added}
        removals={diff.removed}
        formatter={i18nLtiPlacement}
      />
      <Diff
        label={I18n.t('Course Navigation Default')}
        diff={diff.courseNavigationDefault}
        formatter={value => {
          if (value === 'enabled') return I18n.t('Enabled')
          if (value === 'disabled') return I18n.t('Disabled')
          return String(value)
        }}
      />
      {hasPlacementChanges && (
        <View as="div" margin="small 0">
          <Heading level="h3" margin="0 0 x-small 0">
            {I18n.t('Override URIs')}
          </Heading>
          <List isUnstyled margin="none">
            {Array.from(diff.placementChanges.entries()).map(([placement, changes]) => {
              const hasTargetLinkUri = changes.targetLinkUri !== null
              const hasMessageType = changes.messageType !== null

              if (!hasTargetLinkUri && !hasMessageType) {
                return null
              }

              return (
                <List.Item key={placement}>
                  <Heading level="h4" margin="0 0 x-small 0">
                    {i18nLtiPlacement(placement)}
                  </Heading>

                  {changes.targetLinkUri !== null && (
                    <Diff
                      label={I18n.t('Target Link URI')}
                      diff={changes.targetLinkUri}
                      labelSize="h5"
                    />
                  )}

                  {changes.messageType !== null && (
                    <Diff
                      label={I18n.t('Message Type')}
                      diff={changes.messageType}
                      labelSize="h5"
                    />
                  )}
                </List.Item>
              )
            })}
          </List>
        </View>
      )}
    </View>
  )
}
