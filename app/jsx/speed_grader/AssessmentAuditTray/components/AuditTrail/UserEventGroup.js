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
import ApplyTheme from '@instructure/ui-themeable/lib/components/ApplyTheme'
import Button from '@instructure/ui-buttons/lib/components/Button'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import IconWarning from '@instructure/ui-icons/lib/Line/IconWarning'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import Text from '@instructure/ui-elements/lib/components/Text'
import ToggleDetails from '@instructure/ui-toggle-details/lib/components/ToggleGroup'
import Tooltip from '@instructure/ui-overlays/lib/components/Tooltip'
import TruncateText from '@instructure/ui-elements/lib/components/TruncateText'
import View from '@instructure/ui-layout/lib/components/View'
import I18n from 'i18n!speed_grader'

import DateEventGroup from './DateEventGroup'
import * as propTypes from './propTypes'
import {roleLabelFor} from '../../AuditTrailHelpers'

const themeOverride = {
  [View.theme]: {
    borderStyle: 'dashed'
  }
}

export default class UserEventGroup extends PureComponent {
  static propTypes = {
    userEventGroup: propTypes.userEventGroup.isRequired
  }

  render() {
    const {anonymousOnly, dateEventGroups, user} = this.props.userEventGroup
    const userName = user.name || I18n.t('Unknown User')
    const roleLabel = roleLabelFor(user)
    const message = !anonymousOnly && I18n.t('This user performed actions while anonymous was off')

    return (
      <View as="div">
        <ApplyTheme theme={themeOverride}>
          <ToggleDetails
            border={false}
            id={`user-event-group-${user.id}`}
            summary={
              <Flex as="div" direction="row">
                <FlexItem grow size="0" padding="none xx-small none none">
                  <Text as="h3">
                    <TruncateText maxLines={1}>
                      <Text weight="bold">{userName}</Text> ({roleLabel})
                    </TruncateText>
                  </Text>
                </FlexItem>

                {!anonymousOnly && (
                  <FlexItem>
                    <Tooltip
                      on={['click', 'focus', 'hover']}
                      placement="start"
                      size="medium"
                      tip={message}
                      variant="inverse"
                    >
                      <Button icon={<IconWarning color="error" />} size="medium" variant="icon">
                        <ScreenReaderContent>{I18n.t('Toggle tooltip')}</ScreenReaderContent>
                      </Button>
                    </Tooltip>
                  </FlexItem>
                )}
              </Flex>
            }
            toggleLabel={I18n.t('Assessment audit events for %{userName}', {userName})}
          >
            <div>
              {dateEventGroups.map(dateEventGroup => (
                <DateEventGroup dateEventGroup={dateEventGroup} key={dateEventGroup.startDateKey} />
              ))}
            </div>
          </ToggleDetails>
        </ApplyTheme>

        <View as="div" borderWidth="none none small" margin="none" padding="none" />
      </View>
    )
  }
}
