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
import DueDateTokenWrapper from '../due_dates/DueDateTokenWrapper'
import DueDateCalendars from '../due_dates/DueDateCalendars'
import DueDateRemoveRowLink from '../due_dates/DueDateRemoveRowLink'
import I18n from 'i18n!assignments'
import $ from 'jquery'


  var DueDateRow = React.createClass({

    propTypes: {
      overrides: PropTypes.array.isRequired,
      rowKey: PropTypes.string.isRequired,
      dates: PropTypes.object.isRequired,
      students: PropTypes.object.isRequired,
      sections: PropTypes.object.isRequired,
      groups: PropTypes.object.isRequired,
      validDropdownOptions: PropTypes.array.isRequired,
      handleDelete: PropTypes.func.isRequired,
      handleTokenAdd: PropTypes.func.isRequired,
      handleTokenRemove: PropTypes.func.isRequired,
      defaultSectionNamer: PropTypes.func.isRequired,
      replaceDate: PropTypes.func.isRequired,
      canDelete: PropTypes.bool.isRequired,
      currentlySearching: PropTypes.bool.isRequired,
      allStudentsFetched: PropTypes.bool.isRequired,
      inputsDisabled: PropTypes.bool.isRequired
    },

    // --------------------
    // Tokenizing Overrides
    // --------------------

    // this component takes overrides & returns a list of tokens:
    // 1 adhoc override => 1 token per student
    // 1 section override => 1 token for the section
    // 1 group override => 1 token for the group

    tokenizedOverrides(){
      var {sectionOverrides, groupOverrides, adhocOverrides, noopOverrides} = _.groupBy(this.props.overrides,
        (ov) => {
          if (ov.get("course_section_id")) {
            return "sectionOverrides"
          } else if (ov.get("group_id")) {
            return "groupOverrides"
          } else if (ov.get("noop_id")) {
            return "noopOverrides"
          } else {
            return "adhocOverrides"
          }
        }
      )

      return _.union(
        this.tokenizedSections(sectionOverrides),
        this.tokenizedGroups(groupOverrides),
        this.tokenizedAdhoc(adhocOverrides),
        this.tokenizedNoop(noopOverrides)
      )
    },

    tokenizedSections(sectionOverrides){
      var sectionOverrides = sectionOverrides || []
      return _.map(sectionOverrides, (override, index) => {
        return {
            id: `section-key-${index}`,
            type: "section",
            course_section_id: override.get("course_section_id"),
            name: this.nameForCourseSection(override.get("course_section_id"))
          }
      })
    },

    tokenizedGroups(groupOverrides){
      var groupOverrides = groupOverrides || []
      return _.map(groupOverrides, (override, index) => {
        return {
            id: `group-key-${index}`,
            type: "group",
            group_id: override.get("group_id"),
            name: this.nameForGroup(override.get("group_id"))
          }
      })
    },

    tokenizedAdhoc(adhocOverrides){
      var adhocOverrides = adhocOverrides || []
      return _.reduce(adhocOverrides, (overrideTokens, ov) => {
        var tokensForStudents = _.map(ov.get("student_ids"), this.tokenFromStudentId, this)
        return overrideTokens.concat(tokensForStudents)
      }, [])
    },

    tokenizedNoop(noopOverrides){
      var noopOverrides = noopOverrides || []
      return _.map(noopOverrides, (override, index) => {
        return {
            id: `noop-key-${index}`,
            noop_id: override.get("noop_id"),
            name: override.get("title")
          }
      })
    },

    tokenFromStudentId(studentId, index){
      return {
        id: `student-key-${index}`,
        type: "student",
        student_id: studentId,
        name: this.nameForStudentToken(studentId)
      }
    },

    nameForCourseSection(sectionId){
      var defaultName = this.props.defaultSectionNamer(sectionId)
      if(defaultName) return defaultName

      return this.nameOrLoading(
        this.props.sections,
        sectionId
      )
    },

    nameForGroup(groupId){
      return this.nameOrLoading(
        this.props.groups,
        groupId
      )
    },

    nameForStudentToken(studentId){
      return this.nameOrLoading(
        this.props.students,
        studentId
      )
    },

    nameOrLoading(collection, id){
      var item = collection[id]
      return item ? item["name"] : I18n.t("Loading...")
    },

    // -------------------
    //      Rendering
    // -------------------

    removeLinkIfNeeded(){
      if(this.props.canDelete && !this.props.inputsDisabled){
        return <DueDateRemoveRowLink handleClick={this.props.handleDelete}/>
      }
    },

    renderClosedGradingPeriodNotification() {
      if (this.props.inputsDisabled) {
        return (
          <span>{I18n.t("Due date falls in a closed Grading Period")}</span>
        )
      }
    },

    render() {
      return (
        <div className="Container__DueDateRow-item" role="region" aria-label={I18n.t("Due Date Set")} data-row-key={this.props.rowKey} >
          {this.removeLinkIfNeeded()}
          <DueDateTokenWrapper
            tokens              = {this.tokenizedOverrides()}
            disabled            = {this.props.inputsDisabled}
            handleTokenAdd      = {this.props.handleTokenAdd}
            handleTokenRemove   = {this.props.handleTokenRemove}
            potentialOptions    = {this.props.validDropdownOptions}
            rowKey              = {this.props.rowKey}
            defaultSectionNamer = {this.props.defaultSectionNamer}
            currentlySearching  = {this.props.currentlySearching}
            allStudentsFetched  = {this.props.allStudentsFetched}
          />

          <DueDateCalendars
            dates       = {this.props.dates}
            disabled    = {this.props.inputsDisabled}
            rowKey      = {this.props.rowKey}
            overrides   = {this.props.overrides}
            replaceDate = {this.props.replaceDate}
            sections    = {this.props.sections}
            dueDatesReadonly = {this.props.dueDatesReadonly}
            availabilityDatesReadonly = {this.props.availabilityDatesReadonly}
          />
          {this.renderClosedGradingPeriodNotification()}
        </div>
      )
    }

  })

export default DueDateRow
