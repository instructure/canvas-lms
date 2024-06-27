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
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {View} from '@instructure/ui-view'

import update from 'immutability-helper'
import {get, isEmpty} from 'lodash'
import axios from '@canvas/axios'

import {useScope as useI18nScope} from '@canvas/i18n'
import preventDefault from '@canvas/util/preventDefault'
import unflatten from 'obj-unflatten'
import Modal from '@canvas/instui-bindings/react/InstuiModal'

const I18n = useI18nScope('account_course_user_search')

const trim = (str = '') => str.trim()

const initialState = {
  open: false,
  data: {
    request_name: null,
  },
  errors: {},
}

export default class CreateDSRModal extends React.Component {
  static propTypes = {
    // whatever you pass as the child, when clicked, will open the dialog
    children: element.isRequired,
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

  state = {...initialState}

  UNSAFE_componentWillMount() {
      this.setState(update(this.state, {data: {
        $set: {
          request_name: ENV.ROOT_ACCOUNT_NAME.toString().replace(/\s+/g, '-') + '-' + (new Date).toISOString().split('T')[0],
          request_output: "xlsx",
        }
      }}))
  }

  onChange = (field, value) => {
    this.setState(prevState => {
      let newState = update(prevState, {
        data: unflatten({[field]: {$set: value}}),
        errors: {$set: {}},
      })
      return newState
    })
  }

  close = () => this.setState({open: false})

  onSubmit = () => {
    if (!isEmpty(this.state.errors)) return
    const method = 'POST'
    // eslint-disable-next-line promise/catch-or-return
    axios({url: this.props.url, method, data: this.state.data}).then(
      response => {
        const dsr_request = response.data
        const request_name = dsr_request.request_name
        $.flashMessage(
          I18n.t(
            'DSR Request *%{request_name}* was created successfully! You will receive an email upon completion.',
            {request_name}
          )
        )

        this.setState({...initialState})
        if (this.props.afterSave) this.props.afterSave(response)
      },
      ({response}) => {
        $.flashError('Something went wrong creating the DSR request.')
        this.setState({errors: {
          request_name: ["Invalid request name"]
          },
        })
      }
    )
  }

  render = () => (
    <span>
      <Modal
        as="form"
        onSubmit={preventDefault(this.onSubmit)}
        open={this.state.open}
        onDismiss={this.close}
        size="medium"
        label={
          I18n.t('Create DSR Request')
        }
      >
        <Modal.Body>
          <FormFieldGroup layout="stacked" rowSpacing="small" description="">
                <TextInput
                  key="request_name"
                  renderLabel={<>
                    {I18n.t('DSR Request Name')} <Text color="danger"> *</Text>
                  </>}
                  label={ I18n.t('DSR Request Name')}
                  data-testid={ I18n.t('DSR Request Name') }
                  value={get(this.state.data, "request_name")?.toString() ?? ''}
                  onChange={e =>
                    this.onChange("request_name", e.target.value)
                  }
                  isRequired={true}
                  layout="inline"
                  messages={(this.state.errors["request_name"] || [])
                    .map(errMsg => ({type: 'error', text: errMsg}))
                    .concat({type: 'hint', text: I18n.t('This is a a common tracking ID for DSR requests.')})
                    .filter(Boolean)}
                />
                <View as="div" padding="0 0 0 medium">
                  <RadioInputGroup
                    name="request_output"
                    description="Output Format"
                    layout="columns"
                    value={get(this.state.data, "request_output")?.toString() ?? ''}
                    onChange={e =>
                      this.onChange("request_output", e.target.value)
                    }
                  >
                    <RadioInput value="xlsx" label="Excel" />
                    {/* Enabled once we agree on a format for PDF */}
                    {/* <RadioInput value="pdf" label="PDF" /> */}
                  </RadioInputGroup>
                </View>
          </FormFieldGroup>
        </Modal.Body>
        <Modal.Footer>
          <Button onClick={this.close}>{I18n.t('Cancel')}</Button> &nbsp;
          <Button type="submit" color="primary">
            { I18n.t('Create') }
          </Button>
        </Modal.Footer>
      </Modal>
      {React.Children.map(this.props.children, child =>
        // when you click whatever is the child element to this, open the modal
        React.cloneElement(child, {
          onClick: (...args) => {
            if (child.props.onClick) child.props.onClick(...args)
            this.setState({open: true})
          },
        })
      )}
    </span>
  )
}
