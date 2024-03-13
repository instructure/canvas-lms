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

import {useScope as useI18nScope} from '@canvas/i18n'
import {map, each, isEmpty, compact} from 'lodash'
import $ from 'jquery'
import React from 'react'
import createReactClass from 'create-react-class'
import PropTypes from 'prop-types'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import ConfigOptionField from './ConfigOptionField'
import ExternalTool from '@canvas/external-tools/backbone/models/ExternalTool'
import '@canvas/jquery/jquery.disableWhileLoading'
import '@canvas/rails-flash-notifications'
import {Button} from '@instructure/ui-buttons'

const I18n = useI18nScope('external_tools')

// eslint-disable-next-line react/prefer-es6-class
export default createReactClass({
  displayName: 'AddApp',

  propTypes: {
    handleToolInstalled: PropTypes.func.isRequired,
    app: PropTypes.object.isRequired,
  },

  getInitialState() {
    return {
      modalIsOpen: false,
      errorMessage: null,
      fields: {},
    }
  },

  componentDidMount() {
    const fields = {}

    fields.name = {
      type: 'text',
      value: this.props.app.name,
      required: true,
      description: I18n.t('Name'),
    }

    if (this.props.app.requires_secret) {
      fields.consumer_key = {
        type: 'text',
        value: '',
        required: true,
        description: I18n.t('Consumer Key'),
      }
      fields.shared_secret = {
        type: 'text',
        value: '',
        required: true,
        description: I18n.t('Shared Secret'),
      }
    }

    this.props.app.config_options.forEach(opt => {
      fields[opt.name] = {
        type: opt.param_type,
        value: opt.default_value,
        required: opt.is_required || opt.is_required === 1,
        description: opt.description,
      }
    })

    // eslint-disable-next-line react/no-is-mounted
    if (this.isMounted()) {
      this.setState({fields}, this.validateConfig)
      this.refs.addTool.focus()
    }
  },

  handleChange(e) {
    const target = e.target
    let value = target.value
    const name = $(target).data('rel')
    const fields = this.state.fields

    if (target.type === 'checkbox') {
      value = target.checked
    }

    fields[name].value = value
    this.setState({fields}, this.validateConfig)
  },

  validateConfig() {
    const invalidFields = compact(
      map(this.state.fields, (v, k) => {
        if (v.required && isEmpty(v.value)) {
          return k
        }
      })
    )
    this.setState({invalidFields})
  },

  openModal(e) {
    e.preventDefault()
    // eslint-disable-next-line react/no-is-mounted
    if (this.isMounted()) {
      this.setState({modalIsOpen: true})
    }
  },

  closeModal(cb) {
    if (typeof cb === 'function') {
      this.setState({modalIsOpen: false}, cb)
    } else {
      this.setState({modalIsOpen: false})
    }
  },

  configSettings() {
    const queryParams = {}
    each(this.state.fields, (v, k) => {
      if (v.type === 'checkbox') {
        if (!v.value) return
        queryParams[k] = '1'
      } else queryParams[k] = encodeURIComponent(v.value)
    })
    delete queryParams.consumer_key
    delete queryParams.shared_secret

    return queryParams
  },

  submit(e) {
    const newTool = new ExternalTool()
    newTool.on('sync', this.onSaveSuccess, this)
    newTool.on('error', this.onSaveFail, this)
    if (!isEmpty(this.state.invalidFields)) {
      const fields = this.state.fields
      const invalidFieldNames = map(this.state.invalidFields, k => fields[k].description).join(', ')
      this.setState({
        errorMessage: I18n.t('The following fields are invalid: %{fields}', {
          fields: invalidFieldNames,
        }),
      })
      return
    }

    if (this.props.app.requires_secret) {
      newTool.set('consumer_key', this.state.fields.consumer_key.value)
      newTool.set('shared_secret', this.state.fields.shared_secret.value)
    } else {
      newTool.set('consumer_key', 'N/A')
      newTool.set('shared_secret', 'N/A')
    }

    newTool.set('name', this.state.fields.name.value)
    newTool.set('app_center_id', this.props.app.short_name)
    newTool.set('config_settings', this.configSettings())

    $(e.target).prop('disabled', true)

    newTool.save()
  },

  onSaveSuccess(tool) {
    $(this.addButtonRef).removeAttr('disabled')
    tool.off('sync', this.onSaveSuccess)
    this.setState({errorMessage: null})
    this.closeModal(this.props.handleToolInstalled)
  },

  onSaveFail(_tool) {
    $(this.addButtonRef).removeAttr('disabled')
    this.setState({
      errorMessage: I18n.t('There was an error in processing your request'),
    })
  },

  configOptions() {
    return map(this.state.fields, (v, k) => (
      <ConfigOptionField
        name={k}
        type={v.type}
        ref={'option_' + k}
        key={'option_' + k}
        value={v.value}
        required={v.required}
        aria-required={v.required}
        description={v.description}
        handleChange={this.handleChange}
      />
    ))
  },

  errorMessage() {
    if (this.state.errorMessage) {
      $.screenReaderFlashMessage(this.state.errorMessage)
      return <div className="alert alert-error">{this.state.errorMessage}</div>
    }
  },

  render() {
    return (
      <div className="AddApp">
        {/* TODO: use InstUI button */}
        {/* eslint-disable-next-line jsx-a11y/anchor-is-valid */}
        <a
          href="#"
          ref="addTool"
          className="btn btn-primary btn-block add_app icon-add"
          onClick={this.openModal}
        >
          {I18n.t('Add App')}
        </a>

        <Modal
          open={this.state.modalIsOpen}
          onDismiss={this.closeModal}
          label={I18n.t('Add App')}
          shouldCloseOnDocumentClick={false}
        >
          <Modal.Body>
            {this.errorMessage()}
            <form>{this.configOptions()}</form>
          </Modal.Body>
          <Modal.Footer>
            <Button onClick={this.closeModal}>{I18n.t('Close')}</Button>
            &nbsp;
            <Button onClick={this.submit} color="primary">
              {I18n.t('Add App')}
            </Button>
          </Modal.Footer>
        </Modal>
      </div>
    )
  },
})
