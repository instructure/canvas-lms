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
import {useScope as createI18nScope} from '@canvas/i18n'
import {IconButton} from '@instructure/ui-buttons'
import {IconInfoLine} from '@instructure/ui-icons'
import {Img} from '@instructure/ui-img'
import {Responsive} from '@instructure/ui-responsive'
import {Text} from '@instructure/ui-text'
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'
import {memo} from 'react'
import {i18nLtiPlacementDescription} from '../model/i18nLtiPlacementDescription'
import type {LtiPlacement} from '../model/LtiPlacement'
import {Flex} from '@instructure/ui-flex'
import {i18nLtiPlacement} from '../model/i18nLtiPlacement'

const I18n = createI18nScope('lti_registrations')

export type PlacementInfoTooltipProps = {
  placement: LtiPlacement
}

export const PlacementInfoTooltip = memo(({placement}: PlacementInfoTooltipProps) => {
  return (
    <Tooltip
      placement="top"
      constrain="parent"
      renderTip={
        <Responsive
          match="media"
          query={{
            small: {maxWidth: 500},
            medium: {minWidth: 500},
            large: {minWidth: 1000},
          }}
          props={{
            small: {width: '15rem'},
            medium: {width: '30rem'},
            large: {width: '35rem'},
          }}
          render={props => {
            return (
              <Flex
                direction="column"
                width={props?.width}
                alignItems="center"
                justifyItems="center"
              >
                <Flex.Item>
                  <Img
                    data-testid={`placement-img-${placement}`}
                    constrain="contain"
                    src={`/doc/api/images/placements/${placement}.png`}
                    alt={I18n.t('An image showing the %{placement} placement within Canvas', {
                      placement: i18nLtiPlacement(placement),
                    })}
                  />
                </Flex.Item>
                <Flex.Item>
                  <Text>{i18nLtiPlacementDescription(placement)}</Text>
                </Flex.Item>
              </Flex>
            )
          }}
        />
      }
    >
      <IconButton
        withBackground={false}
        withBorder={false}
        renderIcon={IconInfoLine}
        size="small"
        screenReaderLabel={I18n.t('Tooltip for the %{placement} placement', {
          placement,
        })}
      />
    </Tooltip>
  )
})
