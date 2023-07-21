/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import PropTypes from 'prop-types'
import Lti2ReregistrationUpdateModal from './Lti2ReregistrationUpdateModal'

const I18n = useI18nScope('external_tools')

export default class ManageUpdateExternalToolButton extends React.Component {
  static propTypes = {
    tool: PropTypes.object.isRequired,
    returnFocus: PropTypes.func.isRequired,
  }

  openReregModal = e => {
    this.refs.reregModal.openModal(e)
  }

  render() {
    const updateAriaLabel = I18n.t('Manage update for %{toolName}', {
      toolName: this.props.tool.name,
    })

    const cssClassName = this.props.tool.has_update ? '' : ' hide'
    return (
      <li role="presentation" className={`EditExternalToolButton ui-menu-item${cssClassName}`}>
        {/* TODO: use InstUI button */}
        {/* eslint-disable-next-line jsx-a11y/anchor-is-valid */}
        <a
          href="#"
          ref="updateButton"
          tabIndex="-1"
          role="menuitem"
          aria-label={updateAriaLabel}
          className="icon-upload"
          onClick={this.openReregModal}
        >
          {I18n.t('Manage Update')}
        </a>
        <Lti2ReregistrationUpdateModal
          ref="reregModal"
          tool={this.props.tool}
          returnFocus={this.props.returnFocus}
        />
      </li>
    )
  }
}
