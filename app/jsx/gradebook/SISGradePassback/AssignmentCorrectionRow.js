/*
 * Copyright (C) 2014 - present Instructure, Inc.
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
import I18n from 'i18n!modules'
import React from 'react'
import assignmentUtils from '../../gradebook/SISGradePassback/assignmentUtils'
import classnames from 'classnames'

  var AssignmentCorrectionRow = React.createClass({
    componentDidMount() {
      this.initDueAtDateTimeField()
    },

    handleDateChanged(e) {
      //send date chosen in jquery date-picker so that
      //the assignment or assignment override due_at is set
      var $picker = $(this.refs.due_at.getDOMNode())
      this.props.onDateChanged($picker.data('date'))
    },

    initDueAtDateTimeField() {
      var $picker = $(this.refs.due_at.getDOMNode())
      $picker.datetime_field().change(this.handleDateChanged)
    },

    ignoreAssignment(e) {
      e.preventDefault()
      this.props.updateAssignment({please_ignore: true})
    },

    // The real 'change' event for due_at happens in initDueAtDateTimeField,
    // but we need to check a couple of things during keypress events to
    // maintain assignment state consistency
    checkDueAtChange(e) {
      if(this.props.assignment.overrideForThisSection != undefined) {
        if (e.target.value == "") {
          $picker = $(this.refs.due_at.getDOMNode()).data("date", null)
          this.props.assignment.due_at = null
        }
        // When a user edits the due_at datetime field, we should reset any
        // previous "please_ignore" request
        this.props.updateAssignment({please_ignore: false})
      }
      else {
        if (e.target.value == "") {
          $picker = $(this.refs.due_at.getDOMNode()).data("date", null)
          this.props.updateAssignment({due_at: null})
        }
        // When a user edits the due_at datetime field, we should reset any
        // previous "please_ignore" request
        this.props.updateAssignment({please_ignore: false})
      }

    },

    updateAssignmentName(e) {
      this.props.updateAssignment({name: e.target.value, please_ignore: false})
    },

    currentSectionforOverride(a) {
      if(_.isEmpty(_.where(a.overrides, {course_section_id: a.currentlySelected.id.toString()})) || a.currentlySelected.type == 'course'){
        return true
      } else {
        return false
      }
    },

    validCheck(a) {
      if(a.overrideForThisSection != undefined && a.currentlySelected.type == 'course'){
        return a.due_at != null ? true : false
      }
      else if(a.overrideForThisSection != undefined && a.currentlySelected.type == 'section' && a.currentlySelected.id.toString() == a.overrideForThisSection.course_section_id){
        return a.overrideForThisSection.due_at != null ? true : false
      }
      else{
        return true
      }
    },

    render() {
      var assignment = this.props.assignment;
      var assignmentList = this.props.assignmentList;
      var rowClass = classnames({
        "row": true,
        "correction-row": true,
        "ignore-row": assignment.please_ignore
      })

      var nameEmptyError = assignmentUtils.nameEmpty(assignment) && !assignment.please_ignore
      var nameTooLongError = assignmentUtils.nameTooLong(assignment) && !assignment.please_ignore
      var nameError = assignmentUtils.notUniqueName(assignmentList, assignment) && !assignment.please_ignore
      var dueAtError = !assignment.due_at && !assignment.please_ignore
      var default_value = null
      var place_holder = null

      //dueAtError will always return true when assignments have overrides so we want to check and see if the
      //assignment override in the section has a due_at date
      if(assignment.overrideForThisSection != undefined && assignment.overrideForThisSection.due_at != null){
        dueAtError = false
      }

      //handles data being filled in the inputs if there are name issues on an assignment with an assignment override
      if(assignment.overrideForThisSection != undefined){
        default_value = $.datetimeString(assignment.overrideForThisSection.due_at, {format: 'medium'})
        place_holder = assignment.overrideForThisSection.due_at ? null : I18n.t('No Due Date')
      }
      else{
        default_value = $.datetimeString(assignment.due_at, {format: 'medium'})
        place_holder = assignment.due_at ? null : I18n.t("No Due Date")
      }

      //handles 'Everyone Else' scenario
      if(assignmentUtils.noDueDateForEveryoneElseOverride(assignment) && this.currentSectionforOverride(assignment)){
        default_value = $.datetimeString(assignment.due_at, {format: 'medium'})
        dueAtError = true
      }

      var anyError = nameError || dueAtError || nameTooLongError || nameEmptyError
      return (
        <div className={rowClass}>
          <div className="span3 input-container">
            {anyError || assignment.please_ignore ? null : <i className="success-mark icon-check" />}
            <div
              className={classnames({
                "error-circle": nameError || nameTooLongError || nameEmptyError
              })}
            >
              <label className="screenreader-only">{I18n.t("Name Error")}</label>
            </div>
            <input
              ref="name"
              type="text"
              aria-label={I18n.t("Assignment Name")}
              className="input-mlarge assignment-name"
              placeholder={assignment.name ? null : I18n.t("No Assignment Name")}
              defaultValue={_.unescape(assignment.name)}
              onChange={this.updateAssignmentName}
            />
            {nameError ? <div className="hint-text">The assignment name must be unique</div> : ""}
            {nameTooLongError ? <div className="hint-text">The name must be under 30 characters</div> : ""}
            {nameEmptyError ? <div className="hint-text">The name must not be empty</div> : ""}
          </div>

          <div className="span2 date_field_container input-container assignment_correction_input">
            <div
              className={classnames({
                "error-circle": dueAtError
              })}
            >
              <label className="screenreader-only">{I18n.t("Date Error")}</label>
            </div>
            <input
              ref="due_at"
              type="text"
              aria-label={I18n.t("Due Date")}
              className="input-medium assignment-due-at"
              placeholder={place_holder}
              defaultValue={default_value}
              onChange={this.checkDueAtChange}
            />
            <button
              style={{visibility: assignment.please_ignore ? 'hidden' : ''}}
              className="btn btn-link btn-ignore assignment_correction_ignore"
              aria-label={I18n.t("Ignore %{name}", {name: assignment.name})}
              title={I18n.t("Ignore Assignment")}
              onClick={this.ignoreAssignment}
            ><i className="icon-minimize" /></button>
          </div>
        </div>
      )
    }
  })

export default AssignmentCorrectionRow
