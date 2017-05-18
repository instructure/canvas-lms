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

import I18n from 'i18n!external_tools'
import React from 'react'
import PropTypes from 'prop-types'
import htmlEscape from 'str/htmlEscape'

export default React.createClass({
    displayName: 'Lti2Permissions',

    propTypes: {
      tool: PropTypes.object.isRequired,
      handleCancelLti2: PropTypes.func.isRequired,
      handleActivateLti2: PropTypes.func.isRequired
    },

    render() {
      var p1 = I18n.t(
        '*name* has been successfully installed but has not yet been enabled.',
        { wrappers: [
          '<strong>' + htmlEscape(this.props.tool.name) + '</strong>'
        ]}
      );
      return (
        <div className="Lti2Permissions">
          <div className="ReactModal__Body">
            <p dangerouslySetInnerHTML={{ __html: p1 }}></p>
            <p>{I18n.t('Would you like to enable this app?')}</p>
          </div>
          <div className="ReactModal__Footer">
            <div className="ReactModal__Footer-Actions">
              <button type="button" className="Button" onClick={this.props.handleCancelLti2}>{I18n.t("Delete")}</button>
              <button type="button" className="Button Button--primary" onClick={this.props.handleActivateLti2}>{I18n.t('Enable')}</button>
            </div>
          </div>
        </div>
      )
    }
  });
