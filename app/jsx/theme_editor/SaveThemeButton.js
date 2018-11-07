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

import I18n from 'i18n!theme_editor'
import React, {Component} from 'react'
import PropTypes from 'prop-types'
import $ from 'jquery'
import customTypes from './PropTypes'
import Modal, {ModalBody, ModalFooter} from 'jsx/shared/components/InstuiModal'

export default class SaveThemeButton extends Component {
  static propTypes = {
    accountID: PropTypes.string.isRequired,
    brandConfigMd5: customTypes.md5,
    sharedBrandConfigBeingEdited: customTypes.sharedBrandConfig.isRequired,
    onSave: PropTypes.func.isRequired
  }

  constructor() {
    super()
    this.state = {
      newThemeName: '',
      modalIsOpen: false
    }
  }

  save = () => {
    const shouldUpdate = !!(
      this.props.sharedBrandConfigBeingEdited && this.props.sharedBrandConfigBeingEdited.id
    )

    const params = {brand_config_md5: this.props.brandConfigMd5}

    let url, method
    if (shouldUpdate) {
      url = `/api/v1/accounts/${this.props.accountID}/shared_brand_configs/${
        this.props.sharedBrandConfigBeingEdited.id
      }`
      method = 'PUT'
    } else {
      if (!this.state.newThemeName) {
        this.setState({modalIsOpen: true})
        return
      }
      params.name = this.state.newThemeName
      url = `/api/v1/accounts/${this.props.accountID}/shared_brand_configs`
      method = 'POST'
    }

    return $.ajaxJSON(url, method, {shared_brand_config: params}, updatedSharedConfig => {
      this.setState({modalIsOpen: false})
      this.props.onSave(updatedSharedConfig)
    })
  }

  render() {
    let disable = false
    let disableMessage
    if (this.props.userNeedsToPreviewFirst) {
      disable = true
      disableMessage = I18n.t('You need to "Preview Changes" before saving')
    } else if (
      this.props.sharedBrandConfigBeingEdited &&
      this.props.sharedBrandConfigBeingEdited.brand_config_md5 === this.props.brandConfigMd5
    ) {
      disable = true
      disableMessage = I18n.t('There are no unsaved changes')
    } else if (!this.props.brandConfigMd5) {
      disable = true
    }

    return (
      <div className="pull-left" data-tooltip="left" title={disableMessage}>
        <button
          type="button"
          className="Button Button--primary"
          disabled={disable}
          onClick={this.save}
        >
          {I18n.t('Save theme')}
        </button>
        <Modal
          size="small"
          label={I18n.t('Save Theme')}
          open={this.state.modalIsOpen}
          onDismiss={() => this.setState({modalIsOpen: false})}
        >
          <ModalBody>
            <div className="ic-Form-control">
              <label htmlFor="new_theme_theme_name" className="ic-Label">
                {I18n.t('Theme Name')}
              </label>
              <input
                type="text"
                id="new_theme_theme_name"
                className="ic-Input"
                placeholder={I18n.t('Pick a name to save this theme as')}
                onChange={e => this.setState({newThemeName: e.target.value})}
              />
            </div>
          </ModalBody>
          <ModalFooter>
            <button
              type="button"
              className="Button"
              onClick={() => this.setState({modalIsOpen: false})}
            >
              {I18n.t('Cancel')}
            </button>
            &nbsp;
            <button
              type="button"
              onClick={this.save}
              disabled={!this.state.newThemeName}
              className="Button Button--primary"
            >
              {I18n.t('Save theme')}
            </button>
          </ModalFooter>
        </Modal>
      </div>
    )
  }
}
