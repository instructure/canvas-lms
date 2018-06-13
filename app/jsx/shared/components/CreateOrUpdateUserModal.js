/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {bool, func, shape, string, element, oneOf} from 'prop-types'
import Avatar from '@instructure/ui-elements/lib/components/Avatar'
import Button from '@instructure/ui-buttons/lib/components/Button'
import Checkbox from '@instructure/ui-forms/lib/components/Checkbox'
import FormFieldGroup from '@instructure/ui-forms/lib/components/FormFieldGroup'
import TextInput from '@instructure/ui-forms/lib/components/TextInput'
import update from 'immutability-helper'
import {get, isEmpty} from 'lodash'
import axios from 'axios'

import I18n from 'i18n!account_course_user_search'
import {firstNameFirst, lastNameFirst, nameParts} from 'user_utils'
import preventDefault from 'compiled/fn/preventDefault'
import unflatten from 'compiled/object/unflatten'
import registrationErrors from 'compiled/registration/registrationErrors'
import InstuiModal, {ModalBody, ModalFooter} from './InstuiModal'
import TimeZoneSelect from './TimeZoneSelect'

const trim = (str = '') => str.trim()

const initialState = {
  open: false,
  data: {
    user: {},
    pseudonym: {
      send_confirmation: true
    }
  },
  errors: {}
}

export default class CreateOrUpdateUserModal extends React.Component {
  static propTypes = {
    // whatever you pass as the child, when clicked, will open the dialog
    children: element.isRequired,
    createOrUpdate: oneOf(['create', 'update']).isRequired,
    url: string.isRequired,
    user: shape({
      name: string.isRequired,
      sortable_name: string,
      short_name: string,
      email: string,
      time_zone: string
    }),
    customized_login_handle_name: string,
    delegated_authentication: bool.isRequired,
    showSIS: bool.isRequired,
    afterSave: func.isRequired
  }

  static defaultProps = {
    customized_login_handle_name: window.ENV.customized_login_handle_name,
    delegated_authentication: window.ENV.delegated_authentication,
    showSIS: window.ENV.SHOW_SIS_ID_IN_NEW_USER_FORM
  }

  state = {...initialState}

  componentWillMount() {
    if (this.props.createOrUpdate === 'update') {
      // only get the attributes from the user that we are actually going to show in the <input>s
      // and send to the server. Because if we send the server extraneous attributes like user[id]
      // it throws 401 errors
      const userDataFromProps = this.getInputFields().reduce((memo, {name}) => {
        const key = name.match(/user\[(.*)\]/)[1] // extracts 'short_name' from 'user[short_name]'
        return {...memo, [key]: this.props.user[key]}
      }, {})
      this.setState(update(this.state, {data: {user: {$set: userDataFromProps}}}))
    }
  }

  onChange = (field, value) => {
    this.setState(prevState => {
      let newState = update(prevState, {
        data: unflatten({[field]: {$set: value}}),
        errors: {$set: {}}
      })

      // set sensible defaults for sortable_name and short_name
      if (field === 'user[name]') {
        const u = prevState.data.user
        // shamelessly copypasted from user_sortable_name.js
        const sortableNameParts = nameParts(trim(u.sortable_name))
        if (!trim(u.sortable_name) || trim(firstNameFirst(sortableNameParts)) === trim(u.name)) {
          const newSortableName = lastNameFirst(nameParts(value, sortableNameParts[1]))
          newState = update(newState, {data: {user: {sortable_name: {$set: newSortableName}}}})
        }
        if (!trim(u.short_name) || trim(u.short_name) === trim(u.name)) {
          newState = update(newState, {data: {user: {short_name: {$set: value}}}})
        }
      }
      return newState
    })
  }

  close = () => this.setState({open: false})

  onSubmit = () => {
    if (!isEmpty(this.state.errors)) return
    const method = {create: 'POST', update: 'PUT'}[this.props.createOrUpdate]
    axios({url: this.props.url, method, data:this.state.data}).then(response => {
      const getUserObj = o => o.user ? getUserObj(o.user) : o
      const user = getUserObj(response.data)
      const userName = user.name
      const wrapper = `<a href='/users/${user.id}'>$1</a>`
      $.flashMessage(response.data.message_sent
        ? I18n.t('*%{userName}* saved successfully! They should receive an email confirmation shortly.', {userName, wrapper})
        : I18n.t('*%{userName}* saved successfully!', {userName, wrapper})
      )

      this.setState({...initialState})
      if (this.props.afterSave) this.props.afterSave(response)
    }, ({response}) => {
      const errors = registrationErrors(response.data.errors)
      $.flashError('Something went wrong saving user details.')
      this.setState({errors})
    })
  }

  getInputFields = () => {
    const showCustomizedLoginId = (this.props.customized_login_handle_name || this.props.delegated_authentication)
    return [
      {
        name: 'user[name]',
        label: I18n.t('Full Name'),
        hint: I18n.t('This name will be used by teachers for grading.'),
        required: I18n.t('Full name is required')
      },
      {
        name: 'user[short_name]',
        label: I18n.t('Display Name'),
        hint: I18n.t('People will see this name in discussions, messages and comments.')
      },
      {
        name: 'user[sortable_name]',
        label: I18n.t('Sortable Name'),
        hint: I18n.t('This name appears in sorted lists.')
      }
    ].concat(this.props.createOrUpdate === 'create' ? [
      {
        name: 'pseudonym[unique_id]',
        label: this.props.customized_login_handle_name || I18n.t('Email'),
        required: this.props.customized_login_handle_name
          ? I18n.t('%{login_handle} is required', {login_handle: this.props.customized_login_handle_name})
          : I18n.t('Email is required')
      },
      (showCustomizedLoginId && {
        name: 'pseudonym[path]',
        label: I18n.t('Email'),
        required: I18n.t('Email is required')
      }),
      (this.props.showSIS && {
        name: 'pseudonym[sis_user_id]',
        label: I18n.t('SIS ID'),
      }),
      {
        name: 'pseudonym[send_confirmation]',
        label: I18n.t('Email the user about this account creation'),
        Component: Checkbox
      }
    ] : [
      {
        name: 'user[email]',
        label: I18n.t('Default Email')
      },
      {
        name: 'user[time_zone]',
        label: I18n.t('Time Zone'),
        Component: TimeZoneSelect
      }
    ]).filter(Boolean)
  }

  render = () => (
    <span>
      <InstuiModal
        open={this.state.open}
        onDismiss={this.close}
        size="small"
        label={this.props.createOrUpdate === 'create'
          ? I18n.t('Add a New User')
          : (
            <span>
              <Avatar
                size="small"
                name={this.state.data.user.name}
                src={this.props.user.avatar_url}
              />
              {' '}
              {I18n.t('Edit User Details')}
            </span>
          )
        }
      >
        <form onSubmit={preventDefault(this.onSubmit)} style={{marginBottom: 0}}>
          <ModalBody>
            <FormFieldGroup layout="stacked" rowSpacing="small" description="">
              {this.getInputFields().map(({name, label, hint, required, Component = TextInput}) => (
                <Component
                  key={name}
                  label={label}
                  value={get(this.state.data, name)}
                  checked={get(this.state.data, name)}
                  onChange={e => this.onChange(name, e.target.type === 'checkbox'
                    ? e.target.checked
                    : e.target.value
                  )}
                  required={!!required}
                  layout="inline"
                  messages={(this.state.errors[name] || [])
                    .map(errMsg => ({type: 'error', text: errMsg}))
                    .concat(hint && {type: 'hint', text: hint})
                    .filter(Boolean)}
                />
              ))}
            </FormFieldGroup>
          </ModalBody>
          <ModalFooter>
            <Button onClick={this.close}>{I18n.t('Cancel')}</Button> &nbsp;
            <Button type="submit" variant="primary">
              {this.props.createOrUpdate === 'create'
                ? I18n.t('Add User')
                : I18n.t('Save')
              }
            </Button>
          </ModalFooter>
        </form>
      </InstuiModal>
      {React.Children.map(this.props.children, child =>
        // when you click whatever is the child element to this, open the modal
        React.cloneElement(child, {
          onClick: (...args) => {
            if (child.props.onClick) child.props.onClick(...args)
            this.setState({open: true})
          }
        })
      )}
    </span>
  )
}
