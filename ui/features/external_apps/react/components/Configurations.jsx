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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import PropTypes from 'prop-types'
import Header from './Header'
import ExternalToolsTable from './ExternalToolsTable'
import AddExternalToolButton from './AddExternalToolButton'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import page from 'page'

const I18n = useI18nScope('external_tools')

export default class Configurations extends React.Component {
  static propTypes = {
    env: PropTypes.object.isRequired,
  }

  // legacy all-encompassing permission
  canAddEdit = () => this.props.env.PERMISSIONS && this.props.env.PERMISSIONS.create_tool_manually

  canAdd = () => this.props.env.PERMISSIONS && this.props.env.PERMISSIONS.add_tool_manually

  canEdit = () => this.props.env.PERMISSIONS && this.props.env.PERMISSIONS.edit_tool_manually

  canDelete = () => this.props.env.PERMISSIONS && this.props.env.PERMISSIONS.delete_tool_manually

  focusHeader = () => {
    this.headerRef.focus()
  }

  setHeaderRef = node => {
    this.headerRef = node
  }

  render() {
    const appCenterLink = () => {
      if (!this.props.env.APP_CENTER.enabled) {
        return ''
      }
      const baseUrl = page.base()
      return (
        <View>
          <Button margin="x-small" href={baseUrl}>
            {I18n.t('View App Center')}
          </Button>
        </View>
      )
    }

    return (
      <div className="Configurations">
        <Header ref={this.setHeaderRef}>
          {(this.canAddEdit() || this.canAdd()) && <AddExternalToolButton />}
          {appCenterLink()}
        </Header>
        <ExternalToolsTable
          canAdd={this.canAdd()}
          canEdit={this.canEdit()}
          canDelete={this.canDelete()}
          canAddEdit={this.canAddEdit()}
          setFocusAbove={this.focusHeader}
        />
      </div>
    )
  }
}
