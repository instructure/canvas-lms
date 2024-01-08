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
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import customPropTypes from '../modules/customPropTypes'
import Folder from '../../backbone/models/Folder'
import File from '../../backbone/models/File'
import '@canvas/datetime/jquery'
import accessibleDateFormat from '@canvas/datetime/accessibleDateFormat'
import filesEnv from '../modules/filesEnv'

const I18n = useI18nScope('restrict_student_access')

const allAreEqual = (models, fields) =>
  models.every(model =>
    fields.every(
      attribute =>
        models[0].get(attribute) === model.get(attribute) ||
        (!models[0].get(attribute) && !model.get(attribute))
    )
  )

class RestrictedRadioButtons extends React.Component {
  static propTypes = {
    models: PropTypes.arrayOf(customPropTypes.filesystemObject).isRequired,
    radioStateChange: PropTypes.func,
  }

  constructor(props) {
    super(props)
    let initialState

    const permissionAttributes = ['hidden', 'locked', 'lock_at', 'unlock_at']
    initialState = {}
    if (allAreEqual(props.models, permissionAttributes)) {
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
      },
    },
    {
      ref: 'unpublishInput',
      text: I18n.t('Unpublish'),
      selectedOptionKey: 'unpublished',
      iconClasses: 'icon-unpublish RestrictedRadioButtons__icon',
      onChange() {
        this.updateBtnEnable()
        this.setState({selectedOption: 'unpublished'})
      },
    },
    {
      ref: 'linkOnly',
      selectedOptionKey: 'link_only',
      text: I18n.t('Only available with link'),
      iconClasses: 'icon-line icon-off RestrictedRadioButtons__icon',
      onChange() {
        this.updateBtnEnable()
        this.setState({selectedOption: 'link_only'})
      },
    },
    {
      ref: 'dateRange',
      selectedOptionKey: 'date_range',
      text: I18n.t('Schedule availability'),
      iconClasses: 'icon-line icon-calendar-month RestrictedRadioButtons__icon',
      onChange() {
        this.updateBtnEnable()
        this.setState({selectedOption: 'date_range'})
      },
    },
  ]

  componentDidMount() {
    return $([this.unlock_at, this.lock_at]).datetime_field()
  }

  extractFormValues = () => {
    const opts = {
      hidden: this.state.selectedOption === 'link_only',
      unlock_at:
        (this.state.selectedOption === 'date_range' && $(this.unlock_at).data('unfudged-date')) ||
        '',
      lock_at:
        (this.state.selectedOption === 'date_range' && $(this.lock_at).data('unfudged-date')) || '',
      locked: this.state.selectedOption === 'unpublished',
    }

    const vis_val = $(this.visibility_field).val()
    if (filesEnv.enableVisibility && vis_val) {
      opts.visibility_level = vis_val
    }

    return opts
  }

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

  isPermissionChecked = option => this.state.selectedOption === option.selectedOptionKey

  renderPermissionOptions = () => (
    <div>
      <label className="control-label label-offline" htmlFor="availabilitySelector">
        {I18n.t('Availability:')}
      </label>
      <div>
        {this.permissionOptions.map((option, index) => (
          // eslint-disable-next-line react/no-array-index-key
          <div className="radio" key={index}>
            {/* eslint-disable-next-line jsx-a11y/label-has-associated-control */}
            <label>
              <input
                ref={e => (this[option.ref] = e)}
                type="radio"
                name="permissions"
                checked={this.isPermissionChecked(option)}
                onChange={option.onChange.bind(this)}
              />
              <i className={option.iconClasses} aria-hidden={true} />
              {option.text}
            </label>
          </div>
        ))}
      </div>
    </div>
  )

  renderDatePickers = () => {
    const styleObj = {}
    if (this.state.selectedOption !== 'date_range') {
      styleObj.visibility = 'hidden'
    }

    return (
      <div style={styleObj}>
        <label
          htmlFor="dateSelectInput"
          className="control-label dialog-adapter-form-calendar-label"
        >
          {I18n.t('Available From')}
        </label>
        <div className="dateSelectInputContainer controls">
          <input
            id="dateSelectInput"
            ref={e => (this.unlock_at = e)}
            defaultValue={this.state.unlock_at ? $.datetimeString(this.state.unlock_at) : ''}
            className="form-control dateSelectInput"
            type="text"
            title={accessibleDateFormat()}
            data-tooltip=""
            aria-label={I18n.t('Available From Date')}
          />
        </div>
        <div>
          <label htmlFor="lockDate" className="control-label dialog-adapter-form-calendar-label">
            {I18n.t('Available Until')}
          </label>
          <div className="dateSelectInputContainer controls">
            <input
              id="lockDate"
              ref={e => (this.lock_at = e)}
              defaultValue={this.state.lock_at ? $.datetimeString(this.state.lock_at) : ''}
              className="form-control dateSelectInput"
              type="text"
              title={accessibleDateFormat()}
              data-tooltip=""
              aria-label={I18n.t('Available Until Date')}
            />
          </div>
        </div>
      </div>
    )
  }

  renderVisibilityOptions = () => {
    const equal = allAreEqual(
      this.props.models.filter(model => model instanceof File),
      ['visibility_level']
    )

    return (
      <div className="control-group">
        <label className="control-label label-offline" htmlFor="visibilitySelector">
          {I18n.t('Visibility:')}
        </label>
        <select
          id="visibilitySelector"
          className=""
          disabled={this.state.selectedOption === 'unpublished'}
          defaultValue={equal ? this.props.models[0].get('visibility_level') : null}
          ref={e => (this.visibility_field = e)}
        >
          {!equal && <option value="">-- {I18n.t('Keep')} --</option>}
          <option value="inherit">{I18n.t('Inherit from Course')}</option>
          <option value="context">{I18n.t('Course Members')}</option>
          <option value="institution">{I18n.t('Institution Members')}</option>
          <option value="public">{I18n.t('Public')}</option>
        </select>
      </div>
    )
  }

  renderRestrictedRadioButtons = () => (
    <div className="RestrictedRadioButtons__wrapper">
      <div>
        {this.renderPermissionOptions()}
        {this.renderDatePickers()}
      </div>
      {filesEnv.enableVisibility && !this.allFolders() && (
        <div className="RestrictedRadioButtons__visibility_wrapper">
          {this.renderVisibilityOptions()}
        </div>
      )}
    </div>
  )

  render() {
    return <div>{this.renderRestrictedRadioButtons()}</div>
  }
}

export default RestrictedRadioButtons
