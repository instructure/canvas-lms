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

import React from 'react'
import I18n from 'i18n!assignments_2'
import {OverrideShape} from '../../assignmentData'
import OverrideSubmissionTypes from './OverrideSubmissionTypes'
import TeacherViewContext from '../TeacherViewContext'
import AvailabilityDates from '../../../shared/AvailabilityDates'
import FriendlyDatetime from '../../../../shared/FriendlyDatetime'

import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import Text from '@instructure/ui-elements/lib/components/Text'
import View from '@instructure/ui-layout/lib/components/View'

export default class OverrideSummary extends React.Component {
  static contextType = TeacherViewContext

  static propTypes = {
    override: OverrideShape
  }

  renderTitle(override) {
    return <Text weight="bold">{override.title}</Text>
  }

  renderAttemptsAllowed() {
    const allowed = this.props.override.allowedAttempts
    const attempts = Number.isInteger(allowed) ? allowed : 1
    return <Text>{I18n.t({one: '1 Attempt', other: '%{count} Attempts'}, {count: attempts})}</Text>
  }

  renderSubmissionTypesAndDueDate(override) {
    return (
      <Text>
        <OverrideSubmissionTypes variant="simple" override={this.props.override} />
        <Text> | </Text>
        <FriendlyDatetime
          prefix={I18n.t('Due: ')}
          dateTime={override.dueAt}
          format={I18n.t('#date.formats.full')}
        />
      </Text>
    )
  }

  renderAvailability(override) {
    return (
      <Text>
        {I18n.t('Available ')}
        <AvailabilityDates assignment={override} formatStyle="short" />
      </Text>
    )
  }

  render() {
    const override = this.props.override
    if (override) {
      return (
        <View as="div">
          <Flex justifyItems="space-between">
            <FlexItem grow>
              <Flex direction="column">
                <FlexItem>{this.renderTitle(override)}</FlexItem>
                <FlexItem>{this.renderAttemptsAllowed(override)}</FlexItem>
              </Flex>
            </FlexItem>
            <FlexItem>
              <Flex direction="column" textAlign="end" justifyItems="end">
                <FlexItem>{this.renderSubmissionTypesAndDueDate(override)}</FlexItem>
                <FlexItem>{this.renderAvailability(override)}</FlexItem>
              </Flex>
            </FlexItem>
          </Flex>
        </View>
      )
    }
    return <View as="div" />
  }
}
