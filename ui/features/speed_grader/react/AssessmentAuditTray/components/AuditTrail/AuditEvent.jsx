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
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Badge} from '@instructure/ui-badge'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Focusable} from '@instructure/ui-focusable'

import {Tooltip} from '@instructure/ui-tooltip'

import {useScope as useI18nScope} from '@canvas/i18n'

import {
  auditEventStudentAnonymityStates,
  iconFor,
  labelFor,
  snippetFor,
} from '../../AuditTrailHelpers'
import * as propTypes from './propTypes'

const I18n = useI18nScope('speed_grader')

const {OFF, TURNED_OFF} = auditEventStudentAnonymityStates

export default class AuditEvent extends PureComponent {
  static propTypes = {
    ...propTypes.auditEventInfo,
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
              <View as="div" padding="none none none small" data-testid="audit_event_badge">
                <Tooltip
                  on={['click', 'focus', 'hover']}
                  placement="start"
                  renderTip={message}
                  color="primary"
                >
                  <View as="div" withFocusOutline={focused}>
                    {innerView}
                  </View>
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
        <Flex.Item as="div" margin="none">
          {iconView}
        </Flex.Item>

        <Flex.Item as="div" showGrow={true} shouldShrink={true} margin="none none none x-small">
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
        </Flex.Item>
      </Flex>
    )
  }
}
