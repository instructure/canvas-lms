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
import IconModuleSolid from '@instructure/ui-icons/lib/Solid/IconModule'
import IconUploadLine from '@instructure/ui-icons/lib/Line/IconUpload'
import I18n from 'i18n!modules_home_page'

export default class ModulesHomePage extends React.Component {
  static propTypes = {
    onCreateButtonClick: PropTypes.func
  }

  static defaultProps = {
    onCreateButtonClick: () => {}
  }

  render () {
    const importURL = window.ENV.CONTEXT_URL_ROOT + '/content_migrations'
    return (
      <ul className="ic-EmptyStateList">
        <li className="ic-EmptyStateList__Item">
          <div className="ic-EmptyStateList__BillboardWrapper">
            <button
              type="button"
              className="ic-EmptyStateButton"
              onClick={this.props.onCreateButtonClick}
            >
              <IconModuleSolid className="ic-EmptyStateButton__SVG" />
              <span className="ic-EmptyStateButton__Text">
                {I18n.t('Create a new Module')}
              </span>
            </button>
          </div>
        </li>
        <li className="ic-EmptyStateList__Item">
          <div className="ic-EmptyStateList__BillboardWrapper">
            <a href={importURL} className="ic-EmptyStateButton">
              <IconUploadLine className="ic-EmptyStateButton__SVG" />
              <span className="ic-EmptyStateButton__Text">
                {I18n.t('Add existing content')}
              </span>
            </a>
          </div>
        </li>
      </ul>
    )
  }
}
