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
import {string} from 'prop-types'
import ApplyTheme from '@instructure/ui-themeable/lib/components/ApplyTheme'
import Text from '@instructure/ui-elements/lib/components/Text'
import ToggleDetails from '@instructure/ui-toggle-details/lib/components/ToggleGroup'
import View from '@instructure/ui-layout/lib/components/View'
import I18n from 'i18n!speed_grader'

import DateEventGroup from './DateEventGroup'
import * as propTypes from './propTypes'

const themeOverride = {
  [View.theme]: {
    borderStyle: 'dashed'
  }
}

export default class UserEventGroup extends PureComponent {
  static propTypes = {
    userEventGroup: propTypes.userEventGroup.isRequired,
    userId: string.isRequired,
    userName: string.isRequired
  }

  render() {
    const {dateEventGroups} = this.props.userEventGroup

    return (
      <View as="div">
        <ApplyTheme theme={themeOverride}>
          <ToggleDetails
            border={false}
            id={`user-event-group-${this.props.userId}`}
            summary={
              <Text as="h3" weight="bold">
                {this.props.userName}
              </Text>
            }
            toggleLabel={I18n.t('Assessment audit events for %{userName}', {
              userName: this.props.userName
            })}
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
