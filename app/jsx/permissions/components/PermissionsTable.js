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

import I18n from 'i18n!permissions'
import React, {Component} from 'react'
import {arrayOf, func} from 'prop-types'
import {connect} from 'react-redux'
import $ from 'jquery'
// For screenreaderFlashMessageExclusive  Maybe there's a better way
import 'compiled/jquery.rails_flash_notifications' // eslint-disable-line

import Link from '@instructure/ui-elements/lib/components/Link'
import Text from '@instructure/ui-elements/lib/components/Text'
import Tooltip from '@instructure/ui-overlays/lib/components/Tooltip'
import View from '@instructure/ui-layout/lib/components/View'

import actions from '../actions'
import {ConnectedPermissionButton} from './PermissionButton'
import propTypes from '../propTypes'

export default class PermissionsTable extends Component {
  static propTypes = {
    roles: arrayOf(propTypes.role).isRequired,
    permissions: arrayOf(propTypes.permission).isRequired,
    setAndOpenRoleTray: func.isRequired,
    setAndOpenPermissionTray: func.isRequired
  }

  state = {
    expanded: {}
  }

  fixScroll = (leftOffset, leftScroll) => {
    const sidebarWidth = 300
    if (leftOffset - sidebarWidth < leftScroll) {
      const newScroll = Math.max(0, leftScroll - sidebarWidth)
      this.contentWrapper.scrollLeft = newScroll
    }
  }

  fixScrollButton = e => {
    const leftOffset = e.target.offsetParent.offsetLeft
    const leftScroll = this.contentWrapper.scrollLeft
    this.fixScroll(leftOffset, leftScroll)
  }

  fixScrollHeader = e => {
    const leftOffset = e.target.offsetParent.offsetParent.offsetLeft
    const leftScroll = this.contentWrapper.scrollLeft
    this.fixScroll(leftOffset, leftScroll)
  }

  toggleExpanded(id) {
    return () => {
      const expanded = Object.assign(this.state.expanded)
      expanded[id] = !expanded[id]
      if (expanded[id]) {
        $.screenReaderFlashMessage(I18n.t('4 rows added'))
      } else {
        $.screenReaderFlashMessage(I18n.t('4 rows removed'))
      }
      this.setState({expanded})
    }
  }

  openRoleTray(role) {
    // TODO ideally (according to kendal) we should have this close the current
    //      tray (an animation) before loading the new tray. I was hoping that
    //      calling hideTrays() here would be enough to do that, but it is
    //      alas not the case. The `Admin > People` page has an example of
    //      how this should look, so I should check there for inspiration.
    this.props.setAndOpenRoleTray(role)
  }

  renderTopHeader() {
    return (
      <tr className="ic-permissions__top-header">
        <th className="ic-permissions__corner-stone">
          <span className="ic-permission-corner-text">
            <Text weight="bold" size="small">
              {I18n.t('Permissions')}
            </Text>
          </span>
        </th>
        {this.props.roles.map(role => (
          <th
            key={role.id}
            scope="col"
            aria-label={role.label}
            className="ic-permissions__top-header__col-wrapper-th"
          >
            <div className="ic-permissions__top-header__col-wrapper">
              <div
                className="ic-permissions__header-content ic-permissions__header-content-col"
                id={`ic-permissions__role-header-for-role-${role.id}`}
              >
                <Tooltip
                  as={Link}
                  tip={role.label}
                  onClick={() => this.openRoleTray(role)}
                  id={`role_${role.id}`}
                  onFocus={this.fixScrollHeader}
                >
                  <div
                    style={{
                      width: '140px',
                      whiteSpace: 'nowrap',
                      overflow: 'hidden',
                      textOverflow: 'ellipsis'
                    }}
                  >
                    <Text size="small">{role.label}</Text>
                  </div>
                </Tooltip>
              </div>
            </div>
          </th>
        ))}
      </tr>
    )
  }

  renderLeftHeader(perm) {
    return (
      <th scope="row" className="ic-permissions__main-left-header" aria-label={perm.label}>
        <div className="ic-permissions__left-header__col-wrapper">
          <div className="ic-permissions__header-content">
            {/*
            This button is for the expanding of permissions.  When we get more granular
            we will uncomment this to allow that functionality to still stand
            <button onClick={this.toggleExpanded(perm.permission_name)}>
              {this.state.expanded[perm.permission_name] ? 'v' : '>'}
            </button>
            */}
            <View margin="small">
              {/* eslint-disable-next-line */}
              <Link
                as="button"
                onClick={() => this.props.setAndOpenPermissionTray(perm)}
                id={`permission_${perm.permission_name}`}
              >
                <Text>{perm.label}</Text>
              </Link>
            </View>
          </div>
        </div>
      </th>
    )
  }

  renderExapndedRows() {
    const rowTypes = {
      create: I18n.t('create'),
      read: I18n.t('read'),
      update: I18n.t('update'),
      delete: I18n.t('delete')
    }

    return Object.keys(rowTypes).map(rowType => (
      <tr key={rowType}>
        <th scope="row" className="ic-permissions__left-header__expanded">
          <div className="ic-permissions__left-header__col-wrapper">
            <div className="ic-permissions__header-content">
              <Text>{rowTypes[rowType]}</Text>
            </div>
          </div>
        </th>
        {this.props.roles.map(role => (
          <td key={role.id}>
            <div className="ic-permissions__cell-content">
              <input type="checkbox" aria-label="toggle sub-permission" />
            </div>
          </td>
        ))}
      </tr>
    ))
  }

  renderTable() {
    return (
      <table className="ic-permissions__table">
        <tbody>{this.renderTopHeader()}</tbody>
        {this.props.permissions.map(perm => (
          <tbody key={perm.permission_name}>
            <tr>
              {this.renderLeftHeader(perm)}
              {this.props.roles.map(role => (
                <td key={role.id} id={`${perm.permission_name}_role_${role.id}`}>
                  <div className="ic-permissions__cell-content">
                    <ConnectedPermissionButton
                      permission={role.permissions[perm.permission_name]}
                      permissionName={perm.permission_name}
                      permissionLabel={perm.label}
                      roleId={role.id}
                      roleLabel={role.label}
                      inTray={false}
                      onFocus={this.fixScrollButton}
                    />
                  </div>
                </td>
              ))}
            </tr>
            {this.state.expanded[perm.permission_name] && this.renderExapndedRows()}
          </tbody>
        ))}
      </table>
    )
  }

  render() {
    return (
      <div
        className="ic-permissions__table-container"
        ref={c => {
          this.contentWrapper = c
        }}
      >
        {this.renderTable()}
      </div>
    )
  }
}

function mapStateToProps(state, ownProps) {
  const stateProps = {
    roles: state.roles.filter(r => r.displayed),
    permissions: state.permissions.filter(p => p.displayed)
  }
  return {...ownProps, ...stateProps}
}

const mapDispatchToProps = {
  setAndOpenRoleTray: actions.setAndOpenRoleTray,
  setAndOpenPermissionTray: actions.setAndOpenPermissionTray
}

export const ConnectedPermissionsTable = connect(
  mapStateToProps,
  mapDispatchToProps
)(PermissionsTable)
