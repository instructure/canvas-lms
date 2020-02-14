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
import 'compiled/jquery.rails_flash_notifications'

import {Button, IconButton} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {IconExpandSolid, IconExpandStartSolid} from '@instructure/ui-icons'

import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-elements'
import {Tooltip} from '@instructure/ui-overlays'
import {View} from '@instructure/ui-layout'

import actions from '../actions'
import {ConnectedPermissionButton} from './PermissionButton'
import propTypes, {ENABLED_FOR_NONE} from '../propTypes'

export default class PermissionsTable extends Component {
  static propTypes = {
    roles: arrayOf(propTypes.role).isRequired,
    modifyPermissions: func.isRequired,
    permissions: arrayOf(propTypes.permission).isRequired,
    setAndOpenRoleTray: func.isRequired,
    setAndOpenPermissionTray: func.isRequired
  }

  state = {
    expanded: {}
  }

  // just a heads up: these likely break in RTL. the best thing would be to
  // change the css so you don't manually have to scroll the table in JS but
  // if you do have to do this in JS, you need to use something like
  // 'normalize-scroll-left' from npm (grep for where we use it in the gradebook)
  // so that it works cross browser in RTL
  fixScroll = e => {
    if (!this.contentWrapper) return
    const sidebarWidth = 300
    const leftScroll = this.contentWrapper.scrollLeft
    const leftOffset = e.target.closest('td,th').offsetLeft
    if (leftOffset - sidebarWidth < leftScroll) {
      const newScroll = Math.max(0, leftScroll - sidebarWidth)
      this.contentWrapper.scrollLeft = newScroll
    }
  }

  toggleExpanded(permission) {
    this.setState(prevState => {
      const expanded = {...prevState.expanded}
      expanded[permission.permission_name] = !expanded[permission.permission_name]

      const count = permission.granular_permissions.length
      if (expanded[permission.permission_name]) {
        $.screenReaderFlashMessage(I18n.t('%{count} rows added', {count}))
      } else {
        $.screenReaderFlashMessage(I18n.t('%{count} rows removed', {count}))
      }

      return {expanded}
    })
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
        <th scope="col" className="ic-permissions__corner-stone">
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
                <Tooltip tip={role.label}>
                  <Button
                    id={`role_${role.id}`}
                    variant="link"
                    onClick={() => this.openRoleTray(role)}
                    onFocus={this.fixScroll}
                    size="small"
                    theme={{smallPadding: '0', smallHeight: 'normal'}}
                  >
                    {role.label}
                  </Button>
                </Tooltip>
              </div>
            </div>
          </th>
        ))}
      </tr>
    )
  }

  renderLeftHeader(perm) {
    const expanded = this.state.expanded[perm.permission_name]

    return (
      <th scope="row" className="ic-permissions__main-left-header" aria-label={perm.label}>
        <div className="ic-permissions__left-header__col-wrapper">
          <div className="ic-permissions__header-content">
            {perm.granular_permissions && (
              <IconButton
                data-testid={`expand_${perm.permission_name}`}
                onClick={() => this.toggleExpanded(perm)}
                screenReaderLabel={
                  expanded
                    ? I18n.t('Expand %{permission}', {permission: perm.label})
                    : I18n.t('Shrink %{permission}', {permission: perm.label})
                }
              >
                {expanded ? <IconExpandSolid /> : <IconExpandStartSolid />}
              </IconButton>
            )}
            <View maxWidth="17rem" as="div" padding="small">
              <Button
                variant="link"
                onClick={() => this.props.setAndOpenPermissionTray(perm)}
                id={`permission_${perm.permission_name}`}
                theme={{mediumPadding: '0', mediumHeight: 'normal'}}
                fluidWidth
              >
                {perm.label}
              </Button>
            </View>
          </div>
        </div>
      </th>
    )
  }

  renderExapndedRows(perm) {
    return perm.granular_permissions.map(permission => (
      <tr key={permission.label}>
        <th scope="row" className="ic-permissions__left-header__expanded">
          <div className="ic-permissions__left-header__col-wrapper">
            <div className="ic-permissions__header-content">
              <View maxWidth="17rem" as="div" padding="small">
                <Button
                  variant="link"
                  onClick={() => this.props.setAndOpenPermissionTray(perm)}
                  id={`permission_${permission.permission_name}`}
                  theme={{mediumPadding: '0', mediumHeight: 'normal'}}
                  fluidWidth
                >
                  {permission.label}
                </Button>
              </View>
            </div>
          </div>
        </th>
        {this.props.roles.map(role => (
          <td key={role.id}>
            <div className="ic-permissions__cell-content">
              <Checkbox
                checked={role.permissions[permission.permission_name].enabled !== ENABLED_FOR_NONE}
                disabled={role.permissions[permission.permission_name].readonly}
                label={<ScreenReaderContent>{permission.label}</ScreenReaderContent>}
                onChange={() =>
                  this.props.modifyPermissions({
                    enabled: !role.permissions[permission.permission_name].enabled,
                    explicit: true,
                    id: role.id,
                    name: permission.permission_name
                  })
                }
                value={permission.label}
              />
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
                      onFocus={this.fixScroll}
                    />
                  </div>
                </td>
              ))}
            </tr>
            {this.state.expanded[perm.permission_name] && this.renderExapndedRows(perm)}
          </tbody>
        ))}
      </table>
    )
  }

  render() {
    return (
      <div className="ic-permissions__table-container" ref={c => (this.contentWrapper = c)}>
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
  modifyPermissions: actions.modifyPermissions,
  setAndOpenRoleTray: actions.setAndOpenRoleTray,
  setAndOpenPermissionTray: actions.setAndOpenPermissionTray
}

export const ConnectedPermissionsTable = connect(
  mapStateToProps,
  mapDispatchToProps
)(PermissionsTable)
