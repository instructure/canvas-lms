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
import {arrayOf, func, oneOf, shape, string} from 'prop-types'
import {Alert} from '@instructure/ui-alerts'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'

import I18n from 'i18n!assignment_grade_summary'

import * as AssignmentActions from '../assignment/AssignmentActions'
import GradersTable from './GradersTable/index'
import PostToStudentsButton from './PostToStudentsButton'
import ReleaseButton from './ReleaseButton'

/* eslint-disable no-alert */

function enumeratedStatuses(actions) {
  return [actions.FAILURE, actions.STARTED, actions.SUCCESS]
}

class Header extends Component {
  static propTypes = {
    assignment: shape({
      title: string.isRequired
    }).isRequired,
    graders: arrayOf(
      shape({
        graderName: string,
        graderId: string.isRequired
      })
    ).isRequired,
    releaseGrades: func.isRequired,
    releaseGradesStatus: oneOf(enumeratedStatuses(AssignmentActions)),
    unmuteAssignment: func.isRequired,
    unmuteAssignmentStatus: oneOf(enumeratedStatuses(AssignmentActions))
  }

  static defaultProps = {
    releaseGradesStatus: null,
    unmuteAssignmentStatus: null
  }

  handleReleaseClick = () => {
    const message = I18n.t(
      'Are you sure you want to do this? It cannot be undone and will override existing grades in the gradebook.'
    )
    if (window.confirm(message)) {
      this.props.releaseGrades()
    }
  }

  handleUnmuteClick = () => {
    const message = I18n.t('Are you sure you want to post grades for this assignment to students?')
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
            {I18n.t('Grades cannot be modified from this page as they have already been released.')}
          </Alert>
        )}

        <Heading level="h1" margin="0 0 x-small 0">
          {I18n.t('Grade Summary')}
        </Heading>

        <Text size="x-large">{this.props.assignment.title}</Text>

        <Flex as="div" margin="large 0 0 0">
          {this.props.graders.length > 0 && (
            <Flex.Item as="div" flex="1" grow>
              <GradersTable />
            </Flex.Item>
          )}

          <Flex.Item align="end" as="div" flex="2" grow>
            <Flex as="div" justifyItems="end">
              <Flex.Item>
                <ReleaseButton
                  gradesReleased={this.props.assignment.gradesPublished}
                  margin="0 x-small 0 0"
                  onClick={this.handleReleaseClick}
                  releaseGradesStatus={this.props.releaseGradesStatus}
                />
              </Flex.Item>

              <Flex.Item>
                <PostToStudentsButton
                  assignment={this.props.assignment}
                  onClick={this.handleUnmuteClick}
                  unmuteAssignmentStatus={this.props.unmuteAssignmentStatus}
                />
              </Flex.Item>
            </Flex>
          </Flex.Item>
        </Flex>
      </header>
    )
  }
}

function mapStateToProps(state) {
  const {assignment, releaseGradesStatus, unmuteAssignmentStatus} = state.assignment

  return {
    assignment,
    graders: state.context.graders,
    releaseGradesStatus,
    unmuteAssignmentStatus
  }
}

function mapDispatchToProps(dispatch) {
  return {
    releaseGrades() {
      dispatch(AssignmentActions.releaseGrades())
    },

    unmuteAssignment() {
      dispatch(AssignmentActions.unmuteAssignment())
    }
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(Header)
/* eslint-enable no-alert */
