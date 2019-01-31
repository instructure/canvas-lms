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

import Checkbox from '@instructure/ui-forms/lib/components/Checkbox'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import Link from '@instructure/ui-elements/lib/components/Link'
import Text from '@instructure/ui-elements/lib/components/Text'
import Button from '@instructure/ui-buttons/lib/components/Button'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'

import IconEmail from '@instructure/ui-icons/lib/Line/IconEmail'
import IconSpeedGrader from '@instructure/ui-icons/lib/Line/IconSpeedGrader'
import IconTrash from '@instructure/ui-icons/lib/Line/IconTrash'

import {TeacherAssignmentShape} from '../assignmentData'

export default class Toolbox extends React.Component {
  static propTypes = {
    assignment: TeacherAssignmentShape.isRequired,
    onUnsubmittedClick: func,
    onPublishChange: func
  }

  static defaultProps = {
    onUnsubmittedClick: () => {},
    onPublishChange: () => {}
  }

  renderPublished() {
    // TODO: put the label on the left side of the toggle when checkbox supports it
    return (
      <Checkbox
        label={I18n.t('Published')}
        variant="toggle"
        size="medium"
        inline
        checked={this.props.assignment.state === 'published'}
        onChange={this.props.onPublishChange}
      />
    )
  }

  renderDelete() {
    return (
      <Button margin="0 0 0 x-small" icon={<IconTrash />}>
        <ScreenReaderContent>{I18n.t('Delete')}</ScreenReaderContent>
      </Button>
    )
  }

  renderSpeedGraderLink() {
    const assignmentLid = this.props.assignment.lid
    const courseLid = this.props.assignment.course.lid
    const speedgraderLink = `/courses/${courseLid}/gradebook/speed_grader?assignment_id=${assignmentLid}`
    return (
      <Link href={speedgraderLink} icon={<IconSpeedGrader />} iconPlacement="end" target="_blank">
        <Text transform="uppercase" size="small" color="primary">
          {I18n.t('%{number} to grade', {number: 'X'})}
        </Text>
      </Link>
    )
  }

  renderUnsubmittedButton() {
    return (
      <Link icon={<IconEmail />} iconPlacement="end" onClick={this.props.onUnsubmittedClick}>
        <Text transform="uppercase" size="small" color="primary">
          {I18n.t('%{number} unsubmitted', {number: 'X'})}
        </Text>
      </Link>
    )
  }

  renderPoints() {
    return (
      <Text as="div" size="x-large" lineHeight="fit">
        {this.props.assignment.pointsPossible}
      </Text>
    )
  }

  renderPointsLabel() {
    return (
      <Text as="div" lineHeight="fit">
        {I18n.t('Points')}
      </Text>
    )
  }

  render() {
    return (
      <div data-testid="teacher-toolbox">
        <Flex direction="column">
          <FlexItem padding="xx-small xx-small small">
            {this.renderPublished()}
            {this.renderDelete()}
          </FlexItem>
          <FlexItem padding="xx-small xx-small xxx-small">{this.renderSpeedGraderLink()}</FlexItem>
          <FlexItem padding="xxx-small xx-small">{this.renderUnsubmittedButton()}</FlexItem>
          <FlexItem padding="medium xx-small large">
            {this.renderPoints()}
            {this.renderPointsLabel()}
          </FlexItem>
        </Flex>
      </div>
    )
  }
}
