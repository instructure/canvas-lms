/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import React, {PureComponent} from 'react'
import {ApplyTheme} from '@instructure/ui-themeable'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {IconWarningLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Text} from '@instructure/ui-text'
import {ToggleGroup} from '@instructure/ui-toggle-details'
import {Tooltip} from '@instructure/ui-tooltip'

import I18n from 'i18n!speed_grader'

import DateEventGroup from './DateEventGroup'
import * as propTypes from './propTypes'
import {roleLabelFor, creatorNameFor} from '../../AuditTrailHelpers'

const themeOverride = {
  [View.theme]: {
    borderStyle: 'dashed'
  }
}

export default class CreatorEventGroup extends PureComponent {
  static propTypes = {
    creatorEventGroup: propTypes.creatorEventGroup.isRequired
  }

  render() {
    const {anonymousOnly, dateEventGroups, creator} = this.props.creatorEventGroup
    const creatorName = creatorNameFor(creator)
    const roleLabel = roleLabelFor(creator)
    const message =
      !anonymousOnly &&
      I18n.t('%{creatorName} performed actions while anonymous was off', {creatorName})

    return (
      <View as="div">
        <ApplyTheme theme={themeOverride}>
          <ToggleGroup
            border={false}
            id={`creator-event-group-${creator.key}`}
            summary={
              <Flex as="div" direction="row">
                <Flex.Item grow size="0" padding="none xx-small none none">
                  <Text as="h3">
                    <TruncateText maxLines={1}>
                      <Text weight="bold">{creatorName}</Text> ({roleLabel})
                    </TruncateText>
                  </Text>
                </Flex.Item>

                {!anonymousOnly && (
                  <Flex.Item>
                    <Tooltip
                      on={['click', 'focus', 'hover']}
                      placement="start"
                      tip={message}
                      variant="inverse"
                    >
                      <Button icon={<IconWarningLine color="error" />} size="medium" variant="icon">
                        <ScreenReaderContent>{I18n.t('Toggle tooltip')}</ScreenReaderContent>
                      </Button>
                    </Tooltip>
                  </Flex.Item>
                )}
              </Flex>
            }
            toggleLabel={I18n.t('Assessment audit events for %{creatorName}', {creatorName})}
          >
            <div>
              {dateEventGroups.map(dateEventGroup => (
                <DateEventGroup dateEventGroup={dateEventGroup} key={dateEventGroup.startDateKey} />
              ))}
            </div>
          </ToggleGroup>
        </ApplyTheme>

        <View as="div" borderWidth="none none small" margin="none" padding="none" />
      </View>
    )
  }
}
