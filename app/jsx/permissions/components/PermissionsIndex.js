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
import React, { Component } from 'react'
import { func, bool, number, arrayOf, string } from 'prop-types'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'

import Spinner from '@instructure/ui-core/lib/components/Spinner'
import Heading from '@instructure/ui-core/lib/components/Heading'
import Text from '@instructure/ui-core/lib/components/Text'

import select from '../../shared/select'
import actions from '../actions'

export default class PermissionsIndex extends Component {
  static propTypes = {
    permissions: arrayOf(string),
    isLoadingPermissions: bool.isRequired,
    hasLoadedPermissions: bool.isRequired,
    getPermissions: func.isRequired,
    contextId: number.isRequired
  }

  static defaultProps = {
    permissions: []
  }

  componentDidMount () {
    if (!this.props.hasLoadedPermissions) {
      this.props.getPermissions(this.props.contextId)
    }
  }

  renderSpinner () {
    return this.props.isLoadingPermissions ? (
      <div style={{textAlign: 'center'}}>
        <Spinner size="small" title={I18n.t('Loading Permissions')} />
        <Text size="small" as="p">
          {I18n.t('Loading Permissions')}
        </Text>
      </div>
    ) : null
  }

  renderPermissions () {
    if (this.props.hasLoadedPermissions) {
      const permissionNames = this.props.permissions.map(name => ((
        <span key={`permission-${name}`}> {name} </span>
      )))
      return (
        <Text as="p">
          {permissionNames}
        </Text>
      )
    } else {
      return null
    }
  }

  render () {
    return (
      <div className="permissions-v2__wrapper">
        <Heading>{I18n.t('Permissions V2 Page')}</Heading>
        {this.renderSpinner()}
        {this.renderPermissions()}
      </div>
    )
  }
}

function mapStateToProps(state) {
  return {
    contextId: state.contextId,
    isLoadingPermissions: state.isLoadingPermissions,
    hasLoadedPermissions: state.hasLoadedPermissions,
    permissions: state.permissions
  }
}

const connectActions = dispatch => bindActionCreators(select(actions, [ 'getPermissions' ]), dispatch)
export const ConnectedPermissionsIndex = connect(mapStateToProps, connectActions)(PermissionsIndex)
