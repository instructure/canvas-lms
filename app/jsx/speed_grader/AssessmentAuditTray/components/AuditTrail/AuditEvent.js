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
import Badge from '@instructure/ui-elements/lib/components/Badge'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import Focusable, {FocusableView} from '@instructure/ui-focusable/lib/components/Focusable'
import TruncateText from '@instructure/ui-elements/lib/components/TruncateText'
import Text from '@instructure/ui-elements/lib/components/Text'
import Tooltip from '@instructure/ui-overlays/lib/components/Tooltip'
import View from '@instructure/ui-layout/lib/components/View'
import I18n from 'i18n!speed_grader'

import {
  auditEventStudentAnonymityStates,
  iconFor,
  labelFor,
  snippetFor
} from '../../AuditTrailHelpers'
import * as propTypes from './propTypes'

const {OFF, TURNED_OFF} = auditEventStudentAnonymityStates

export default class AuditEvent extends PureComponent {
  static propTypes = {
    ...propTypes.auditEventInfo
  }

  render() {
    const {auditEvent, studentAnonymity} = this.props

    const Icon = iconFor(auditEvent)
    const label = labelFor(auditEvent)
    const snippet = snippetFor(auditEvent)

    let iconView
    const innerView = (
      <View as="div" padding="xx-small">
        <Icon color="secondary" inline={false} />
      </View>
    )

    if (studentAnonymity === OFF || studentAnonymity === TURNED_OFF) {
      const message =
        studentAnonymity === OFF
          ? I18n.t('Action was not anonymous')
          : I18n.t('Anonymous was turned off')

      iconView = (
        <Focusable>
          {({focused}) => (
            <Badge placement="start center" type="notification" variant="danger">
              <View as="div" padding="none none none small">
                <Tooltip
                  on={['click', 'focus', 'hover']}
                  placement="start"
                  size="medium"
                  tip={message}
                  variant="inverse"
                >
                  <FocusableView as="div" focused={focused}>
                    {innerView}
                  </FocusableView>
                </Tooltip>
              </View>
            </Badge>
          )}
        </Focusable>
      )
    } else {
      iconView = (
        <View as="div" margin="none" padding="none none none small">
          {innerView}
        </View>
      )
    }

    return (
      <Flex alignItems="start" as="div" direction="row">
        <FlexItem as="div" margin="none">
          {iconView}
        </FlexItem>

        <FlexItem as="div" grow margin="none none none x-small" shrink>
          <Text as="div" weight="bold">
            <TruncateText maxLines={2}>{label}</TruncateText>
          </Text>

          {snippet && (
            <View as="p" margin="none">
              <Text size="small">
                <TruncateText maxLines={2}>{snippet}</TruncateText>
              </Text>
            </View>
          )}
        </FlexItem>
      </Flex>
    )
  }
}
