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

import React from 'react'
import update from 'immutability-helper'
import GradingStandard from '../grading/gradingStandard'
import $ from 'jquery'
import I18n from 'i18n!external_tools'
import _ from 'underscore'
import 'jquery.instructure_misc_plugins'

class GradingStandardCollection extends React.Component {
  state = {standards: null}

  componentWillMount() {
    $.getJSON(`${ENV.GRADING_STANDARDS_URL}.json`).done(this.gotStandards)
  }

  gotStandards = standards => {
    let formattedStandards = $.extend(true, [], standards)
    formattedStandards = _.map(
      formattedStandards,
      function(standard) {
        standard.grading_standard.data = this.formatStandardData(standard.grading_standard.data)
        return standard
      },
      this
    )
    this.setState({standards: formattedStandards})
  }

  formatStandardData = standardData =>
    _.map(
      standardData,
      function(dataRow) {
        return [dataRow[0], this.roundToTwoDecimalPlaces(dataRow[1] * 100)]
      },
      this
    )

  addGradingStandard = () => {
    const newStandard = {
      editing: true,
      justAdded: true,
      grading_standard: {
        permissions: {manage: true},
        title: '',
        data: this.formatStandardData(ENV.DEFAULT_GRADING_STANDARD_DATA),
        id: -1
      }
    }
    const newStandards = update(this.state.standards, {$unshift: [newStandard]})
    this.setState({standards: newStandards})
  }

  getStandardById = id =>
    _.find(this.state.standards, standard => standard.grading_standard.id === id)

  standardNotCreated = gradingStandard => gradingStandard.id === -1

  setEditingStatus = (id, setEditingStatusTo) => {
    const newStandards = $.extend(true, [], this.state.standards)
    const existingStandard = this.getStandardById(id)
    const indexToEdit = this.state.standards.indexOf(existingStandard)
    if (
      setEditingStatusTo === false &&
      this.standardNotCreated(existingStandard.grading_standard)
    ) {
      newStandards.splice(indexToEdit, 1)
      this.setState({standards: newStandards})
    } else {
      newStandards[indexToEdit].editing = setEditingStatusTo
      this.setState({standards: newStandards})
    }
  }

  anyStandardBeingEdited = () => !!_.find(this.state.standards, standard => standard.editing)

  saveGradingStandard = standard => {
    const newStandards = $.extend(true, [], this.state.standards)
    const indexToUpdate = this.state.standards.indexOf(this.getStandardById(standard.id))
    let type, url, data
    standard.title = standard.title.trim()
    if (this.standardNotCreated(standard)) {
      if (standard.title === '') standard.title = 'New Grading Scheme'
      type = 'POST'
      url = ENV.GRADING_STANDARDS_URL
      data = this.dataFormattedForCreate(standard)
    } else {
      type = 'PUT'
      url = `${ENV.GRADING_STANDARDS_URL}/${standard.id}`
      data = this.dataFormattedForUpdate(standard)
    }
    $.ajax({
      type,
      url,
      dataType: 'json',
      contentType: 'application/json',
      data: JSON.stringify(data),
      context: this
    })
      .success(function(updatedStandard) {
        updatedStandard.grading_standard.data = this.formatStandardData(
          updatedStandard.grading_standard.data
        )
        newStandards[indexToUpdate] = updatedStandard
        this.setState({standards: newStandards}, () => {
          $.flashMessage(I18n.t('Grading scheme saved'))
        })
      })
      .error(function() {
        newStandards[indexToUpdate].grading_standard.saving = false
        this.setState({standards: newStandards}, () => {
          $.flashError(I18n.t('There was a problem saving the grading scheme'))
        })
      })
  }

  dataFormattedForCreate = standard => {
    const formattedData = {grading_standard: standard}
    _.each(
      standard.data,
      function(dataRow, i) {
        const name = dataRow[0]
        const value = dataRow[1]
        formattedData.grading_standard.data[i] = [
          name.trim(),
          this.roundToTwoDecimalPlaces(value) / 100
        ]
      },
      this
    )
    return formattedData
  }

  dataFormattedForUpdate = standard => {
    const formattedData = {grading_standard: {title: standard.title, standard_data: {}}}
    _.each(
      standard.data,
      function(dataRow, i) {
        const name = dataRow[0]
        const value = dataRow[1]
        formattedData.grading_standard.standard_data[`scheme_${i}`] = {
          name: name.trim(),
          value: this.roundToTwoDecimalPlaces(value)
        }
      },
      this
    )
    return formattedData
  }

  roundToTwoDecimalPlaces = number => Math.round(number * 100) / 100

  deleteGradingStandard = (event, uniqueId) => {
    let self = this,
      $standard = $(event.target).parents('.grading_standard')
    $standard.confirmDelete({
      url: `${ENV.GRADING_STANDARDS_URL}/${uniqueId}`,
      message: I18n.t('Are you sure you want to delete this grading scheme?'),
      success() {
        const indexToRemove = self.state.standards.indexOf(self.getStandardById(uniqueId))
        const newStandards = update(self.state.standards, {$splice: [[indexToRemove, 1]]})
        self.setState({standards: newStandards}, () => {
          $.flashMessage(I18n.t('Grading scheme deleted'))
        })
      },
      error() {
        $.flashError(I18n.t('There was a problem deleting the grading scheme'))
      }
    })
  }

  hasAdminOrTeacherRole = () =>
    _.intersection(ENV.current_user_roles, ['teacher', 'admin']).length > 0

  getAddButtonCssClasses = () => {
    let classes = 'Button pull-right add_standard_button'
    if (!this.hasAdminOrTeacherRole() || this.anyStandardBeingEdited()) classes += ' disabled'
    return classes
  }

  renderGradingStandards = () => {
    if (!this.state.standards) {
      return null
    } else if (this.state.standards.length === 0) {
      return <h3 ref="noSchemesMessage">{I18n.t('No grading schemes to display')}</h3>
    }
    return this.state.standards.map(function(s) {
      return (
        <GradingStandard
          ref={`gradingStandard${s.grading_standard.id}`}
          key={s.grading_standard.id}
          uniqueId={s.grading_standard.id}
          standard={s.grading_standard}
          editing={!!s.editing}
          permissions={s.grading_standard.permissions}
          justAdded={!!s.justAdded}
          onSetEditingStatus={this.setEditingStatus}
          round={this.roundToTwoDecimalPlaces}
          onDeleteGradingStandard={this.deleteGradingStandard}
          othersEditing={!s.editing && this.anyStandardBeingEdited()}
          onSaveGradingStandard={this.saveGradingStandard}
        />
      )
    }, this)
  }

  render() {
    return (
      <div>
        <div className="pull-right">
          <button
            ref="addButton"
            onClick={this.addGradingStandard}
            className={this.getAddButtonCssClasses()}
          >
            <i className="icon-add" />
            {I18n.t(' Add grading scheme')}
          </button>
        </div>
        <div id="standards" className="content-box react_grading_standards">
          {this.renderGradingStandards()}
        </div>
      </div>
    )
  }
}

export default GradingStandardCollection
