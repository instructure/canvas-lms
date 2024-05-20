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
import ReactDOM from 'react-dom'
import {shape, string} from 'prop-types'
import update from 'immutability-helper'
import DataRow from './dataRow'
import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'
import {chain, map, some} from 'lodash'
import splitAssetString from '@canvas/util/splitAssetString'

const I18n = useI18nScope('gradinggradingStandard')

class GradingStandard extends React.Component {
  static propTypes = {
    standard: shape({title: string.isRequired}).isRequired,
  }

  state = {
    editingStandard: $.extend(true, {}, this.props.standard),
    saving: false,
    showAlert: false,
  }

  UNSAFE_componentWillReceiveProps(nextProps) {
    this.setState({
      editingStandard: $.extend(true, {}, this.props.standard),
      saving: nextProps.saving,
      showAlert: false,
    })
  }

  componentDidMount() {
    if (this.props.justAdded) ReactDOM.findDOMNode(this.titleRef).focus()
  }

  componentDidUpdate(prevProps, _prevState) {
    if (this.props.editing !== prevProps.editing) {
      ReactDOM.findDOMNode(this.titleRef).focus()
      this.setState({editingStandard: $.extend(true, {}, this.props.standard)})
    }
  }

  triggerEditGradingStandard = _event => {
    this.props.onSetEditingStatus(this.props.uniqueId, true)
  }

  triggerStopEditingGradingStandard = () => {
    this.props.onSetEditingStatus(this.props.uniqueId, false)
  }

  triggerDeleteGradingStandard = event =>
    this.props.onDeleteGradingStandard(event, this.props.uniqueId)

  triggerSaveGradingStandard = () => {
    if (this.standardIsValid()) {
      this.setState({saving: true}, function () {
        this.props.onSaveGradingStandard(this.state.editingStandard)
      })
    } else {
      this.setState({showAlert: true}, function () {
        ReactDOM.findDOMNode(this.invalidStandardAlertRef).focus()
      })
    }
  }

  assessedAssignment = () => !!(this.props.standard && this.props.standard['assessed_assignment?'])

  deleteDataRow = index => {
    if (this.moreThanOneDataRowRemains()) {
      const newEditingStandard = update(this.state.editingStandard, {data: {$splice: [[index, 1]]}})
      this.setState({editingStandard: newEditingStandard})
    }
  }

  moreThanOneDataRowRemains = () => this.state.editingStandard.data.length > 1

  insertGradingStandardRow = index => {
    const [rowBefore, rowAfter] = this.state.editingStandard.data.slice(index, index + 2)
    const score = rowAfter ? (rowBefore[1] - rowAfter[1]) / 2 + rowAfter[1] : 0

    const newEditingStandard = update(this.state.editingStandard, {
      data: {$splice: [[index + 1, 0, ['', score]]]},
    })
    this.setState({editingStandard: newEditingStandard})
  }

  changeTitle = event => {
    const newEditingStandard = $.extend(true, {}, this.state.editingStandard)
    newEditingStandard.title = event.target.value
    this.setState({editingStandard: newEditingStandard})
  }

  changeRowMinScore = (index, inputVal) => {
    const newEditingStandard = $.extend(true, {}, this.state.editingStandard)
    newEditingStandard.data[index][1] = inputVal
    this.setState({editingStandard: newEditingStandard})
  }

  changeRowName = (index, newRowName) => {
    const newEditingStandard = $.extend(true, {}, this.state.editingStandard)
    newEditingStandard.data[index][0] = newRowName
    this.setState({editingStandard: newEditingStandard})
  }

  hideAlert = () => {
    this.setState({showAlert: false}, function () {
      ReactDOM.findDOMNode(this.titleRef).focus()
    })
  }

  standardIsValid = () => this.rowDataIsValid() && this.rowNamesAreValid()

  rowDataIsValid = () => {
    if (this.state.editingStandard.data.length <= 1) return true
    const rowValues = map(this.state.editingStandard.data, dataRow => String(dataRow[1]).trim())
    const sanitizedRowValues = chain(rowValues).compact().uniq().value()
    const inputsAreUniqueAndNonEmpty = sanitizedRowValues.length === rowValues.length
    const valuesDoNotOverlap = !some(this.state.editingStandard.data, (element, index, list) => {
      if (index < 1) return false
      const thisMinScore = this.props.round(element[1])
      const aboveMinScore = this.props.round(list[index - 1][1])
      return thisMinScore >= aboveMinScore
    })

    return inputsAreUniqueAndNonEmpty && valuesDoNotOverlap
  }

  rowNamesAreValid = () => {
    const rowNames = map(this.state.editingStandard.data, dataRow => dataRow[0].trim())
    const sanitizedRowNames = chain(rowNames).compact().uniq().value()
    return sanitizedRowNames.length === rowNames.length
  }

  renderCannotManageMessage = () => {
    if (this.props.permissions.manage && this.props.othersEditing) return null
    if (this.props.standard.context_name) {
      return (
        <div>
          {I18n.t('(%{context}: %{contextName})', {
            context: this.props.standard.context_type.toLowerCase(),
            contextName: this.props.standard.context_name,
          })}
        </div>
      )
    }
    return (
      <div>
        {I18n.t('(%{context} level)', {context: this.props.standard.context_type.toLowerCase()})}
      </div>
    )
  }

  renderIdNames = () => {
    if (this.assessedAssignment()) return 'grading_standard_blank'
    return `grading_standard_${this.props.standard ? this.props.standard.id : 'blank'}`
  }

  renderTitle = () => {
    if (this.props.editing) {
      return (
        <div className="pull-left">
          <input
            type="text"
            onChange={this.changeTitle}
            name="grading_standard[title]"
            className="scheme_name"
            title={I18n.t('Grading standard title')}
            value={this.state.editingStandard.title}
            ref={ref => {
              this.titleRef = ref
            }}
          />
        </div>
      )
    }
    return (
      <div className="pull-left">
        <div
          className="title"
          ref={ref => {
            this.titleRef = ref
          }}
        >
          <span className="screenreader-only">{I18n.t('Grading standard title')}</span>
          {this.props.standard.title}
        </div>
      </div>
    )
  }

  renderDataRows = () => {
    const data = this.props.editing ? this.state.editingStandard.data : this.props.standard.data
    return data.map(function (item, idx, array) {
      return (
        <DataRow
          // eslint-disable-next-line react/no-array-index-key
          key={idx}
          uniqueId={idx}
          row={item}
          siblingRow={array[idx - 1]}
          editing={this.props.editing}
          onDeleteRow={this.deleteDataRow}
          onInsertRow={this.insertGradingStandardRow}
          onlyDataRowRemaining={!this.moreThanOneDataRowRemains()}
          round={this.props.round}
          onRowMinScoreChange={this.changeRowMinScore}
          onRowNameChange={this.changeRowName}
        />
      )
    }, this)
  }

  renderSaveButton = () => {
    if (this.state.saving) {
      return (
        <button type="button" className="btn btn-primary save_button" disabled={true}>
          {I18n.t('Saving...')}
        </button>
      )
    }
    return (
      <button
        type="button"
        onClick={this.triggerSaveGradingStandard}
        className="btn btn-primary save_button"
      >
        {I18n.t('Save')}
      </button>
    )
  }

  renderSaveAndCancelButtons = () => {
    if (this.props.editing) {
      return (
        <div className="form-actions">
          <button
            type="button"
            onClick={this.triggerStopEditingGradingStandard}
            className="btn cancel_button"
          >
            {I18n.t('Cancel')}
          </button>
          {this.renderSaveButton()}
        </div>
      )
    }
    return null
  }

  renderEditAndDeleteIcons = () => {
    if (!this.props.editing) {
      const {title} = this.props.standard

      return (
        <div>
          <button
            className={`Button Button--icon-action edit_grading_standard_button ${
              this.assessedAssignment() ? 'read_only' : ''
            }`}
            onClick={this.triggerEditGradingStandard}
            type="button"
          >
            <span className="screenreader-only">
              {I18n.t('Edit Grading Scheme %{title}', {title})}
            </span>
            <i className="icon-edit" />
          </button>
          <button
            ref={c => (this.deleteButtonRef = c)}
            className="Button Button--icon-action delete_grading_standard_button"
            onClick={this.triggerDeleteGradingStandard}
            type="button"
          >
            <span className="screenreader-only">
              {I18n.t('Delete Grading Scheme %{title}', {title})}
            </span>
            <i className="icon-trash" />
          </button>
        </div>
      )
    }
    return null
  }

  renderIconsAndTitle = () => {
    if (
      this.props.permissions.manage &&
      !this.props.othersEditing &&
      (!this.props.standard.context_code ||
        this.props.standard.context_code === ENV.context_asset_string)
    ) {
      return (
        <div>
          {this.renderTitle()}
          <div className="links">{this.renderEditAndDeleteIcons()}</div>
        </div>
      )
    }
    return (
      <div>
        {this.renderTitle()}
        {this.renderDisabledIcons()}
        <div className="pull-left cannot-manage-notification">
          {this.renderCannotManageMessage()}
        </div>
      </div>
    )
  }

  renderDisabledIcons = () => {
    if (
      this.props.permissions.manage &&
      this.props.standard.context_code &&
      this.props.standard.context_code !== ENV.context_asset_string
    ) {
      const url = `/${splitAssetString(this.props.standard.context_code).join(
        '/'
      )}/grading_standards`
      const titleText = I18n.t('Manage grading schemes in %{context_name}', {
        context_name:
          this.props.standard.context_name || this.props.standard.context_type.toLowerCase(),
      })
      return (
        <a
          className="links cannot-manage-notification"
          href={url}
          title={titleText}
          data-tooltip="left"
        >
          <span className="screenreader-only">{titleText}</span>
          <i className="icon-more standalone-icon" />
        </a>
      )
    } else {
      return (
        <div className="disabled-buttons">
          <i className="icon-edit" />
          <i className="icon-trash" />
        </div>
      )
    }
  }

  renderInvalidStandardMessage = () => {
    let message = 'Invalid grading scheme'
    if (!this.rowDataIsValid())
      message =
        "Cannot have overlapping or empty ranges. Fix the ranges and try clicking 'Save' again."
    if (!this.rowNamesAreValid())
      message =
        "Cannot have duplicate or empty row names. Fix the names and try clicking 'Save' again."
    return (
      <div
        id={`invalid_standard_message_${this.props.uniqueId}`}
        className="alert-message"
        tabIndex="-1"
        ref={ref => {
          this.invalidStandardAlertRef = ref
        }}
      >
        {I18n.t('%{message}', {message})}
      </div>
    )
  }

  renderStandardAlert = () => {
    if (!this.state.showAlert) return null
    if (this.standardIsValid()) {
      return (
        <div id="valid_standard" className="alert alert-success">
          <button
            type="button"
            aria-label="Close"
            className="dismiss_alert close"
            onClick={this.hideAlert}
          >
            ×
          </button>
          <div className="alert-message">{I18n.t('Looks great!')}</div>
        </div>
      )
    }
    return (
      <div id="invalid_standard" className="alert alert-error">
        <button
          type="button"
          aria-label="Close"
          className="dismiss_alert close"
          onClick={this.hideAlert}
        >
          ×
        </button>
        {this.renderInvalidStandardMessage()}
      </div>
    )
  }

  render() {
    return (
      <div>
        <div
          className="grading_standard react_grading_standard pad-box-mini border border-trbl border-round"
          id={this.renderIdNames()}
        >
          {this.renderStandardAlert()}
          <div>
            <table className="grading_standard_data">
              <caption className="screenreader-only">
                {I18n.t(
                  'A table that contains the grading scheme data. First is a name of the grading scheme and buttons for editing and deleting the scheme. Each row contains a name, a maximum percentage, and a minimum percentage. In addition, each row contains a button to add a new row below, and a button to delete the current row.'
                )}
              </caption>
              <thead>
                <tr className="grading_standard_headers">
                  <th scope="col" className="icon_row_cell" tabIndex="-1">
                    <div className="screenreader-only">{I18n.t('Insert row in edit mode')}</div>
                  </th>
                  <th scope="col" colSpan="4" className="standard_title">
                    {this.renderIconsAndTitle()}
                  </th>
                </tr>
                <tr className="grading_standard_headers">
                  <th scope="col" className="icon_row_cell">
                    <div className="screenreader-only">{I18n.t('Insert row in edit mode')}</div>
                  </th>
                  <th scope="col" className="name_row_cell">
                    {I18n.t('Name')}
                  </th>
                  <th scope="col" className="range_row_cell" colSpan="2">
                    {I18n.t('Range')}
                  </th>
                  <th scope="col" className="icon_row_cell">
                    <div className="screenreader-only">{I18n.t('Remove row in edit mode')}</div>
                  </th>
                </tr>
              </thead>
              <tbody>{this.renderDataRows()}</tbody>
            </table>
            {this.renderSaveAndCancelButtons()}
          </div>
        </div>
      </div>
    )
  }
}

export default GradingStandard
