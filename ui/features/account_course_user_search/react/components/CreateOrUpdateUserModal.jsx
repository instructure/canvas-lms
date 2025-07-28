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

import $ from 'jquery'
import React from 'react'
import {bool, func, shape, string, element, oneOf} from 'prop-types'
import {Button} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import update from 'immutability-helper'
import { TextInput } from '@instructure/ui-text-input'
import {get} from 'lodash'
import axios from '@canvas/axios'

import {useScope as createI18nScope} from '@canvas/i18n'
import {
  firstNameFirst,
  lastNameFirst,
  nameParts,
} from '@canvas/user-sortable-name/jquery/user_utils'
import preventDefault from '@canvas/util/preventDefault'
import unflatten from 'obj-unflatten'
import registrationErrors from '@canvas/normalize-registration-errors'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import TimeZoneSelect from '@canvas/datetime/react/components/TimeZoneSelect'

const I18n = createI18nScope('account_course_user_search')

const trim = (str = '') => str.trim()

const initialState = {
  open: false,
  data: {
    user: {},
    pseudonym: {
      send_confirmation: true,
    },
  },
  errors: {},
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
      time_zone: string,
    }),
    customized_login_handle_name: string,
    delegated_authentication: bool,
    showSIS: bool,
    afterSave: func.isRequired,
  }

  static defaultProps = {
    customized_login_handle_name: window.ENV.customized_login_handle_name,
    delegated_authentication: window.ENV.delegated_authentication,
    showSIS: window.ENV.SHOW_SIS_ID_IN_NEW_USER_FORM,
  }

  nameRef = React.createRef()
  uniqueRef = React.createRef()
  pathRef = React.createRef()
  emailRef = React.createRef()

  state = {...initialState}

  UNSAFE_componentWillMount() {
    if (this.props.createOrUpdate === 'update') {
      // only get the attributes from the user that we are actually going to show in the <input>s
      // and send to the server. Because if we send the server extraneous attributes like user[id]
      // it throws 401 errors
      const userDataFromProps = {
        name: this.props.user.name,
        sortable_name: this.props.user.sortable_name,
        short_name: this.props.user.short_name,
        email: this.props.user.email,
        time_zone: this.props.user.time_zone
      }

      this.setState(update(this.state, {data: {user: {$set: userDataFromProps}}}))
    }
  }

  onChange = (field, value) => {
    this.setState(prevState => {
      let newState = update(prevState, {
        data: unflatten({[field]: {$set: value}}),
        errors: {$set: prevState.errors},
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
    this.isBlank(field, value)
  }

  close = () => this.setState({open: false})

  onSubmit = async () => {
    if (await this.hasErrors(this.state.errors)) return
    const method = {create: 'POST', update: 'PUT'}[this.props.createOrUpdate]

    // exclude email if it's blank
    const {user, pseudonym} = this.state.data
    let userData = user
    if (user.email === "" || user.email == null) {
      const {email, ...rest} = user
      userData = rest
    }
    axios({url: this.props.url, method, data: {user: userData, pseudonym}}).then(
      response => {
        const getUserObj = o => (o.user ? getUserObj(o.user) : o)
        const user = getUserObj(response.data)
        const userName = user.name
        const wrapper = `<a href='/users/${user.id}'>$1</a>`
        $.flashMessage(
          response.data.message_sent
            ? I18n.t(
                '*%{userName}* saved successfully! They should receive an email confirmation shortly.',
                {userName, wrapper}
              )
            : I18n.t('*%{userName}* saved successfully!', {userName, wrapper})
        )

        this.setState({...initialState})
        if (this.props.afterSave) this.props.afterSave(response)
      },
      ({response}) => {
        const errors = registrationErrors(response.data.errors)
        $.flashError('Something went wrong saving user details.')
        this.setState({errors})
      }
    )
  }

  hasErrors = async () => {
    const showCustomizedLoginId = this.props.customized_login_handle_name || this.props.delegated_authentication

    if (this.props.createOrUpdate === 'create' && showCustomizedLoginId) {
      if (await this.isBlank('pseudonym[path]')) {
        this.pathRef.current.focus()
      }
    }
    if (this.props.createOrUpdate === 'create') {
      if (await this.isBlank('pseudonym[unique_id]')) {
        this.uniqueRef.current.focus()
      }
    } else {
      if (await this.isBlank('user[email]')) {
        this.emailRef.current.focus()
      }
    }
    if (await this.isBlank('user[name]')) {
      this.nameRef.current.focus()
    }
    const errorArray = Object.values(this.state.errors)
    return errorArray.some(error => error !== undefined)
  }

  isBlank = (field, currentValue) => {
    // return true/false after state is set
    return new Promise((resolve) => {
      let isBlank = true

      this.setState((prevState) => {
        const updatedValue =
          currentValue !== undefined ? currentValue : get(this.state.data, field)?.toString()
        let newState = update(prevState, {
          data: { $set: prevState.data },
          errors: { $set: prevState.errors },
        })

        if (updatedValue === '' || updatedValue === undefined) {
          if (field === 'user[name]') {
            newState = update(newState, {
              errors: { [field]: { $set: I18n.t('Name is required.') } },
            })
          } else if (field === 'pseudonym[unique_id]') {
            newState = update(newState, {
              errors: { [field]: { $set: I18n.t('Email is required.') } },
            })
          } else if (field === 'pseudonym[path]') {
            const message = this.props.customized_login_handle_name ? I18n.t('%{login_handle} is required', {
              login_handle: this.props.customized_login_handle_name,
            }) : I18n.t('Email is required')
            newState = update(newState, {
              errors: { [field]: { $set: message } },
            })
          } else {
            newState = update(newState, { errors: { [field]: { $set: undefined } } })
            isBlank = false
          }
        } else if (field === 'user[email]') {
          // we are doing the same validation the backend does
          // so we are requiring a domain for the email
          const splitEmail = updatedValue.split('@')
          const domain = splitEmail.length > 1 ? splitEmail[1] : ''
          if (domain === '') {
            newState = update(newState, {
              errors: { [field]: { $set: I18n.t('Email is invalid.') } },
            })
          } else {
            newState = update(newState, { errors: { [field]: { $set: undefined } } })
            isBlank = false
          }
        } else {
          newState = update(newState, { errors: { [field]: { $set: undefined } } })
          isBlank = false
        }

        return newState
      }, () => {
        resolve(isBlank)
      })
    })
  }

  renderMessage = message => {
    if (message === undefined) return []
    return [{text: message, type: 'newError'}]
  }

  renderNameFields = () => {
    const nameField = 'user[name]'
    const shortField = 'user[short_name]'
    const sortField = 'user[sortable_name]'

    const nameErrors = this.renderMessage(this.state.errors[nameField])
    const nameHint = [{type: 'hint', text: I18n.t('This name will be used by teachers for grading.')}]
    return (
      <>
        <TextInput
          data-testid='Full Name'
          name={nameField}
          renderLabel={I18n.t('Full Name')}
          isRequired={true}
          onChange={e => this.onChange(nameField, e.target.value)}
          value={get(this.state.data, nameField)?.toString()}
          ref={this.nameRef}
          messages={nameErrors.length > 0 ? nameErrors : nameHint}
        />
        <TextInput
          name={shortField}
          renderLabel={I18n.t('Display Name')}
          onChange={e => this.onChange(shortField, e.target.value)}
          value={get(this.state.data, shortField)?.toString()}
          messages={[{type: 'hint', text: I18n.t('People will see this name in discussions, messages and comments.')}]}
        />
        <TextInput
          data-testid='Sortable Name'
          name={sortField}
          renderLabel={I18n.t('Sortable Name')}
          onChange={e => this.onChange(sortField, e.target.value)}
          value={get(this.state.data, sortField)?.toString()}
          messages={[{type: 'hint', text: I18n.t('This name appears in sorted lists.')}]}
          />
      </>
    )
  }

  renderCreateFields = () => {
    const showCustomizedLoginId = this.props.customized_login_handle_name || this.props.delegated_authentication
    const uniqueField = 'pseudonym[unique_id]'
    const pathField = 'pseudonym[path]'
    const sisField = 'pseudonym[sis_user_id]'
    const confirmationField = 'pseudonym[send_confirmation]'

    const emailErrors = this.renderMessage(this.state.errors[uniqueField])
    const emailHint = [{type: 'hint', text: I18n.t('This email will be used for login.')}]
    return (
      <>
        <TextInput
          name={uniqueField}
          data-testid='Email'
          renderLabel={this.props.customized_login_handle_name || I18n.t('Email')}
          isRequired={true}
          onChange={e => this.onChange(uniqueField, e.target.value)}
          value={get(this.state.data, uniqueField)?.toString()}
          ref={this.uniqueRef}
          messages={emailErrors.length > 0 ? emailErrors : emailHint}
        />
        {showCustomizedLoginId ?
          <TextInput
            name={pathField}
            renderLabel={I18n.t('Email')}
            isRequired={true}
            onChange={e => this.onChange(pathField, e.target.value)}
            value={get(this.state.data, pathField)?.toString()}
            ref={this.pathRef}
          />
         : null}
        {this.props.showSIS ?
          <TextInput
            name={sisField}
            renderLabel={I18n.t('SIS ID')}
            onChange={e => this.onChange(sisField, e.target.value)}
            value={get(this.state.data, sisField)?.toString()}
          />
          : null}
        <Checkbox
          name={confirmationField}
          label={I18n.t('Email the user about this account creation')}
          onChange={e => this.onChange(confirmationField, e.target.checked)}
          checked={get(this.state.data, confirmationField)}
        />
      </>
    )
  }

  renderUpdateFields = () => {
    const emailField = 'user[email]'
    const timeField = 'user[time_zone]'

    const emailErrors = this.renderMessage(this.state.errors[emailField])
    const emailHint = [{text: I18n.t('This email will be used for login.'), type: 'hint'}]
    return (
      <>
        <TextInput
          name={emailField}
          renderLabel={I18n.t('Default Email')}
          onChange={e => this.onChange(emailField, e.target.value)}
          value={get(this.state.data, emailField)?.toString()}
          ref={this.emailRef}
          messages={emailErrors.length > 0 ? emailErrors : emailHint}
        />
        <TimeZoneSelect
          name={timeField}
          renderLabel={I18n.t('Time Zone')}
          onChange={e => this.onChange(timeField, e.target.value)}
          value={get(this.state.data, timeField)?.toString()}
        />
      </>
    )
  }

  render = () => {
    return (
    <span>
      <Modal
        noValidate={true}
        open={this.state.open}
        onDismiss={this.close}
        size="medium"
        label={
          this.props.createOrUpdate === 'create'
            ? I18n.t('Add a New User')
            : I18n.t('Edit User Details')
        }
      >
        <form style={{margin: '0px'}} onSubmit={preventDefault(this.onSubmit)}>
          <Modal.Body>
            <Flex gap='small' direction='column'>
              {this.renderNameFields()}
              {this.props.createOrUpdate === 'create' ? this.renderCreateFields() : this.renderUpdateFields()}
            </Flex>
          </Modal.Body>
          <Modal.Footer>
            <Button onClick={this.close}>{I18n.t('Cancel')}</Button> &nbsp;
            <Button type="submit" color="primary">
              {this.props.createOrUpdate === 'create' ? I18n.t('Add User') : I18n.t('Save')}
            </Button>
          </Modal.Footer>
        </form>
      </Modal>
      {React.Children.map(this.props.children, child =>
        // when you click whatever is the child element to this, open the modal
        React.cloneElement(child, {
          onClick: () => {
            this.setState({open: true})
          },
        }),
      )}
    </span>
    )
  }
}
