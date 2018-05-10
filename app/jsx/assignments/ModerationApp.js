/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import _ from 'underscore'
import React from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!moderated_grading'
import ModeratedStudentList from './ModeratedStudentList'
import Header from './ModerationHeader'
import FlashMessageHolder from './FlashMessageHolder'
import Actions from './actions/ModerationActions'
import ModeratedColumnHeader from './ModeratedColumnHeader'

export default React.createClass({
  displayName: 'ModerationApp',

  propTypes: {
    store: PropTypes.object.isRequired,
    permissions: PropTypes.shape({
      viewGrades: PropTypes.bool.isRequired,
      editGrades: PropTypes.bool.isRequired
    }).isRequired
  },

  getInitialState () {
    return this.props.store.getState();
  },

  componentDidMount () {
    this.props.store.subscribe(this.handleChange);
    this.props.store.dispatch(Actions.apiGetStudents());
  },

  handleChange () {
    this.setState(this.props.store.getState());
  },

  handleCheckbox (student, event) {
    if (event.target.checked) {
      this.props.store.dispatch(Actions.selectStudent(student.id));
    } else {
      this.props.store.dispatch(Actions.unselectStudent(student.id));
    }
  },

  isModerationSet (students) {
    return !!(_.find(students, (student) => {
      return student.in_moderation_set;
    }));
  },
  handleSelectAll (event) {
    if (event.target.checked) {
      var allStudents = this.props.store.getState().students;
      this.props.store.dispatch(Actions.selectAllStudents(allStudents));
    } else {
      this.props.store.dispatch(Actions.unselectAllStudents());
    }
  },
  render () {
    return (
      <div className="ModerationApp">
        <FlashMessageHolder {...this.state.flashMessage} />
        <h1 className="screenreader-only">{I18n.t('Moderate %{assignment_name}', {assignment_name: this.state.assignment.title})}</h1>
        <Header
          anonymousModeratedMarkingEnabled={this.state.assignment.anonymousModeratedMarkingEnabled}
          onPublishClick={
            () => {
              this.props.store.dispatch(Actions.publishStarted());
              this.props.store.dispatch(Actions.publishGrades())
            }
          }
          onReviewClick={
            () => {
              this.props.store.dispatch(Actions.moderationStarted());
              this.props.store.dispatch(Actions.addStudentToModerationSet());
            }
          }
          onUnmuteClick={
            () => {
              this.props.store.dispatch(Actions.unmuteStarted());
              this.props.store.dispatch(Actions.unmuteAssignment());
            }
          }
          published={this.state.assignment.published}
          muted={this.state.assignment.muted}
          selectedStudentCount={this.state.studentList.selectedCount}
          inflightAction={this.state.inflightAction}
          permissions={this.props.permissions}
        />

        <table width="100%" className="grade-moderation-table">
          <caption className="screenreader-only">{I18n.t('Clicking on the column headers will sort the rows by that column.')}</caption>

          <ModeratedColumnHeader
            includeModerationSetHeaders={this.isModerationSet(this.state.studentList.students)}
            sortDirection={this.state.studentList.sort.direction}
            markColumn={this.state.studentList.sort.column}
            store={this.props.store}
            handleSortMark1={() => this.props.store.dispatch(Actions.sortMark1Column())}
            handleSortMark2={() => this.props.store.dispatch(Actions.sortMark2Column())}
            handleSortMark3={() => this.props.store.dispatch(Actions.sortMark3Column())}
            handleSelectAll={this.handleSelectAll}
            permissions={this.props.permissions}
          />

          <ModeratedStudentList
            includeModerationSetColumns={this.isModerationSet(this.state.studentList.students)}
            handleCheckbox={this.handleCheckbox}
            onSelectProvisionalGrade={
              provisionalGradeId => this.props.store.dispatch(Actions.selectProvisionalGrade(provisionalGradeId))
            }
            studentList={this.state.studentList}
            assignment={this.state.assignment}
            urls={this.state.urls}
          />
        </table>
      </div>
    );
  }
});
