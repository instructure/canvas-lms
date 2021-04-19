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
import React, {useRef, useState} from 'react'
import useStateWithCallback from '@canvas/use-state-with-callback-hook'
import {func, arrayOf} from 'prop-types'
import {connect} from 'react-redux'
import {debounce, isEqual} from 'lodash'
import $ from 'jquery'
import '@canvas/rails-flash-notifications'

import {ScreenReaderContent} from '@instructure/ui-a11y'
import {Button} from '@instructure/ui-buttons'
import {Grid} from '@instructure/ui-grid'
import {View} from '@instructure/ui-view'
import {IconSearchLine} from '@instructure/ui-icons'
import {Tabs} from '@instructure/ui-tabs'
import CanvasMultiSelect from '@canvas/multi-select'
import {TextInput} from '@instructure/ui-text-input'
import {Heading} from '@instructure/ui-heading'

import actions from '../actions'
import propTypes, {COURSE, ACCOUNT, ALL_ROLES_VALUE, ALL_ROLES_LABEL} from '@canvas/permissions/react/propTypes'

import {ConnectedPermissionsTable} from './PermissionsTable'
import {ConnectedPermissionTray} from './PermissionTray'
import {ConnectedRoleTray} from './RoleTray'
import {ConnectedAddTray} from './AddTray'

function setDiff(minuend, subtrahend) {
  const difference = new Set(minuend)
  for (const elt of subtrahend) {
    difference.delete(elt)
  }
  return difference
}

const SEARCH_DELAY = 350

export default function PermissionsIndex(props) {
  const setPermissionSearchString = useStateWithCallback('')[1]
  const [contextType, setContextType] = useStateWithCallback(COURSE)
  const [selectedTabId, setSelectedTabId] = useState('course')

  function filterPermissions(searchString) {
    props.searchPermissions({
      contextType,
      permissionSearchString: searchString
    })
  }

  const debouncedFilterPermissions = useRef(
    debounce(filterPermissions, SEARCH_DELAY, {
      leading: false,
      trailing: true
    })
  )

  function onRoleFilterChange(newIdList) {
    let resultSet = new Set(newIdList)
    const oldSet = new Set(props.selectedRoles.map(r => r.id || r.value))
    if (oldSet.size === 0) oldSet.add(ALL_ROLES_VALUE)
    if (resultSet.size === 0) resultSet.add(ALL_ROLES_VALUE)

    if (!oldSet.has(ALL_ROLES_VALUE) && resultSet.has(ALL_ROLES_VALUE)) {
      resultSet = new Set(ALL_ROLES_VALUE)
    } else {
      const added = setDiff(resultSet, oldSet)
      const removed = setDiff(oldSet, resultSet)
      if (added.size > 0) {
        const addedRole = props.roles.find(r => added.has(r.id || r.value))
        $.screenReaderFlashMessage(I18n.t('%{value} Added', {value: addedRole.label}))
      }
      if (removed.size > 0) {
        const removedRole = props.roles.find(r => removed.has(r.id || r.value))
        $.screenReaderFlashMessage(I18n.t('%{value} Removed', {value: removedRole.label}))
      }
    }

    if (resultSet.size > 1) resultSet.delete(ALL_ROLES_VALUE)
    if (isEqual(oldSet, resultSet)) return
    const sel = props.roles.filter(r => resultSet.has(r.id))
    props.filterRoles({
      selectedRoles: sel,
      contextType
    })
  }

  function onSearchStringChange(e) {
    setPermissionSearchString(e.target.value, debouncedFilterPermissions.current)
  }

  function onTabChanged(_e, {id}) {
    if (id === selectedTabId) return
    const newContextType = id === 'course' ? COURSE : ACCOUNT
    props.filterRoles({
      selectedRoles: [{value: ALL_ROLES_VALUE, label: ALL_ROLES_LABEL}],
      contextType
    })
    setPermissionSearchString('')
    setContextType(newContextType, props.tabChanged)
    setSelectedTabId(id)
  }

  function optionsToRender() {
    const options = props.roles
      .filter(role => role.contextType === contextType)
      .map(role => (
        <CanvasMultiSelect.Option
          key={role.id}
          id={role.id || role.value}
          value={role.value || role.id}
        >
          {role.label}
        </CanvasMultiSelect.Option>
      ))

    options.push(
      <CanvasMultiSelect.Option key={ALL_ROLES_VALUE} id={ALL_ROLES_VALUE} value={ALL_ROLES_VALUE}>
        {ALL_ROLES_LABEL}
      </CanvasMultiSelect.Option>
    )
    return options
  }

  function renderHeader() {
    const selectedIds = props.selectedRoles.map(r => r.id || r.value)
    if (selectedIds.length === 0) selectedIds.push(ALL_ROLES_VALUE)
    return (
      <div className="permissions-v2__header_container">
        <View display="block">
          <Grid>
            <Grid.Row vAlign="middle">
              <Grid.Col width={3}>
                <TextInput
                  label={<ScreenReaderContent>{I18n.t('Search Permissions')}</ScreenReaderContent>}
                  placeholder={I18n.t('Search Permissions')}
                  icon={() => (
                    <span disabled>
                      <IconSearchLine focusable={false} />
                    </span>
                  )}
                  onChange={onSearchStringChange}
                  name="permission_search"
                />
              </Grid.Col>
              <Grid.Col width={8}>
                <CanvasMultiSelect
                  id="permissions-role-filter"
                  assistiveText={I18n.t(
                    'Filter Roles. Type or use arrow keys to navigate. Multiple selections are allowed.'
                  )}
                  onChange={onRoleFilterChange}
                  selectedOptionIds={selectedIds}
                >
                  {optionsToRender()}
                </CanvasMultiSelect>
              </Grid.Col>
              <Grid.Col width={2}>
                <Button
                  id="add_role"
                  variant="primary"
                  margin="0 x-small 0 0"
                  onClick={props.setAndOpenAddTray}
                >
                  {I18n.t('Add Role')}
                </Button>
              </Grid.Col>
            </Grid.Row>
          </Grid>
        </View>
      </div>
    )
  }

  return (
    <div className="permissions-v2__wrapper">
      <ScreenReaderContent>
        <Heading level="h1">{I18n.t('Permissions')}</Heading>
      </ScreenReaderContent>
      <ConnectedRoleTray />
      <ConnectedAddTray />
      <ConnectedPermissionTray
        tab={props.roles.length ? props.roles.find(role => !!role.displayed).contextType : COURSE}
      />
      <Tabs onRequestTabChange={onTabChanged}>
        <Tabs.Panel
          id="course"
          renderTitle={I18n.t('Course Roles')}
          isSelected={selectedTabId === 'course'}
        >
          {renderHeader()}
          <ConnectedPermissionsTable />
        </Tabs.Panel>
        <Tabs.Panel
          id="account"
          renderTitle={I18n.t('Account Roles')}
          isSelected={selectedTabId === 'account'}
        >
          {renderHeader()}
          <ConnectedPermissionsTable />
        </Tabs.Panel>
      </Tabs>
    </div>
  )
}

PermissionsIndex.propTypes = {
  filterRoles: func.isRequired,
  roles: arrayOf(propTypes.role).isRequired,
  searchPermissions: func.isRequired,
  tabChanged: func.isRequired,
  selectedRoles: arrayOf(propTypes.filteredRole).isRequired
}

function mapStateToProps(state, ownProps) {
  return {
    ...ownProps,
    roles: state.roles,
    selectedRoles: state.selectedRoles
  }
}

const mapDispatchToProps = {
  filterRoles: actions.filterRoles,
  searchPermissions: actions.searchPermissions,
  setAndOpenAddTray: actions.setAndOpenAddTray,
  tabChanged: actions.tabChanged
}

export const ConnectedPermissionsIndex = connect(
  mapStateToProps,
  mapDispatchToProps
)(PermissionsIndex)
