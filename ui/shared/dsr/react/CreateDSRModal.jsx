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
import {func, shape, string, element} from 'prop-types'
import {Button} from '@instructure/ui-buttons'
import {IconCloudDownloadLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Tooltip} from '@instructure/ui-tooltip'

import update from 'immutability-helper'
import {get, isEmpty} from 'lodash'
import axios from '@canvas/axios'
import {datetimeString} from '@canvas/datetime/date-functions'

import {useScope as createI18nScope} from '@canvas/i18n'
import preventDefault from '@canvas/util/preventDefault'
import unflatten from 'obj-unflatten'
import Modal from '@canvas/instui-bindings/react/InstuiModal'

const I18n = createI18nScope('dsr')

const initialState = {
  open: false,
  data: {
    request_name: null,
  },
  latestRequest: null,
  errors: {},
}

export default class CreateDSRModal extends React.Component {
  static propTypes = {
    // whatever you pass as the child, when clicked, will open the dialog
    children: element.isRequired,
    accountId: string.isRequired,
    user: shape({
      id: string.isRequired,
      name: string.isRequired,
      sortable_name: string,
      short_name: string,
      email: string,
      time_zone: string,
    }).isRequired,
    afterSave: func.isRequired,
  }

  state = {...initialState}

  requestRef = React.createRef()

  UNSAFE_componentWillMount() {
    this.setState(
      update(this.state, {
        data: {
          $set: {
            request_name:
              this.props.user.name.replace(/\s+/g, '-') +
              '-' +
              new Date().toISOString().split('T')[0],
            request_output: 'xlsx',
          },
        },
      }),
    )
  }

  creationDisabled = () => {
    const {expires_at, progress_status} = this.state.latestRequest || {}
    return (
      progress_status === 'running' ||
      progress_status === 'queued' ||
      expires_at > new Date().toISOString()
    )
  }

  disabledText = () => {
    const {expires_at, progress_status} = this.state.latestRequest || {}
    if (progress_status === 'running' || progress_status === 'queued') {
      return I18n.t('A request is already in progress')
    } else {
      return I18n.t('The previous request expires %{expires_at}', {
        expires_at: datetimeString(expires_at),
      })
    }
  }

  componentDidUpdate(_prevProps, prevState) {
    if (this.state.open && !prevState.open) {
      this.fetchDsrRequest()
    }
  }

  fetchDsrRequest = () => {
    const url = `/api/v1/accounts/${this.props.accountId}/users/${this.props.user.id}/dsr_request`
    axios.get(url).then(
      response => {
        // if response is not no content, then we have a request
        if (response.status !== 204) {
          const dsrRequest = response.data
          this.setState(update(this.state, {latestRequest: {$set: dsrRequest}}))
        }
      },
      () => {
        // do nothing
      },
    )
  }

  onChange = (field, value) => {
    this.setState(prevState => {
      let newState = update(prevState, {
        data: unflatten({[field]: {$set: value}}),
        errors: {$set: {}},
      })
      if (value === '' || value === undefined) {
        newState = update(newState, {
          errors: {[field]: {$set: [I18n.t('Request name is required')]}},
        })
      }
      return newState
    })
  }

  close = () => this.setState({open: false})

  onSubmit = () => {
    if (!isEmpty(this.state.errors)) {
      this.requestRef.current.focus()
      return
    }
    const url = `/api/v1/accounts/${this.props.accountId}/users/${this.props.user.id}/dsr_request`
    const method = 'POST'

    axios({url, method, data: this.state.data}).then(
      response => {
        const dsr_request = response.data
        const request_name = dsr_request.request_name
        $.flashMessage(
          I18n.t(
            'DSR Request *%{request_name}* was created successfully! You will receive an email upon completion.',
            {request_name},
          ),
        )

        this.close()
        if (this.props.afterSave) this.props.afterSave(response)
      },
      () => {
        $.flashError(I18n.t('Something went wrong creating the DSR request.'))
        this.setState({
          errors: {
            request_name: [I18n.t('Invalid request name')],
          },
        })
      },
    )
  }

  renderPreviousReportStatus = () => {
    switch (this.state.latestRequest.progress_status) {
      case 'completed':
        return (
          <a href={this.state.latestRequest.download_url} target="_blank" rel="noopener noreferrer">
            {this.state.latestRequest.request_name}{' '}
            <IconCloudDownloadLine title={I18n.t('Download')} />
          </a>
        )
      case 'failed':
        return <Text>{I18n.t('Failed')}</Text>
      default:
        return <Text>{I18n.t('In progress')}</Text>
    }
  }

  render = () => (
    <span>
      <Modal
        as="form"
        noValidate={true}
        onSubmit={preventDefault(this.onSubmit)}
        open={this.state.open}
        onDismiss={this.close}
        size="medium"
        label={I18n.t('Create Data Subject Request (DSR)')}
      >
        <Modal.Body>
          <Flex direction="column">
            <Flex.Item padding="small medium">
              <TextInput
                key="request_name"
                ref={this.requestRef}
                renderLabel={I18n.t('DSR Request Name')}
                label={I18n.t('DSR Request Name')}
                data-testid={I18n.t('DSR Request Name')}
                value={get(this.state.data, 'request_name')?.toString() ?? ''}
                onChange={e => this.onChange('request_name', e.target.value)}
                isRequired={true}
                messages={(this.state.errors.request_name || [])
                  .map(errMsg => ({type: 'newError', text: errMsg}))
                  .filter(Boolean)}
              />
            </Flex.Item>
            <Flex.Item as="div" padding="medium medium 0 medium">
              <RadioInputGroup
                name="request_output"
                description={I18n.t('Output Format')}
                layout="columns"
                value={get(this.state.data, 'request_output')?.toString() ?? ''}
                onChange={e => this.onChange('request_output', e.target.value)}
              >
                <RadioInput value="xlsx" label="Excel" />
                {/* Enabled once we agree on a format for PDF */}
                {/* <RadioInput value="pdf" label="PDF" /> */}
              </RadioInputGroup>
            </Flex.Item>
          </Flex>
          {this.state.latestRequest && (
            <View as="div" padding="small medium 0 medium">
              <hr />
              <Text weight="bold">{I18n.t('Latest DSR: ')}</Text>
              {this.renderPreviousReportStatus()}
            </View>
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button onClick={this.close}>{I18n.t('Cancel')}</Button> &nbsp;
          <Tooltip
            renderTip={this.disabledText()}
            on={this.creationDisabled() ? ['hover', 'focus'] : []}
          >
            <Button
              type="submit"
              color="primary"
              disabled={this.creationDisabled()}
              data-testid="submit-button"
            >
              {I18n.t('Create')}
            </Button>
          </Tooltip>
        </Modal.Footer>
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
