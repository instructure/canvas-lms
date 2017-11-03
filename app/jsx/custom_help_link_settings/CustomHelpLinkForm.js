/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import I18n from 'i18n!custom_help_link'
import CustomHelpLinkPropTypes from './CustomHelpLinkPropTypes'
import CustomHelpLinkConstants from './CustomHelpLinkConstants'

export default class CustomHelpLinkForm extends React.Component {
  static propTypes = {
    link: CustomHelpLinkPropTypes.link.isRequired,
    onSave: PropTypes.func,
    onCancel: PropTypes.func
  }

  static defaultProps = {
    onSave: () => {},
    onCancel: () => {}
  }

  state = {
    link: {
      ...this.props.link
    }
  }

  handleKeyDown = (e, field) => {
    // need to update the state if the user hits the ENTER key from any of the fields
    if (e.which !== 13) {
      return
    }

    if (field === 'available_to') {
      this.handleAvailableToChange(e.target.value, e.target.checked)
    } else if (field) {
      this.handleChange(field, e.target.value)
    }
  }

  handleChange = (field, value) => {
    this.setState({
      link: {
        ...this.state.link,
        [field]: value
      }
    })
  }

  handleSave = e => {
    if (typeof this.props.onSave === 'function') {
      this.props.onSave(this.state.link)
    }
    e.preventDefault()
  }

  handleAvailableToChange = (type, checked) => {
    const available_to = this.state.link.available_to.slice() // make a copy

    if (checked) {
      available_to.push(type)
    } else {
      available_to.splice(available_to.indexOf(type), 1)
    }

    this.handleChange('available_to', available_to)
  }

  handleCancel = () => {
    if (typeof this.props.onCancel === 'function') {
      this.props.onCancel(this.props.link)
    }
  }

  focus = () => {
    const el = this.focusable()
    if (el) {
      el.focus()
    }
  }

  focusable = () => {
    let el = this.textInputRef
    if (el.disabled) {
      el = this.availableToUserRef
    }
    return el
  }

  render() {
    const {text, state, subtext, url, available_to, index, id} = this.state.link

    const namePrefix = `${CustomHelpLinkConstants.NAME_PREFIX}[${index}]`

    return (
      <li className="ic-Sortable-item ic-Sortable-item--new-item">
        <input type="hidden" name={`${namePrefix}[state]`} value="active" />
        <div className="ic-Sortable-item__Actions">
          <button className="Button Button--icon-action" type="button" onClick={this.handleCancel}>
            <span className="screenreader-only">{I18n.t('Cancel custom link creation')}</span>
            <i className="icon-x" aria-hidden="true" />
          </button>
        </div>
        <fieldset className="ic-Fieldset ic-Sortable-item__Add-link-fieldset">
          <legend className="screenreader-only">{I18n.t('Custom link details')}</legend>
          <label className="ic-Form-control" htmlFor="admin_settings_custom_link_name">
            <span className="ic-Label">{I18n.t('Link name')}</span>
            <input
              id="admin_settings_custom_link_name"
              ref={c => {
                this.textInputRef = c
              }}
              type="text"
              required
              aria-required="true"
              name={`${namePrefix}[text]`}
              className="ic-Input"
              defaultValue={text}
              onKeyDown={e => this.handleKeyDown(e, 'text')}
              onBlur={e => this.handleChange('text', e.target.value)}
            />
          </label>
          <label className="ic-Form-control" htmlFor="admin_settings_custom_link_subtext">
            <span className="ic-Label">{I18n.t('Link description')}</span>
            <textarea
              id="admin_settings_custom_link_subtext"
              className="ic-Input"
              name={`${namePrefix}[subtext]`}
              defaultValue={subtext}
              onKeyDown={e => this.handleKeyDown(e, 'subtext')}
              onBlur={e => this.handleChange('subtext', e.target.value)}
            />
          </label>
          <label className="ic-Form-control" htmlFor="admin_settings_custom_link_url">
            <span className="ic-Label">{I18n.t('Link URL')}</span>
            <input
              type="url"
              id="admin_settings_custom_link_url"
              required
              aria-required="true"
              disabled={this.props.link.type === 'default'}
              name={`${namePrefix}[url]`}
              className="ic-Input"
              onKeyDown={e => this.handleKeyDown(e, 'url')}
              onBlur={e => this.handleChange('url', e.target.value)}
              placeholder={I18n.t('e.g., http://university.edu/helpdesk')}
              defaultValue={url}
            />
          </label>
          <fieldset className="ic-Fieldset ic-Fieldset--radio-checkbox">
            <legend className="ic-Legend">{I18n.t('Available to')}</legend>
            <div className="ic-Checkbox-group ic-Checkbox-group--inline">
              {CustomHelpLinkConstants.USER_TYPES.map(type => (
                <label
                  key={`${id}_${type.value}`}
                  className="ic-Form-control ic-Form-control--checkbox"
                  htmlFor={`admin_settings_custom_link_type_${type.value}`}
                >
                  <input
                    type="checkbox"
                    id={`admin_settings_custom_link_type_${type.value}`}
                    ref={c => {
                      if (c && c.value === 'user') {
                        this.availableToUserRef = c
                      }
                    }}
                    name={`${namePrefix}[available_to][]`}
                    value={type.value}
                    checked={available_to.indexOf(type.value) > -1}
                    onKeyDown={e => this.handleKeyDown(e, 'available_to')}
                    onChange={e => this.handleAvailableToChange(e.target.value, e.target.checked)}
                  />
                  <span className="ic-Label">{type.label}</span>
                </label>
              ))}
            </div>
          </fieldset>
          <div>
            <button type="submit" className="Button Button--primary" onClick={this.handleSave}>
              {state === 'new' ? I18n.t('Add link') : I18n.t('Update link')}
            </button>
            &nbsp;
            <button className="Button" type="button" onClick={this.handleCancel}>
              {I18n.t('Cancel')}
            </button>
          </div>
        </fieldset>
      </li>
    )
  }
}
