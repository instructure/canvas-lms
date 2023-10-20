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

import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import PropTypes from 'prop-types'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import ConfigOptionField from './ConfigOptionField'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('external_tools')

export default class ManageAppListButton extends React.Component {
  static propTypes = {
    onUpdateAccessToken: PropTypes.func.isRequired,
    extAppStore: PropTypes.object,
  }

  state = {
    modalIsOpen: false,
    accessToken: undefined,
  }

  componentDidMount() {
    this.setState({
      originalAccessToken: this.maskedAccessToken(ENV.MASKED_APP_CENTER_ACCESS_TOKEN),
      accessToken: this.maskedAccessToken(ENV.MASKED_APP_CENTER_ACCESS_TOKEN),
    })
  }

  closeModal = cb => {
    if (typeof cb === 'function') {
      this.setState({modalIsOpen: false}, cb)
    } else {
      this.setState({modalIsOpen: false})
    }
  }

  openModal = () => {
    this.setState(state => ({modalIsOpen: true, accessToken: state.originalAccessToken}))
  }

  successHandler = () => {
    this.setState(state => ({
      originalAccessToken: this.maskedAccessToken(state.accessToken.substring(0, 5)),
    }))
    if (typeof this.props.onUpdateAccessToken === 'function') {
      this.props.onUpdateAccessToken()
    }
  }

  errorHandler = () => {
    $.flashError(I18n.t('We were unable to add the access token.'))
  }

  handleChange = e => {
    this.setState({accessToken: e.target.value})
  }

  handleSubmit = () => {
    this.closeModal(() => {
      if (this.state.accessToken !== this.state.originalAccessToken) {
        this.props.extAppStore.updateAccessToken(
          ENV.CONTEXT_BASE_URL,
          this.state.accessToken,
          this.successHandler,
          this.errorHandler
        )
      }
    })
  }

  maskedAccessToken = token => {
    if (typeof token === 'string') {
      return `${token}...`
    }
  }

  render() {
    // xsslint safeString.identifier allowListLink
    const allowListLink = I18n.t('#community.admin_app_center_allowlist')
    return (
      <View>
        <Button margin="none x-small" onClick={this.openModal}>
          {I18n.t('Manage App List')}
        </Button>
        <Modal
          open={this.state.modalIsOpen}
          onDismiss={this.closeModal}
          label={I18n.t('Manage App List')}
        >
          <Modal.Body>
            <p
              dangerouslySetInnerHTML={{
                __html: I18n.t(
                  `Enter the access token for your organization from \
                    *eduappcenter.com*. Once applied, only apps your organization has approved in the \
                    EduAppCenter will be listed on the External Apps page. \
                    Learn how to **generate an access token**.`,
                  {
                    wrappers: [
                      '<a href="https://www.eduappcenter.com">$1</a>',
                      '<a href="' + allowListLink + '">$1</a>',
                    ],
                  }
                ),
              }}
            />
            <form>
              <ConfigOptionField
                name="manage_app_list_token"
                type="text"
                description={I18n.t('Access Token')}
                value={this.state.accessToken}
                handleChange={this.handleChange}
              />
            </form>
          </Modal.Body>
          <Modal.Footer>
            <Button onClick={this.closeModal}>{I18n.t('Cancel')}</Button>
            &nbsp;
            <Button onClick={this.handleSubmit}>{I18n.t('Save')}</Button>
          </Modal.Footer>
        </Modal>
      </View>
    )
  }
}
