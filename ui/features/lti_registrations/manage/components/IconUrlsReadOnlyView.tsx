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

import * as React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import type {InternalPlacementConfiguration} from '../model/internal_lti_configuration/placement_configuration/InternalPlacementConfiguration'
import {i18nLtiPlacement} from '../model/i18nLtiPlacement'
import {isLtiPlacementWithDefaultIcon} from '../model/LtiPlacement'
import {ltiToolDefaultIconUrl} from '../model/ltiToolIcons'
import type {DeveloperKeyId} from '../model/developer_key/DeveloperKeyId'

const I18n = createI18nScope('lti_registrations')

export type IconUrlsReadOnlyViewProps = {
  toolIconUrl?: string | null
  placements: InternalPlacementConfiguration[]
  registrationName: string
  developerKeyId?: DeveloperKeyId | null
}

export const IconUrlsReadOnlyView = ({
  toolIconUrl,
  placements,
  registrationName,
  developerKeyId = null,
}: IconUrlsReadOnlyViewProps) => {
  return (
    <>
      {toolIconUrl ? (
        <Flex direction="row" alignItems="center" margin="small 0 0" gap="xx-small">
          <Flex.Item margin="0 xx-small 0 0">
            <img
              style={{height: '24px'}}
              src={toolIconUrl}
              alt={I18n.t('Icon displayed next to tool on Apps page')}
            ></img>
          </Flex.Item>
          <Flex.Item shouldShrink>
            <Text wrap="break-word">{toolIconUrl}</Text>
          </Flex.Item>
        </Flex>
      ) : (
        <Text fontStyle="italic">{I18n.t('No tool icon URL configured.')}</Text>
      )}

      <Heading level="h3" margin="small 0" id="placement-icon-urls">
        {I18n.t('Placement Icon URLs')}
      </Heading>
      {placements.length > 0 ? (
        placements.map((p, i) => (
          <View key={p.placement} as="div" margin="small 0" style={{overflow: 'hidden'}}>
            <Text weight="bold">{i18nLtiPlacement(p.placement)}:</Text>
            <Flex
              direction="row"
              alignItems="center"
              margin="0"
              key={i}
              style={{overflow: 'hidden'}}
            >
              {p.icon_url ? (
                <>
                  <Flex.Item margin="0 xx-small 0 0">
                    <img style={{height: '24px'}} src={p.icon_url} alt={registrationName}></img>
                  </Flex.Item>
                  <div
                    data-testid={`icon-url-${p.placement}`}
                    style={{
                      textOverflow: 'ellipsis',
                      overflow: 'hidden',
                      whiteSpace: 'nowrap',
                      flex: 1,
                    }}
                  >
                    {p.icon_url}
                  </div>
                </>
              ) : isLtiPlacementWithDefaultIcon(p.placement) ? (
                <>
                  <Flex.Item margin="0 xx-small 0 0">
                    <img
                      style={{height: '24px'}}
                      src={ltiToolDefaultIconUrl({
                        base: window.location.origin,
                        toolName: registrationName,
                        developerKeyId: developerKeyId ?? undefined,
                      })}
                      alt={registrationName}
                    ></img>
                  </Flex.Item>
                  <Flex.Item margin="0 xx-small 0 0" data-testid={`icon-url-${p.placement}`}>
                    <Text fontStyle="italic">{I18n.t('Default Icon')}</Text>
                  </Flex.Item>
                </>
              ) : (
                <Text fontStyle="italic" data-testid={`icon-url-${p.placement}`}>
                  {I18n.t('Not Included')}
                </Text>
              )}
            </Flex>
          </View>
        ))
      ) : (
        <Text fontStyle="italic">{I18n.t('No placements with icons are enabled.')}</Text>
      )}
    </>
  )
}
