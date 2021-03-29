/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import I18n from 'i18n!discussion_posts'

import PropTypes from 'prop-types'
import React from 'react'

import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'

export function Alert({...props}) {
  return (
    <Flex data-testid="graded-discussion-info">
      <Flex.Item padding="x-small" align="start">
        <Text weight="light" size="small">
          {props.contextDisplayText}
        </Text>
      </Flex.Item>
      <Flex.Item padding="x-small" shouldGrow align="start">
        <Text weight="light" size="small">
          {I18n.t('This is a graded discussion: %{pointsPossible} points possible', {
            pointsPossible: props.pointsPossible
          })}
        </Text>
      </Flex.Item>
      <Flex.Item padding="x-small" align="end">
        <Text weight="light" size="small">
          {I18n.t('Due: %{dueAtDisplayText}', {dueAtDisplayText: props.dueAtDisplayText})}
        </Text>
      </Flex.Item>
    </Flex>
  )
}

Alert.propTypes = {
  contextDisplayText: PropTypes.string.isRequired,
  pointsPossible: PropTypes.number.isRequired,
  dueAtDisplayText: PropTypes.string.isRequired
}

export default Alert
