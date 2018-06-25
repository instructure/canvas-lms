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
import I18n from 'i18n!message_students'
import axios from 'axios'
import Button from '@instructure/ui-buttons/lib/components/Button'
import TextInput from '@instructure/ui-forms/lib/components/TextInput'
import TextArea from '@instructure/ui-forms/lib/components/TextArea'
import Modal, { ModalBody, ModalFooter } from './components/InstuiModal'
import FormField from '@instructure/ui-forms/lib/components/FormField'
import Alert from '@instructure/ui-alerts/lib/components/Alert'

  class MessageStudents extends React.Component {
    static propTypes = {
      // Data for endpoint
      body: PropTypes.string,
      bulkMessage: PropTypes.bool,
      contextCode: PropTypes.string.isRequired,
      groupConversation: PropTypes.bool,
      mode: PropTypes.string,
      recipients: PropTypes.array,
      subject: PropTypes.string,

      // Form display
      title: PropTypes.string,
      children: PropTypes.element,

      // Callbacks
      onExited: PropTypes.func,
      onRequestClose: PropTypes.func,
    }

    static defaultProps = {
      bulkMessage: true,
      groupConversation: true,
      mode: 'async',
      recipients: []
    }

    constructor (props) {
      super(props)
      this.state = this.initialState
    }

    // Utility

    get initialState () {
      return {
        data: {
          body: '',
          recipients: this.props.recipients,
          subject: ''
        },
        errors: {},
        hideAlert: false,
        open: true,
        sending: false,
        success: false
      }
    }

    composeRequestData () {
      return {
        ...this.state.data,
        recipients: this.state.data.recipients.map((recipient) => {
          return recipient.id
        }),
        bulk_message: this.props.bulkMessage,
        context_code: this.props.contextCode,
        group_conversation: this.props.groupConversation,
        mode: this.props.mode
      }
    }

    errorMessagesFor (field) {
      return this.state.errors[field] ? [{
        text: this.state.errors[field],
        type: 'error'
      }] : null
    }

    sendMessage (data) {
      const config = {
        headers: {
          'Accept': 'application/json'
        }
      }

      this.setState({
        hideAlert: false,
        sending: true
      })

      axios.post('/api/v1/conversations', data, config)
      .then(this.handleResponseSuccess)
      .catch(this.handleResponseError)
    }

    validationErrors (data) {
      const fields = ['subject', 'body']
      let errors = {}
      fields.forEach((field) => {
        if (data[field].length === 0) {
          errors[field] = I18n.t("Please provide a %{field}", {
            field: field
          })
        }
      })

      if (
        typeof errors.subject === 'undefined' &&
        data.subject.length > 255
      ) {
        errors.subject = I18n.t("Subject must contain fewer than 255 characters.")
      }

      return errors
    }

    // Event & pseudo-event handlers

    handleAlertClose = (e) => {
      this.setState({
        hideAlert: true
      })
    }

    handleChange (field, value) {
      let { data, errors } = this.state
      const newData = {}
      newData[field] = value
      data = { ...data, ...newData }
      delete errors[field]
      this.setState({ data, errors: errors })
    }

    handleClose = (e) => {
      if (e) {
        e.preventDefault()
      }

      this.setState({
        open: false
      })
    }

    handleSubmit = (e) => {
      e.preventDefault()
      const data = this.composeRequestData()
      const errors = this.validationErrors(data)
      if (Object.keys(errors).length > 0) {
        this.setState({
          errors: errors,
          hideAlert: false
        })
      } else {
        this.sendMessage(data)
      }
    }

    // Request handlers

    handleResponseError = (error) => {
      let serverErrors = {}
      if (error.response) {
        const errorData = error.response.data
        errorData.forEach((error) => {
          serverErrors[error.attribute] = error.message
        })
      } else {
        serverErrors['request'] = error.message
      }
      this.setState({
        errors: serverErrors,
        sending: false
      })
    }

    handleResponseSuccess = () => {
      setTimeout(() => {
        this.setState({
          ...this.initialState,
          open: false
        })
      }, 2500)
      this.setState({
        hideAlert: false,
        success: true,
        sending: false
      })
    }

    // Render & render helpers

    renderAlert (message, variant, shouldRender) {
      if (shouldRender() && !this.state.hideAlert) {
        return (
          <div className="MessageStudents__Alert">
            <Alert 
              variant={variant}
              closeButtonLabel={I18n.t('Close')}
              onDismiss={this.handleAlertClose}
              transition="none"
            >
              {message}
            </Alert>
          </div>
        );
      } else { return null }
    }

    render () {
      if (!this.state.open) {
        return null
      }

      const onTextChange = field =>
        e => this.handleChange(field, e.target.value)

      const tokens = this.state.data.recipients.map((recipient) => {
        const displayName = recipient.displayName || recipient.email
        return (
          <li key={recipient.id} className="ac-token">{displayName}</li>
        )
      })

      return (
        <div className="MessageStudents">
          <Modal
            open={this.state.open}
            transition="fade"
            label={this.props.title}
            onDismiss={this.props.onRequestClose}
            size='medium'
            onExited={this.props.onExited}
          >
            <ModalBody>
              {this.renderAlert(I18n.t("Your message was sent!"), 'success', () => {
                return this.state.success
              })}
              {this.renderAlert(I18n.t("We're sending your message..."), 'info', () => {
                return this.state.sending
              })}
              {this.renderAlert(I18n.t("There was a problem sending your message."), 'error', () => {
                return Object.keys(this.state.errors).length > 0
              })}
              <form onSubmit={this.handleSubmit} className="MessageStudents__Form">
                <div className="MessageStudents__FormField">
                  <div className="ac">
                    <FormField id='recipients' label={I18n.t('To')}>
                      <ul className="ac-token-list">
                        {tokens}
                      </ul>
                    </FormField>
                  </div>
                </div>
                <div className="MessageStudents__FormField">
                  <TextInput
                    label={I18n.t("Subject")}
                    defaultValue={this.props.subject}
                    onChange={onTextChange('subject')}
                    messages={this.errorMessagesFor('subject')}
                    disabled={this.state.sending || this.state.success}
                  />
                </div>
                <div className="MessageStudents__FormField">
                  <TextArea
                    label={I18n.t("Body")}
                    defaultValue={this.props.body}
                    onChange={onTextChange('body')}
                    messages={this.errorMessagesFor('body')}
                    disabled={this.state.sending || this.state.success}
                  />
                </div>
              </form>
            </ModalBody>
            <ModalFooter>
              <Button disabled={this.state.sending || this.state.success}
                onClick={this.handleClose}>{I18n.t('Close')}</Button>&nbsp;
              <Button disabled={this.state.sending || this.state.success}
                onClick={this.handleSubmit} variant="primary">
                {I18n.t('Send Message')}
              </Button>
            </ModalFooter>
          </Modal>
        </div>
      );
    }
  }

export default MessageStudents
