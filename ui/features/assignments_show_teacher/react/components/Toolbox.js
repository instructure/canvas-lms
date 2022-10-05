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
import {bool, func} from 'prop-types'

import {useScope as useI18nScope} from '@canvas/i18n'

import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {IconTrashLine} from '@instructure/ui-icons'
import {TeacherAssignmentShape} from '../assignmentData'
import AssignmentPoints from './Editables/AssignmentPoints'

const I18n = useI18nScope('assignments_2')

export default class Toolbox extends React.Component {
  static propTypes = {
    assignment: TeacherAssignmentShape.isRequired,
    onChangeAssignment: func.isRequired,
    onValidate: func.isRequired,
    invalidMessage: func.isRequired,
    onSetWorkstate: func.isRequired,
    onDelete: func,
    readOnly: bool,
  }

  static defaultProps = {
    onDelete: () => {},
    readOnly: false,
  }

  state = {
    pointsMode: 'view',
  }

  // TODO: publish => save all pending edits, including state
  //     unpublish => just update state
  // so if event.target.checked, we need to call back up to whatever will
  // do the save.
  handlePublishChange = event => {
    const newState = event.target.checked ? 'published' : 'unpublished'
    this.props.onSetWorkstate(newState)
  }

  renderPublished() {
    // TODO: put the label on the left side of the toggle when checkbox supports it
    // TODO: handle error when updating published
    return (
      <Checkbox
        label={I18n.t('Published')}
        variant="toggle"
        size="medium"
        inline={true}
        checked={this.props.assignment.state === 'published'}
        onChange={this.handlePublishChange}
      />
    )
  }

  renderDelete() {
    return (
      <Button margin="0 0 0 x-small" renderIcon={<IconTrashLine />} onClick={this.props.onDelete}>
        <ScreenReaderContent>{I18n.t('delete assignment')}</ScreenReaderContent>
      </Button>
    )
  }

  renderPoints() {
    return (
      <AssignmentPoints
        mode={this.state.pointsMode}
        pointsPossible={this.props.assignment.pointsPossible}
        onChange={this.handlePointsChange}
        onChangeMode={this.handlePointsChangeMode}
        onValidate={this.props.onValidate}
        invalidMessage={this.props.invalidMessage}
        readOnly={this.props.readOnly}
      />
    )
  }

  handlePointsChange = value => {
    this.props.onChangeAssignment('pointsPossible', value)
  }

  handlePointsChangeMode = mode => {
    this.setState({pointsMode: mode})
  }

  render() {
    return (
      <div data-testid="teacher-toolbox">
        <Flex direction="column">
          <Flex.Item padding="xx-small xx-small small">
            {this.renderPublished()}
            {this.renderDelete()}
          </Flex.Item>
          <Flex.Item padding="medium xx-small large" align="end">
            {this.renderPoints()}
          </Flex.Item>
        </Flex>
      </div>
    )
  }
}
