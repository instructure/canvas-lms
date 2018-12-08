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
import {func} from 'prop-types'

import I18n from 'i18n!assignments_2'

import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import Text from '@instructure/ui-elements/lib/components/Text'

import {AssignmentShape} from '../shapes'
import Toolbox from './Toolbox'

export default class Header extends React.Component {
  static propTypes = {
    assignment: AssignmentShape.isRequired,
    onUnsubmittedClick: func,
    onPublishChange: func
  }

  renderPoints() {
    return (
      <span style={{lineHeight: '1'}}>
        <Text size="x-large">{this.props.assignment.pointsPossible}</Text>
      </span>
    )
  }

  renderPointsLabel() {
    return <Text weight="bold">{I18n.t('Points')}</Text>
  }

  render() {
    return (
      <Flex as="div" justifyItems="space-between">
        <FlexItem>
          <h1>{this.props.assignment.name}</h1>
        </FlexItem>
        <FlexItem>
          <Flex direction="column" textAlign="end">
            <FlexItem>
              <Toolbox {...this.props} />
            </FlexItem>
            <FlexItem padding="medium 0 0 0">{this.renderPoints()}</FlexItem>
            <FlexItem>{this.renderPointsLabel()}</FlexItem>
          </Flex>
        </FlexItem>
      </Flex>
    )
  }
}
