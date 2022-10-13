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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {Component, Fragment} from 'react'
import {arrayOf, func} from 'prop-types'
import {connect} from 'react-redux'
import $ from 'jquery'
import {maxBy} from 'lodash'
// For screenreaderFlashMessageExclusive  Maybe there's a better way
import '@canvas/rails-flash-notifications'

import {IconButton} from '@instructure/ui-buttons'
import {Link} from '@instructure/ui-link'
import {IconArrowOpenEndSolid, IconArrowOpenDownSolid} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import actions from '../actions'
import {GROUP_PERMISSION_DESCRIPTIONS} from '../templates/groupPermissionDescriptions'
import {ConnectedPermissionButton} from './PermissionButton'
import {ConnectedGranularCheckbox} from './GranularCheckbox'
import propTypes from '@canvas/permissions/react/propTypes'

const I18n = useI18nScope('permissions')

const GRANULAR_PERMISSION_TAG = 'ic-permissions__grp-tag'

export default class PermissionsTable extends Component {
  static propTypes = {
    roles: arrayOf(propTypes.role).isRequired,
    permissions: arrayOf(propTypes.permission).isRequired,
    setAndOpenRoleTray: func.isRequired,
    setAndOpenPermissionTray: func.isRequired,
  }

  constructor(props) {
    super(props)
    this.state = {
      expanded: {},
    }
    this.justExpanded = null
    this.tableRef = React.createRef()
  }

  componentDidUpdate() {
    if (this.justExpanded) {
      this.fixVerticalScroll()
      this.justExpanded = null
    }
  }

  // just a heads up: these likely break in RTL. the best thing would be to
  // change the css so you don't manually have to scroll the table in JS but
  // if you do have to do this in JS, you need to use something like
  // 'normalize-scroll-left' from npm (grep for where we use it in the gradebook)
  // so that it works cross browser in RTL
  fixHorizontalScroll = e => {
    if (!this.contentWrapper) return
    const sidebarWidth = 300
    const leftScroll = this.contentWrapper.scrollLeft
    const leftOffset = e.target.closest('td,th').offsetLeft
    if (leftOffset - sidebarWidth < leftScroll) {
      const newScroll = Math.max(0, leftScroll - sidebarWidth)
      this.contentWrapper.scrollLeft = newScroll
    }
  }

  fixVerticalScroll = () => {
    // All rows corrresponding to granular permissions will have a special
    // class attached to them. Find the ones corresponding to the expand-o
    // operation that JUST happened.
    if (!this.tableRef.current) return
    const newGranulars = this.tableRef.current.querySelectorAll(
      `tr.${GRANULAR_PERMISSION_TAG}-${this.justExpanded}`
    )
    if (newGranulars.length === 0) return

    // We now have the rows that were added as a result of expanding the group.
    // Find the bottom-most one of those, and then if it is below the visible
    // region of the scrolling div, scroll it into view.
    // Note that we don't have to worry about scrolling in the other direction,
    // because rows can only get added BELOW the group, so they can never be
    // off the top of the scroll region when first created
    const scrollToMe = maxBy(Array.from(newGranulars), 'offsetTop')
    const scrollArea = scrollToMe.closest('div.ic-permissions__table-container')
    const myBottom = scrollToMe.offsetTop + scrollToMe.offsetHeight
    const scrollAreaBottom = scrollArea.scrollTop + scrollArea.clientHeight
    if (myBottom > scrollAreaBottom)
      scrollArea.scrollBy({
        top: myBottom - scrollAreaBottom,
        left: 0,
        behavior: 'smooth',
      })
  }

  openRoleTray(role) {
    // TODO ideally (according to Kendall) we should have this close the current
    //      tray (an animation) before loading the new tray. I was hoping that
    //      calling hideTrays() here would be enough to do that, but it is
    //      alas not the case. The `Admin > People` page has an example of
    //      how this should look, so I should check there for inspiration.
    this.props.setAndOpenRoleTray(role)
  }

  renderTopHeader() {
    return (
      <thead>
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
                  <Link
                    isWithinText={false}
                    as="button"
                    id={`role_${role.id}`}
                    onClick={() => this.openRoleTray(role)}
                    onFocus={this.fixHorizontalScroll}
                    size="small"
                  >
                    <Text size="medium">{role.label}</Text>
                  </Link>
                </div>
              </div>
            </th>
          ))}
        </tr>
      </thead>
    )
  }

  renderLeftHeader(perm) {
    const isExpanded = this.state.expanded[perm.permission_name]
    const ExpandIcon = isExpanded ? IconArrowOpenDownSolid : IconArrowOpenEndSolid
    const name = perm.permission_name
    const granulars = perm.granular_permissions
    const hasGranulars = granulars?.length > 0
    const isGranular = perm.granular_permission_group

    const toggleExpanded = () => {
      this.setState(prevState => {
        // Need to make a copy to avoid mutating existing state
        // eslint-disable-next-line prefer-object-spread
        const expanded = Object.assign({}, prevState.expanded)
        expanded[name] = !expanded[name]

        const count = granulars.length
        if (expanded[name]) {
          $.screenReaderFlashMessage(I18n.t('%{count} rows added', {count}))
        } else {
          $.screenReaderFlashMessage(I18n.t('%{count} rows removed', {count}))
        }

        if (expanded[name]) this.justExpanded = name
        return {expanded}
      })
    }

    function renderGroupDescription() {
      const description = GROUP_PERMISSION_DESCRIPTIONS[name]
      if (typeof description !== 'function') return null

      return [
        <br key="group-description-br" />,
        <Text key="group-description-text" weight="light" size="small">
          {description(perm.contextType)}
        </Text>,
      ]
    }

    return (
      <th scope="row" className="ic-permissions__main-left-header" aria-label={perm.label}>
        <div className="ic-permissions__left-header__col-wrapper">
          <div className="ic-permissions__header-content">
            {hasGranulars && (
              <IconButton
                data-testid={`expand_${name}`}
                margin="0 0 0 x-small"
                withBorder={false}
                size="small"
                withBackground={false}
                onClick={toggleExpanded}
                screenReaderLabel={
                  isExpanded
                    ? I18n.t('Expand %{permission}', {permission: perm.label})
                    : I18n.t('Shrink %{permission}', {permission: perm.label})
                }
                renderIcon={ExpandIcon}
              />
            )}
            {isGranular && <span style={{minWidth: '2.25rem'}} />}
            <View maxWidth="17rem" as="div" padding="small">
              <Link
                isWithinText={false}
                as="button"
                id={`permission_${name}`}
                onClick={() => this.props.setAndOpenPermissionTray(perm)}
              >
                <Text size="medium">{perm.label}</Text>
              </Link>
              {hasGranulars && renderGroupDescription()}
            </View>
          </div>
        </div>
      </th>
    )
  }

  renderExpandedRows(perm) {
    return perm.granular_permissions.map(permission => (
      <tr
        key={permission.label}
        className={`${GRANULAR_PERMISSION_TAG}-${permission.granular_permission_group}`}
      >
        {this.renderLeftHeader(permission)}
        {this.props.roles.map(role => (
          <td key={role.id}>
            <ConnectedGranularCheckbox
              permission={role.permissions[permission.permission_name]}
              permissionName={permission.permission_name}
              permissionLabel={permission.label}
              roleId={role.id}
              handleScroll={this.fixHorizontalScroll}
            />
          </td>
        ))}
      </tr>
    ))
  }

  renderTable() {
    return (
      <table className="ic-permissions__table">
        {this.renderTopHeader()}
        <tbody ref={this.tableRef}>
          {this.props.permissions.map(perm => (
            <Fragment key={perm.permission_name}>
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
                        onFocus={this.fixHorizontalScroll}
                      />
                    </div>
                  </td>
                ))}
              </tr>
              {this.state.expanded[perm.permission_name] && this.renderExpandedRows(perm)}
            </Fragment>
          ))}
        </tbody>
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
    permissions: state.permissions.filter(p => p.displayed),
  }
  return {...ownProps, ...stateProps}
}

const mapDispatchToProps = {
  setAndOpenRoleTray: actions.setAndOpenRoleTray,
  setAndOpenPermissionTray: actions.setAndOpenPermissionTray,
}

export const ConnectedPermissionsTable = connect(
  mapStateToProps,
  mapDispatchToProps
)(PermissionsTable)
