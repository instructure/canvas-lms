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

import Modal from './components/InstuiModal'
import $ from 'jquery'
import React from 'react'
import {bool} from 'prop-types'
import I18n from 'i18n!terms_of_service_modal'
import RichContentEditor from './rce/RichContentEditor'
import {defaultFetchOptions} from '@instructure/js-utils'

const termsOfServiceText = I18n.t('Acceptable Use Policy')

class TermsOfServiceCustomContents extends React.Component {
  state = {
    TERMS_OF_SERVICE_CUSTOM_CONTENT: undefined
  }

  async componentDidMount() {
    const url = '/api/v1/terms_of_service_custom_content'
    const TERMS_OF_SERVICE_CUSTOM_CONTENT = await (await fetch(url, defaultFetchOptions)).text()

    this.setState({TERMS_OF_SERVICE_CUSTOM_CONTENT})
  }

  render() {
    return this.state.TERMS_OF_SERVICE_CUSTOM_CONTENT ? (
      <div dangerouslySetInnerHTML={{__html: this.state.TERMS_OF_SERVICE_CUSTOM_CONTENT}} />
    ) : (
      <span>{I18n.t('Loading...')}</span>
    )
  }
}

export default class TermsOfServiceModal extends React.Component {
  static propTypes = {
    preview: bool
  }

  static defaultProps = {
    preview: false
  }

  state = {
    open: false
  }

  handleCloseModal = () => {
    this.link.focus()
    this.setState({open: false})
  }

  handleLinkClick = () => {
    this.setState(state => {
      const $rce_container = $('#custom_tos_rce_container')
      let TERMS_OF_SERVICE_CUSTOM_CONTENT
      if ($rce_container.length > 0) {
        const $textarea = $rce_container.find('textarea')
        TERMS_OF_SERVICE_CUSTOM_CONTENT = RichContentEditor.callOnRCE($textarea, 'get_code')
      }

      return {
        open: !state.open,
        TERMS_OF_SERVICE_CUSTOM_CONTENT
      }
    })
  }

  render() {
    return (
      <span id="terms_of_service_modal">
        <a
          className="terms_link"
          href="#"
          ref={c => {
            this.link = c
          }}
          onClick={this.handleLinkClick}
        >
          {this.props.preview ? I18n.t('Preview') : termsOfServiceText}
        </a>
        {this.state.open && (
          <Modal
            open={this.state.open}
            onDismiss={this.handleCloseModal}
            size="fullscreen"
            label={termsOfServiceText}
          >
            <Modal.Body>
              {this.props.preview ? (
                <div
                  dangerouslySetInnerHTML={{__html: this.state.TERMS_OF_SERVICE_CUSTOM_CONTENT}}
                />
              ) : (
                <TermsOfServiceCustomContents />
              )}
            </Modal.Body>
          </Modal>
        )}
      </span>
    )
  }
}
