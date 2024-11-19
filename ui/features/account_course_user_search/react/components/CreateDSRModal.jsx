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

import update from 'immutability-helper'
import {get, isEmpty} from 'lodash'
import axios from '@canvas/axios'

import {useScope as useI18nScope} from '@canvas/i18n'
import preventDefault from '@canvas/util/preventDefault'
import unflatten from 'obj-unflatten'
import Modal from '@canvas/instui-bindings/react/InstuiModal'

const I18n = useI18nScope('account_course_user_search')

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
      })
    )
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
      }
    )
  }

  onChange = (field, value) => {
    this.setState(prevState => {
      const newState = update(prevState, {
        data: unflatten({[field]: {$set: value}}),
        errors: {$set: {}},
      })
      return newState
    })
  }

  close = () => this.setState({open: false})

  onSubmit = () => {
    if (!isEmpty(this.state.errors)) return
    const url = `/api/v1/accounts/${this.props.accountId}/users/${this.props.user.id}/dsr_request`
    const method = 'POST'
    // eslint-disable-next-line promise/catch-or-return
    axios({url, method, data: this.state.data}).then(
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
      () => {
        $.flashError(I18n.t('Something went wrong creating the DSR request.'))
        this.setState({
          errors: {
            request_name: ['Invalid request name'],
          },
        })
      }
    )
  }

  renderPreviousReportStatus = () => {
    switch (this.state.latestRequest.progress_status) {
      case 'completed':
        return (
          <a
            href={this.state.latestRequest.download_url}
            target="_blank"
            rel="noopener noreferrer"
          >
            {this.state.latestRequest.request_name}{' '}
            <IconCloudDownloadLine title={I18n.t('Download')} />
          </a>
        );
      case 'failed':
        return <Text>{I18n.t('Failed')}</Text>;
      default:
        return <Text>{I18n.t('In progress')}</Text>;
    }
  }

  render = () => (
    <span>
      <Modal
        as="form"
        onSubmit={preventDefault(this.onSubmit)}
        open={this.state.open}
        onDismiss={this.close}
        size="medium"
        label={I18n.t('Create DSR Request')}
      >
        <Modal.Body>
          <Flex direction="column">
            <Flex.Item padding="small medium">
              <TextInput
                key="request_name"
                renderLabel={
                  <div style={{textAlign: "left"}}>
                    {I18n.t('DSR Request Name')} <Text color="danger"> *</Text>
                  </div>
                }
                label={I18n.t('DSR Request Name')}
                data-testid={I18n.t('DSR Request Name')}
                value={get(this.state.data, 'request_name')?.toString() ?? ''}
                onChange={e => this.onChange('request_name', e.target.value)}
                isRequired={true}
                layout="inline"
                messages={(this.state.errors.request_name || [])
                  .map(errMsg => ({type: 'error', text: errMsg}))
                  .concat({
                    type: 'hint',
                    text: I18n.t('This is a a common tracking ID for DSR requests.'),
                  })
                  .filter(Boolean)}
              />
            </Flex.Item>
            <Flex.Item as="div" padding="0 medium">
              <RadioInputGroup
                name="request_output"
                description="Output Format"
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
          <Button type="submit" color="primary">
            {I18n.t('Create')}
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
