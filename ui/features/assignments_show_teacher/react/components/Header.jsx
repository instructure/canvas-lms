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

import {View} from '@instructure/ui-view'
import {Grid} from '@instructure/ui-grid'

import {TeacherAssignmentShape} from '../assignmentData'
import TeacherViewContext from './TeacherViewContext'
import Toolbox from './Toolbox'
import AssignmentName from './Editables/AssignmentName'
import AssignmentModules from './Editables/AssignmentModules'
import AssignmentType from './Editables/AssignmentType'
import AssignmentGroup from './Editables/AssignmentGroup'

const I18n = useI18nScope('assignments_2')

// TODO: the assignment type and module selection need to be factored out into
// their own components. too much logic to cram in here

const confirmQuizType = I18n.t(
  'Quizzes are not yet handled in the new assignments flow. Head to the legacy create quiz page?'
)
const confirmPeerReviewType = I18n.t(
  'Peer reviewed assignments are not yet handled in the new assignments flow. Head to the legacy create assignment page?'
)
const confirmGroupType = I18n.t(
  'Creating a group is not yet handled by the new assignments flow. Head to the legacy assignments page?'
)

function assignmentIsNew(assignment) {
  return !assignment.lid
}

// TODO: if the Header is initially rendered with all items in edit mode
// because we're creating a new assignment, then the logic for getting the
// list of available modules and groups will not work

export default class Header extends React.Component {
  static contextType = TeacherViewContext

  static propTypes = {
    assignment: TeacherAssignmentShape.isRequired,
    onChangeAssignment: func.isRequired,
    onValidate: func.isRequired,
    invalidMessage: func.isRequired,
    onSetWorkstate: func.isRequired,
    onPublishChange: func,
    onDelete: func,
    readOnly: bool,
  }

  static defaultProps = {
    onPublishChange: () => {},
    onDelete: () => {},
    readOnly: false,
  }

  constructor(props) {
    super(props)

    const isNewAssignment = assignmentIsNew(props.assignment)
    const initialMode = !props.readOnly && isNewAssignment ? 'edit' : 'view'
    this.state = {
      assignmentTypeMode: initialMode,
      selectedAssignmentType: isNewAssignment ? null : 'assignment',

      modulesMode: initialMode,

      assignmentGroupMode: initialMode,

      nameMode: initialMode,
    }
  }

  handleTypeModeChange = mode => {
    this.setState({assignmentTypeMode: mode})
  }

  /* eslint-disable no-alert */
  handleTypeChange = selectedType => {
    switch (selectedType) {
      case 'assignment':
        break
      case 'quiz':
        if (window.confirm(confirmQuizType)) {
          // must be true, because that's the only way quiz is an option
          if (ENV.QUIZ_LTI_ENABLED) {
            window.location.assign(
              `/courses/${this.props.assignment.course.lid}/assignments/new?quiz_lti`
            )
          }
        }
        break
      case 'peer-review':
        if (window.confirm(confirmPeerReviewType)) {
          window.location.assign(`/courses/${this.props.assignment.course.lid}/assignments/new`)
        }
        break
      case 'group':
        if (window.confirm(confirmGroupType)) {
          window.location.assign(`/courses/${this.props.assignment.course.lid}/assignments/new`)
        }
        break
    }
    // Awkward, but there's a delicate interaction between Header, AssignmentType,
    // and SelectableText so that we have to update our state to reflect the new
    // selectedType, even though it's an invalid value, then set it back
    // to assignment.
    // Without this, AssignmentType's props don't change, it won't rerender, so
    // it doesn't rerender SelectableText which still holds the value the user selected.
    // I was hoping there was a cleaner way of doing this, but I'm stumped.
    this.setState({selectedAssignmentType: selectedType}, () => {
      this.forceUpdate()
      this.setState({
        selectedAssignmentType: 'assignment', // can't change it yet
      })
    })
  }
  /* eslint-enable no-alert */

  handleModulesChange = selectedModules => {
    this.props.onChangeAssignment('modules', selectedModules)
  }

  handleModulesChangeMode = mode => {
    this.setState({modulesMode: mode})
  }

  // TODO: support +Module
  // handleAddModule = (newModule, currentSelection) => {
  //   // get the new module created
  //   const newlyCreatedModule = {...newModule, lid: '9999'}
  //   this.setState((prevState, _prevProps) => ({
  //     selectedModules: currentSelection.concat([newlyCreatedModule]),
  //     moduleList: prevState.moduleList.concat([newlyCreatedModule])
  //   }))
  // }

  handleGroupChange = selectedAssignmentGroup => {
    this.props.onChangeAssignment('assignmentGroup', selectedAssignmentGroup)
  }

  handleGroupChangeMode = mode => {
    this.setState({assignmentGroupMode: mode})
  }

  handleNameChange = name => {
    this.props.onChangeAssignment('name', name)
  }

  handleNameChangeMode = mode => {
    this.setState({nameMode: mode})
  }

  render() {
    const assignment = this.props.assignment
    return (
      <Grid startAt="large" colSpacing="large">
        <Grid.Row>
          <Grid.Col>
            <View display="block" padding="small 0 medium xx-small">
              <AssignmentType
                mode={this.state.assignmentTypeMode}
                selectedAssignmentType={this.state.selectedAssignmentType}
                onChange={this.handleTypeChange}
                onChangeMode={this.handleTypeModeChange}
                readOnly={this.props.readOnly}
              />
            </View>
            <View display="block" padding="xx-small 0 0 xx-small">
              <AssignmentModules
                mode={this.state.modulesMode}
                courseId={assignment.course.lid}
                selectedModules={assignment.modules}
                onChange={this.handleModulesChange}
                onChangeMode={this.handleModulesChangeMode}
                onAddModule={this.handleAddModule}
                readOnly={this.props.readOnly}
              />
            </View>
            <View display="block" padding="xx-small 0 0 xx-small">
              <AssignmentGroup
                mode={this.state.assignmentGroupMode}
                courseId={assignment.course.lid}
                selectedAssignmentGroup={assignment.assignmentGroup}
                onChange={this.handleGroupChange}
                onChangeMode={this.handleGroupChangeMode}
                onAddGroup={this.handleAddGroup}
                readOnly={this.props.readOnly}
              />
            </View>
            <View display="block" padding="medium xx-small large xx-small">
              <AssignmentName
                mode={this.state.nameMode}
                name={assignment.name}
                onChange={this.handleNameChange}
                onChangeMode={this.handleNameChangeMode}
                onValidate={this.props.onValidate}
                invalidMessage={this.props.invalidMessage}
                readOnly={this.props.readOnly}
              />
            </View>
          </Grid.Col>
          <Grid.Col width="auto" textAlign="end">
            <Toolbox {...this.props} />
          </Grid.Col>
        </Grid.Row>
      </Grid>
    )
  }
}
