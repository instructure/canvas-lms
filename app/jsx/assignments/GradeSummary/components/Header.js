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

import React, {Component} from 'react'
import {connect} from 'react-redux'
import {bool, func, oneOf, shape, string} from 'prop-types'
import Alert from '@instructure/ui-alerts/lib/components/Alert'
import Heading from '@instructure/ui-elements/lib/components/Heading'
import Text from '@instructure/ui-elements/lib/components/Text'
import View from '@instructure/ui-layout/lib/components/View'
import I18n from 'i18n!assignment_grade_summary'

import * as AssignmentActions from '../assignment/AssignmentActions'
import DisplayToStudentsButton from './DisplayToStudentsButton'
import PostButton from './PostButton'

/* eslint-disable no-alert */

function enumeratedStatuses(actions) {
  return [actions.FAILURE, actions.STARTED, actions.SUCCESS]
}

class Header extends Component {
  static propTypes = {
    assignment: shape({
      title: string.isRequired
    }).isRequired,
    publishGrades: func.isRequired,
    publishGradesStatus: oneOf(enumeratedStatuses(AssignmentActions)),
    showNoGradersMessage: bool.isRequired,
    unmuteAssignment: func.isRequired,
    unmuteAssignmentStatus: oneOf(enumeratedStatuses(AssignmentActions))
  }

  static defaultProps = {
    publishGradesStatus: null,
    unmuteAssignmentStatus: null
  }

  constructor(props) {
    super(props)

    this.handlePublishClick = this.handlePublishClick.bind(this)
    this.handleUnmuteClick = this.handleUnmuteClick.bind(this)
  }

  handlePublishClick() {
    const message = I18n.t(
      'Are you sure you want to do this? It cannot be undone and will override existing grades in the gradebook.'
    )
    if (window.confirm(message)) {
      this.props.publishGrades()
    }
  }

  handleUnmuteClick() {
    const message = I18n.t(
      'Are you sure you want to display grades for this assignment to students?'
    )
    if (window.confirm(message)) {
      this.props.unmuteAssignment()
    }
  }

  render() {
    return (
      <header>
        {this.props.assignment.gradesPublished && (
          <Alert margin="0 0 medium 0" variant="info">
            <Text weight="bold">{I18n.t('Attention!')}</Text>{' '}
            {I18n.t('Grades cannot be modified from this page as they have already been posted.')}
          </Alert>
        )}

        {this.props.showNoGradersMessage && (
          <Alert margin="0 0 medium 0" variant="warning">
            {I18n.t(
              'Moderation is unable to occur at this time due to grades not being submitted.'
            )}
          </Alert>
        )}

        <Heading level="h1" margin="0 0 x-small 0">
          {I18n.t('Grade Summary')}
        </Heading>

        <Text size="x-large">{this.props.assignment.title}</Text>

        <View as="div" margin="large 0 0 0" textAlign="end">
          <PostButton
            gradesPublished={this.props.assignment.gradesPublished}
            margin="0 x-small 0 0"
            onClick={this.handlePublishClick}
            publishGradesStatus={this.props.publishGradesStatus}
          />

          <DisplayToStudentsButton
            assignment={this.props.assignment}
            onClick={this.handleUnmuteClick}
            unmuteAssignmentStatus={this.props.unmuteAssignmentStatus}
          />
        </View>
      </header>
    )
  }
}

function mapStateToProps(state) {
  const {assignment, publishGradesStatus, unmuteAssignmentStatus} = state.assignment

  return {
    assignment,
    publishGradesStatus,
    showNoGradersMessage: !assignment.gradesPublished && state.context.graders.length === 0,
    unmuteAssignmentStatus
  }
}

function mapDispatchToProps(dispatch) {
  return {
    publishGrades() {
      dispatch(AssignmentActions.publishGrades())
    },

    unmuteAssignment() {
      dispatch(AssignmentActions.unmuteAssignment())
    }
  }
}

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(Header)
