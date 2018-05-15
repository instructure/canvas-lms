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

import I18n from 'i18n!permissions_v2'
import React, {Component} from 'react'
import {number, arrayOf} from 'prop-types'
import {connect} from 'react-redux'
import {bindActionCreators} from 'redux'

import TabList, {TabPanel} from '@instructure/ui-core/lib/components/TabList'

import select from '../../shared/select'
import actions from '../actions'
import propTypes from '../propTypes'

import PermissionsTable from './PermissionsTable'

export default class PermissionsIndex extends Component {
  static propTypes = {
    contextId: number.isRequired,
    accountPermissions: arrayOf(propTypes.permission).isRequired,
    coursePermissions: arrayOf(propTypes.permission).isRequired,
    accountRoles: arrayOf(propTypes.role).isRequired,
    courseRoles: arrayOf(propTypes.role).isRequired
  }

  render() {
    return (
      <div className="permissions-v2__wrapper">
        <TabList>
          <TabPanel title={I18n.t('Course Roles')}>
            <PermissionsTable
              roles={this.props.courseRoles}
              permissions={this.props.coursePermissions}
            />
          </TabPanel>
          <TabPanel title={I18n.t('Account Roles')}>
            <PermissionsTable
              roles={this.props.accountRoles}
              permissions={this.props.accountPermissions}
            />
          </TabPanel>
        </TabList>
      </div>
    )
  }
}

function mapStateToProps(state) {
  return {
    contextId: state.contextId,
    accountPermissions: state.accountPermissions,
    coursePermissions: state.coursePermissions,
    accountRoles: state.accountRoles,
    courseRoles: state.courseRoles
  }
}

const connectActions = dispatch => bindActionCreators(select(actions, ['getPermissions']), dispatch)
export const ConnectedPermissionsIndex = connect(mapStateToProps, connectActions)(PermissionsIndex)
