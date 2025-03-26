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
import {useScope as createI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import customPropTypes from '../modules/customPropTypes'
import Folder from '../../backbone/models/Folder'
import File from '../../backbone/models/File'
import filesEnv from '../modules/filesEnv'
import {dateString, timeString} from '@canvas/datetime/date-functions'
import {renderDatetimeField} from '@canvas/datetime/jquery/DatetimeField'
import {mergeTimeAndDate} from '@instructure/moment-utils'
import classnames from 'classnames'

const I18n = createI18nScope('restrict_student_access')

const allAreEqual = (models, fields) =>
  models.every(model =>
    fields.every(
      attribute =>
        models[0].get(attribute) === model.get(attribute) ||
        (!models[0].get(attribute) && !model.get(attribute)),
    ),
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
      initialState.lock_at_time = timeString(initialState.lock_at) || ''
      initialState.unlock_at_time = timeString(initialState.unlock_at) || ''
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
      onChange: () => {
        this.updateBtnEnable()
        this.setState({selectedOption: 'published'})
      },
    },
    {
      ref: 'unpublishInput',
      text: I18n.t('Unpublish'),
      selectedOptionKey: 'unpublished',
      iconClasses: 'icon-unpublish RestrictedRadioButtons__icon',
      onChange: () => {
        this.updateBtnEnable()
        this.setState({selectedOption: 'unpublished'})
      },
    },
    {
      ref: 'linkOnly',
      selectedOptionKey: 'link_only',
      text: I18n.t('Only available with link'),
      iconClasses: 'icon-line icon-off RestrictedRadioButtons__icon',
      onChange: () => {
        this.updateBtnEnable()
        this.setState({selectedOption: 'link_only'})
      },
    },
    {
      ref: 'dateRange',
      selectedOptionKey: 'date_range',
      text: I18n.t('Schedule availability'),
      iconClasses: 'icon-line icon-calendar-month RestrictedRadioButtons__icon',
      onChange: () => {
        this.updateBtnEnable()
        this.setState({selectedOption: 'date_range'})
      },
    },
  ]

  componentDidMount() {
    renderDatetimeField($(this.unlock_at), {dateOnly: true})
    renderDatetimeField($(this.unlock_at_time), {timeOnly: true})
    renderDatetimeField($(this.lock_at), {dateOnly: true})
    renderDatetimeField($(this.lock_at_time), {timeOnly: true})
  }

  extractFormValues = () => {
    let unlock_at_datetime = ''
    let lock_at_datetime = ''

    if (this.state.selectedOption === 'date_range') {
      unlock_at_datetime = $(this.unlock_at).data('unfudged-date') || ''
      if ($(this.unlock_at_time).val()) {
        unlock_at_datetime =
          mergeTimeAndDate($(this.unlock_at_time).val(), $(this.unlock_at).data('unfudged-date')) ||
          ''
      }

      lock_at_datetime = $(this.lock_at).data('unfudged-date') || ''
      if ($(this.lock_at_time).val()) {
        lock_at_datetime =
          mergeTimeAndDate($(this.lock_at_time).val(), $(this.lock_at).data('unfudged-date')) || ''
      }
    }

    const opts = {
      hidden: this.state.selectedOption === 'link_only',
      unlock_at: (this.state.selectedOption === 'date_range' && unlock_at_datetime) || '',
      lock_at: (this.state.selectedOption === 'date_range' && lock_at_datetime) || '',
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
      <label id="availability-label" className="control-label label-offline">
        <b>{I18n.t('Availability:')}</b>
      </label>
      <div role="radiogroup" aria-labelledby="availability-label">
        {this.permissionOptions.map((option, index) => (
          <div className="radio" key={index}>
            {}
            <label>
              <input
                ref={e => (this[option.ref] = e)}
                type="radio"
                name="permissions"
                checked={this.isPermissionChecked(option)}
                onChange={option.onChange}
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
    const styleObj = classnames('RestrictedRadioButtons__dates_wrapper', {
      RestrictedRadioButtons__dates_wrapper_hidden: this.state.selectedOption !== 'date_range',
    })
    return (
      <div className={styleObj}>
        <label htmlFor="dateSelectInput">
          <b>{I18n.t('Available From')}</b>
        </label>
        <div className="dateSelectInputContainer controls">
          <input
            id="dateSelectInput"
            ref={e => (this.unlock_at = e)}
            defaultValue={this.state.unlock_at ? dateString(this.state.unlock_at) : ''}
            className="form-control dateSelectInput"
            type="text"
            title={I18n.t('YYYY-MM-DD')}
            data-tooltip=""
            aria-label={I18n.t('Available From Date')}
          />
        </div>
        <label htmlFor="timeSelectInput">
          <b>{I18n.t('From Time')}</b>
        </label>
        <div className="dateSelectInputContainer controls">
          <input
            id="timeSelectInput"
            ref={e => (this.unlock_at_time = e)}
            defaultValue={this.state.unlock_at_time}
            className="form-control timeSelectInput"
            type="text"
            title={I18n.t('hh:mm')}
            data-tooltip=""
            aria-label={I18n.t('Available From Time')}
          />
        </div>
        <div>
          <label htmlFor="lockDate">
            <b>{I18n.t('Available Until')}</b>
          </label>
          <div className="dateSelectInputContainer controls">
            <input
              id="lockDate"
              ref={e => (this.lock_at = e)}
              defaultValue={this.state.lock_at ? dateString(this.state.lock_at) : ''}
              className="form-control dateSelectInput"
              type="text"
              title={I18n.t('YYYY-MM-DD')}
              data-tooltip=""
              aria-label={I18n.t('Available Until Date')}
            />
          </div>
        </div>
        <label htmlFor="lockDateTime">
          <b>{I18n.t('Until Time')}</b>
        </label>
        <div className="dateSelectInputContainer controls">
          <input
            id="lockDateTime"
            ref={e => (this.lock_at_time = e)}
            defaultValue={this.state.lock_at_time}
            className="form-control timeSelectInput"
            type="text"
            title={I18n.t('hh:mm')}
            data-tooltip=""
            aria-label={I18n.t('Available Until Time')}
          />
        </div>
      </div>
    )
  }

  renderVisibilityOptions = () => {
    const equal = allAreEqual(
      this.props.models.filter(model => model instanceof File),
      ['visibility_level'],
    )

    return (
      <div className="control-group">
        <label className="control-label label-offline" htmlFor="visibilitySelector">
          <b>{I18n.t('Visibility:')}</b>
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
