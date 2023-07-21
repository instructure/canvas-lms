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

import React from 'react'
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import numberHelper from '@canvas/i18n/numberHelper'

const I18n = useI18nScope('gradingdataRow')

const {bool, func, number} = PropTypes

class DataRow extends React.Component {
  static propTypes = {
    onRowMinScoreChange: func.isRequired,
    uniqueId: number.isRequired,
    round: func.isRequired,
    editing: bool.isRequired,
  }

  state = {showBottomBorder: false}

  UNSAFE_componentWillReceiveProps() {
    this.setState({showBottomBorder: false})
  }

  getRowData = () => {
    const rowData = {name: this.props.row[0], minScore: this.props.row[1], maxScore: null}
    rowData.maxScore = this.props.uniqueId === 0 ? 100 : this.props.siblingRow[1]
    return rowData
  }

  hideBottomBorder = () => {
    this.setState({showBottomBorder: false})
  }

  showBottomBorder = () => {
    this.setState({showBottomBorder: true})
  }

  triggerRowNameChange = event => {
    this.props.onRowNameChange(this.props.uniqueId, event.target.value)
  }

  triggerRowMinScoreBlur = () => {
    if (this.state.minScoreInput == null) return

    const inputVal = numberHelper.parse(this.state.minScoreInput)

    if (!Number.isNaN(Number(inputVal)) && inputVal >= 0 && inputVal <= 100) {
      this.props.onRowMinScoreChange(this.props.uniqueId, String(inputVal))
    }

    this.setState({minScoreInput: null})
  }

  triggerRowMinScoreChange = event => {
    this.setState({minScoreInput: event.target.value})
  }

  triggerDeleteRow = event => {
    event.preventDefault()
    return this.props.onDeleteRow(this.props.uniqueId)
  }

  triggerInsertRow = event => {
    event.preventDefault()
    return this.props.onInsertRow(this.props.uniqueId)
  }

  renderInsertRowButton = () => (
    <button
      className="Button Button--icon-action insert_row_button"
      onMouseEnter={this.showBottomBorder}
      onFocus={this.showBottomBorder}
      onBlur={this.hideBottomBorder}
      onMouseLeave={this.hideBottomBorder}
      onClick={this.triggerInsertRow}
      type="button"
    >
      <span className="screenreader-only">
        {I18n.t('Insert row below %{name}', {name: this.getRowData().name})}
      </span>
      <i className="icon-add" />
    </button>
  )

  renderMaxScore = () => {
    const maxScore = this.props.round(this.getRowData().maxScore)
    return (maxScore === 100 ? '' : '< ') + I18n.n(maxScore)
  }

  renderMinScore = () => {
    let minScore = this.getRowData().minScore

    if (!this.props.editing) {
      minScore = this.props.round(minScore)
    } else if (this.state.minScoreInput != null) {
      return this.state.minScoreInput
    }

    return I18n.n(minScore)
  }

  renderDeleteRowButton = () => {
    if (this.props.onlyDataRowRemaining) return null
    return (
      <button
        ref={c => (this.deleteButtonRef = c)}
        className="Button Button--icon-action delete_row_button"
        onClick={this.triggerDeleteRow}
        type="button"
      >
        <span className="screenreader-only">
          {I18n.t('Remove row %{name}', {name: this.getRowData().name})}
        </span>
        <i className="icon-end" />
      </button>
    )
  }

  renderViewMode = () => (
    <tr className="grading_standard_row react_grading_standard_row" ref="viewContainer">
      <td className="insert_row_icon_container" />
      <td className="row_name_container">
        <div className="name" ref="name">
          {this.getRowData().name}
        </div>
      </td>
      <td className="row_cell max_score_cell" aria-label={I18n.t('Upper limit of range')}>
        <div>
          <span className="max_score" ref="maxScore" title="Upper limit of range">
            {`${this.renderMaxScore()}%`}
          </span>
        </div>
      </td>
      <td className="row_cell">
        <div>
          <span className="range_to" ref="minScore">
            {I18n.t('to %{minScore}%', {minScore: this.renderMinScore()})}
          </span>
          <span className="min_score" />
        </div>
      </td>
      <td className="row_cell last_row_cell" />
    </tr>
  )

  renderEditMode = () => (
    <tr
      className={
        this.state.showBottomBorder
          ? 'grading_standard_row react_grading_standard_row border_below'
          : 'grading_standard_row react_grading_standard_row'
      }
      ref="editContainer"
    >
      <td className="insert_row_icon_container">{this.renderInsertRowButton()}</td>
      <td className="row_name_container">
        <div>
          <input
            type="text"
            ref="nameInput"
            onChange={this.triggerRowNameChange}
            className="standard_name"
            title={I18n.t('Range name')}
            aria-label={I18n.t('Range name')}
            name={`grading_standard[standard_data][scheme_${this.props.uniqueId}[name]`}
            value={this.getRowData().name}
          />
        </div>
      </td>
      <td className="row_cell max_score_cell edit_max_score">
        <span className="edit_max_score">
          {`${this.renderMaxScore()}%`}
          <span className="screenreader-only">{I18n.t('Upper limit of range')}</span>
        </span>
      </td>
      <td className="row_cell">
        <div>
          <span className="range_to" aria-hidden="true">
            {I18n.t('to ')}
          </span>
          <input
            type="text"
            className="standard_value"
            ref={input => {
              this.minScoreInput = input
            }}
            onChange={this.triggerRowMinScoreChange}
            onBlur={this.triggerRowMinScoreBlur}
            title={I18n.t('Lower limit of range')}
            aria-label={I18n.t('Lower limit of range')}
            name={`grading_standard[standard_data][scheme_${this.props.uniqueId}][value]`}
            value={this.renderMinScore()}
          />
          <span aria-hidden="true"> % </span>
        </div>
      </td>
      <td className="row_cell last_row_cell">{this.renderDeleteRowButton()}</td>
    </tr>
  )

  render() {
    return this.props.editing ? this.renderEditMode() : this.renderViewMode()
  }
}

export default DataRow
