/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import I18n from 'i18n!react_developer_keys'
import PropTypes from 'prop-types'
import React from 'react'

import Button from '@instructure/ui-buttons/lib/components/Button'
import {ModalFooter} from '@instructure/ui-overlays/lib/components/Modal'

export default class LtiKeyFooter extends React.Component {
  onAdvanceToCustomization = () => {
    this.props.onAdvanceToCustomization()
  }

  onSave = e => {
    this.props.dispatch(this.props.ltiKeysSetCustomizing(false))
    this.props.onSaveClick(e)
  }

  onCancel = e => {
    this.props.dispatch(this.props.ltiKeysSetCustomizing(false))
    this.props.onCancelClick(e)
  }

  nextOrSaveButton() {
    const {customizing} = this.props
    const clickHandler = customizing ? this.onSave : this.onAdvanceToCustomization
    const buttonText = customizing ? I18n.t('Save Customizations') : I18n.t('Save and Customize')

    return (
      <Button onClick={clickHandler} variant="primary" disabled={this.props.disable}>
        {buttonText}
      </Button>
    )
  }

  render() {
    return (
      <ModalFooter>
        <Button onClick={this.onCancel} margin="0 small 0 0">{I18n.t('Cancel')}</Button>
        {this.nextOrSaveButton()}
      </ModalFooter>
    )
  }
}

LtiKeyFooter.propTypes = {
  dispatch: PropTypes.func.isRequired,
  ltiKeysSetCustomizing: PropTypes.func.isRequired,
  onCancelClick: PropTypes.func.isRequired,
  onSaveClick: PropTypes.func.isRequired,
  onAdvanceToCustomization: PropTypes.func.isRequired,
  customizing: PropTypes.bool.isRequired,
  disable: PropTypes.bool
}
