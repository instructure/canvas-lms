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
import I18n from 'i18n!restrict_student_access'
import $ from 'jquery'
import customPropTypes from 'compiled/react_files/modules/customPropTypes'
import Folder from 'compiled/models/Folder'
import 'jquery.instructure_date_and_time'

class RestrictedRadioButtons extends React.Component {
  static propTypes = {
    models: PropTypes.arrayOf(customPropTypes.filesystemObject).isRequired,
    radioStateChange: PropTypes.func
  }

  constructor(props) {
    super(props)
    let allAreEqual, initialState, permissionAttributes

    permissionAttributes = ['hidden', 'locked', 'lock_at', 'unlock_at']
    initialState = {}
    allAreEqual = props.models.every(model =>
      permissionAttributes.every(
        attribute =>
          props.models[0].get(attribute) === model.get(attribute) ||
          (!props.models[0].get(attribute) && !model.get(attribute))
      )
    )
    if (allAreEqual) {
      initialState = props.models[0].pick(permissionAttributes)
      if (initialState.locked) {
        initialState.selectedOption = 'unpublished'
      } else if (initialState.lock_at || initialState.unlock_at) {
        initialState.selectedOption = 'date_range'
      } else if (initialState.hidden) {
        initialState.selectedOption = 'link_only'
      } else {
        initialState.selectedOption = 'published'
      }
    }
    this.state = initialState
  }

  permissionOptions = [
    {
      ref: 'publishInput',
      text: I18n.t('Publish'),
      selectedOptionKey: 'published',
      iconClasses: 'icon-publish icon-Solid RestrictedRadioButtons__publish_icon',
      onChange() {
        this.updateBtnEnable()
        this.setState({selectedOption: 'published'})
      }
    },
    {
      ref: 'unpublishInput',
      text: I18n.t('Unpublish'),
      selectedOptionKey: 'unpublished',
      iconClasses: 'icon-unpublish RestrictedRadioButtons__icon',
      onChange() {
        this.updateBtnEnable()
        this.setState({selectedOption: 'unpublished'})
      }
    },
    {
      ref: 'linkOnly',
      selectedOptionKey: 'link_only',
      text: I18n.t('Not visible in student files'),
      iconClasses: 'icon-line icon-off RestrictedRadioButtons__icon',
      onChange() {
        this.updateBtnEnable()
        this.setState({selectedOption: 'link_only'})
      }
    },
    {
      ref: 'dateRange',
      selectedOptionKey: 'date_range',
      text: I18n.t('Schedule student availability'),
      iconClasses: 'icon-line icon-calendar-month RestrictedRadioButtons__icon',
      onChange() {
        this.updateBtnEnable()
        this.setState({selectedOption: 'date_range'})
      }
    }
  ]

  componentDidMount() {
    return $([this.unlock_at, this.lock_at]).datetime_field()
  }

  extractFormValues = () => ({
    hidden: this.state.selectedOption === 'link_only',
    unlock_at:
      (this.state.selectedOption === 'date_range' && $(this.unlock_at).data('unfudged-date')) || '',
    lock_at:
      (this.state.selectedOption === 'date_range' && $(this.lock_at).data('unfudged-date')) || '',
    locked: this.state.selectedOption === 'unpublished'
  })

  allFolders = () => this.props.models.every(model => model instanceof Folder)

  /*
  # Returns true if all the models passed in are folders.
  */
  anyFolders = () => this.props.models.filter(model => model instanceof Folder).length

  updateBtnEnable = () => {
    if (this.props.radioStateChange) {
      this.props.radioStateChange()
    }
  }

  isPermissionChecked = option =>
    this.state.selectedOption === option.selectedOptionKey ||
    _.includes(option.selectedOptionKey, this.state.selectedOption)

  renderPermissionOptions = () =>
    this.permissionOptions.map((option, index) => (
      <div className="radio" key={index}>
        <label>
          <input
            ref={e => (this[option.ref] = e)}
            type="radio"
            name="permissions"
            checked={this.isPermissionChecked(option)}
            onChange={option.onChange.bind(this)}
          />
          <i className={option.iconClasses} aria-hidden />
          {option.text}
        </label>
      </div>
    ))

  renderDatePickers = () => {
    const styleObj = {}
    if (this.state.selectedOption !== 'date_range') {
      styleObj.visibility = 'hidden'
    }

    return (
      <div style={styleObj}>
        <label className="control-label dialog-adapter-form-calendar-label">
          {I18n.t('Available From')}
        </label>
        <div className="dateSelectInputContainer controls">
          <input
            ref={e => (this.unlock_at = e)}
            defaultValue={this.state.unlock_at ? $.datetimeString(this.state.unlock_at) : ''}
            className="form-control dateSelectInput"
            type="text"
            aria-label={I18n.t('Available From Date')}
          />
        </div>
        <div>
          <label className="control-label dialog-adapter-form-calendar-label">
            {I18n.t('Available Until')}
          </label>
          <div className="dateSelectInputContainer controls">
            <input
              id="lockDate"
              ref={e => (this.lock_at = e)}
              defaultValue={this.state.lock_at ? $.datetimeString(this.state.lock_at) : ''}
              className="form-control dateSelectInput"
              type="text"
              aria-label={I18n.t('Available Until Date')}
            />
          </div>
        </div>
      </div>
    )
  }

  renderRestrictedRadioButtons = () => (
    <div>
      {this.renderPermissionOptions()}
      {this.renderDatePickers()}
    </div>
  )

  render() {
    return <div>{this.renderRestrictedRadioButtons()}</div>
  }
}

export default RestrictedRadioButtons
