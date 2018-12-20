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

import EditableNumber from './Editables/EditableNumber'
import {TeacherAssignmentShape} from '../assignmentData'

// let's use these helpers from the gradebook so we're consistent
import {
  hasSubmitted,
  hasSubmission
} from '../../../gradezilla/shared/helpers/messageStudentsWhoHelper'

export default class Toolbox extends React.Component {
  static propTypes = {
    assignment: TeacherAssignmentShape.isRequired,
    onUnsubmittedClick: func,
    onPublishChange: func,
    onDelete: func
  }

  static defaultProps = {
    onUnsubmittedClick: () => {},
    onPublishChange: () => {},
    onDelete: () => {}
  }

  submissions() {
    // TODO: We will need to exhaust the submissions pagination for this to work correctly
    return this.props.assignment.submissions.nodes
  }

  countSubmissions(fn) {
    return this.submissions().reduce((memo, submission) => memo + (fn(submission) ? 1 : 0), 0)
  }

  constructor(props) {
    super(props)

    this.state = {
      pointsMode: 'view',
      pointsValue: this.props.assignment.pointsPossible
    }
  }

  handlePublishChange = event => {
    const newState = event.target.checked ? 'published' : 'unpublished'
    this.props.onPublishChange(newState)
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
        onChange={this.handlePublishChange}
      />
    )
  }

  renderDelete() {
    return (
      <Button margin="0 0 0 x-small" icon={<IconTrash />} onClick={this.props.onDelete}>
        <ScreenReaderContent>{I18n.t('delete assignment')}</ScreenReaderContent>
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
          {I18n.t('%{number} to grade', {number: this.props.assignment.needsGradingCount})}
        </Text>
      </Link>
    )
  }

  renderUnsubmittedButton() {
    const unsubmittedCount = this.countSubmissions(submission => !hasSubmitted(submission))
    return this.renderMessageStudentsWhoButton(
      I18n.t('%{number} unsubmitted', {number: unsubmittedCount})
    )
  }

  renderMessageStudentsWhoButton(text) {
    return (
      <Link icon={<IconEmail />} iconPlacement="end" onClick={this.props.onUnsubmittedClick}>
        <Text transform="uppercase" size="small" color="primary">
          {text}
        </Text>
      </Link>
    )
  }

  renderSubmissionStats() {
    return hasSubmission(this.props.assignment) ? (
      [
        <FlexItem key="unsubmitted" padding="xx-small xx-small xxx-small">
          {this.renderSpeedGraderLink()}
        </FlexItem>,
        <FlexItem key="to grade" padding="xxx-small xx-small">
          {this.renderUnsubmittedButton()}
        </FlexItem>
      ]
    ) : (
      <FlexItem padding="xx-small xx-small xxx-small">
        {this.renderMessageStudentsWhoButton(I18n.t('Message Students Who'))}
      </FlexItem>
    )
  }

  renderPoints() {
    const sty = this.state.pointsMode === 'view' ? {marginTop: '7px'} : {}
    return (
      <div style={sty}>
        <Flex alignItems="center">
          <FlexItem margin="0 x-small 0 0">
            <EditableNumber
              mode={this.state.pointsMode}
              inline
              size="large"
              value={this.state.pointsValue}
              onChange={this.handlePointsChange}
              onChangeMode={this.handlePointsChangeMode}
              label={I18n.t('Edit Points')}
              editButtonPlacement="start"
              invalidMessage={I18n.t('Points must be >= 0')}
              required
            />
          </FlexItem>
          <FlexItem>
            <Text size="large">{I18n.t('Points')}</Text>
          </FlexItem>
        </Flex>
      </div>
    )
  }

  handlePointsChange = value => {
    this.setState({pointsValue: value})
  }

  handlePointsChangeMode = mode => {
    this.setState({pointsMode: mode})
  }

  render() {
    return (
      <div data-testid="teacher-toolbox">
        <Flex direction="column">
          <FlexItem padding="xx-small xx-small small">
            {this.renderPublished()}
            {this.renderDelete()}
          </FlexItem>
          {this.renderSubmissionStats()}
          <FlexItem padding="medium xx-small large" align="end">
            {this.renderPoints()}
          </FlexItem>
        </Flex>
      </div>
    )
  }
}
