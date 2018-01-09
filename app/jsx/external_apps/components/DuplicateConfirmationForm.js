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

import React from 'react'
import PropTypes from 'prop-types'
import Button from 'instructure-ui/lib/components/Button'
import I18n from 'i18n!external_tools'


export default class DuplicateConfirmationForm extends React.Component {
  forceSaveTool = () => {
    const data = this.props.toolData;
    data.verifyUniqueness = undefined;
    this.props.store.save(this.props.configurationType, data, this.props.onSuccess, this.props.onError);
  }

  render () {
    return (
      <div id="duplicate-confirmation-form">
        <div className="ReactModal__Body">
          <p>
            {I18n.t('This tool has already been installed in this context. Would you like to install it anyway?')}
          </p>
        </div>
        <div className="ReactModal__Footer">
          <div className="ReactModal__Footer-Actions">
            <Button id='cancel-install' variant="primary" margin="0 x-small 0 0" onClick={this.props.onCancel} >
              {I18n.t('No, Cancel Installation')}
            </Button>
            <Button id='continue-install' onClick={this.forceSaveTool}>
              {I18n.t('Yes, Install Tool')}
            </Button>
          </div>
        </div>
      </div>
    );
  }
}

DuplicateConfirmationForm.propTypes = {
  onCancel: PropTypes.func.isRequired,
  onSuccess: PropTypes.func.isRequired,
  onError: PropTypes.func.isRequired,
  toolData: PropTypes.object.isRequired,
  configurationType: PropTypes.string.isRequired,
  store: PropTypes.object.isRequired
}