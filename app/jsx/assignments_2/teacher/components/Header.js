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
import Heading from '@instructure/ui-elements/lib/components/Heading'
import Text from '@instructure/ui-elements/lib/components/Text'
import TruncateText from '@instructure/ui-elements/lib/components/TruncateText'
import Grid, {GridRow, GridCol} from '@instructure/ui-layout/lib/components/Grid'
import AssignmentIcon from '@instructure/ui-icons/lib/Line/IconAssignment'

import {TeacherAssignmentShape} from '../assignmentData'
import TeacherViewContext from './TeacherViewContext'
import Toolbox from './Toolbox'

export default class Header extends React.Component {
  static contextType = TeacherViewContext

  static propTypes = {
    assignment: TeacherAssignmentShape.isRequired,
    onUnsubmittedClick: func,
    onPublishChange: func
  }

  static defaultProps = {
    onUnsubmittedClick: () => {},
    onPublishChange: () => {}
  }

  renderIcon() {
    return <AssignmentIcon size="x-small" />
  }

  renderType() {
    return (
      <Text transform="uppercase" size="x-small" letterSpacing="expanded">
        {I18n.t('Assignment')}
      </Text>
    )
  }

  renderModules() {
    if (this.props.assignment.modules.length === 0) {
      return <div />
    }
    return (
      <Text>
        <TruncateText>
          {this.props.assignment.modules.map(module => module.name).join(' | ')}
        </TruncateText>
      </Text>
    )
  }

  renderAssignmentGroup() {
    return (
      <Text>
        <TruncateText>{this.props.assignment.assignmentGroup.name}</TruncateText>
      </Text>
    )
  }

  render() {
    return (
      <Grid startAt="large" colSpacing="large">
        <GridRow>
          <GridCol>
            <Flex direction="column">
              <FlexItem padding="small 0 medium">
                {this.renderIcon()} {this.renderType()}
              </FlexItem>
              <FlexItem padding="xx-small 0 0">{this.renderModules()}</FlexItem>
              <FlexItem padding="xx-small 0 0">{this.renderAssignmentGroup()}</FlexItem>
              <FlexItem padding="medium 0 large">
                <Heading as="div" level="h1">
                  {this.props.assignment.name}
                </Heading>
              </FlexItem>
            </Flex>
          </GridCol>
          <GridCol width="auto" textAlign="end">
            <Toolbox {...this.props} />
          </GridCol>
        </GridRow>
      </Grid>
    )
  }
}
