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
import React, {useEffect, useState} from 'react'
import {func, arrayOf} from 'prop-types'
import {connect} from 'react-redux'
import {isEqual} from 'lodash'
import {useDebounce} from 'use-debounce'
import $ from 'jquery'
import '@canvas/rails-flash-notifications'

import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {IconSearchLine} from '@instructure/ui-icons'
import {Tabs} from '@instructure/ui-tabs'
import CanvasMultiSelect from '@canvas/multi-select'
import {TextInput} from '@instructure/ui-text-input'
import {Heading} from '@instructure/ui-heading'

import actions from '../actions'
import propTypes, {
  COURSE,
  ACCOUNT,
  ALL_ROLES_VALUE,
  ALL_ROLES_LABEL,
} from '@canvas/permissions/react/propTypes'

import {ConnectedPermissionsTable} from './PermissionsTable'
import {ConnectedPermissionTray} from './PermissionTray'
import {ConnectedRoleTray} from './RoleTray'
import {ConnectedAddTray} from './AddTray'

const I18n = useI18nScope('permissions_v2')

function setDiff(minuend, subtrahend) {
  const difference = new Set(minuend)
  for (const elt of subtrahend) {
    difference.delete(elt)
  }
  return difference
}

const SEARCH_DELAY = 500

export default function PermissionsIndex(props) {
  const [contextType, setContextType] = useState(COURSE)
  const [selectedTabId, setSelectedTabId] = useState('tab-panel-course')
  const [permissionSearchString, setPermissionSearchString] = useState('')
  const [debouncedSearchString] = useDebounce(permissionSearchString, SEARCH_DELAY)

  useEffect(() => {
    const searchPermissions = props.searchPermissions

    searchPermissions({
      permissionSearchString: debouncedSearchString,
      contextType,
    })
  }, [contextType, debouncedSearchString, props.searchPermissions])

  function onSearchStringChange(e) {
    setPermissionSearchString(e.target.value)
  }

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
      contextType,
    })
  }

  function onTabChanged(_e, {id}) {
    if (id === selectedTabId) return
    const newContextType = id === 'tab-panel-course' ? COURSE : ACCOUNT
    props.filterRoles({
      selectedRoles: [{value: ALL_ROLES_VALUE, label: ALL_ROLES_LABEL}],
      contextType,
    })
    setPermissionSearchString('')
    setContextType(newContextType)
    setSelectedTabId(id)
    props.tabChanged(newContextType)
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
          <Flex alignItems="end">
            <Flex.Item size="20%">
              <TextInput
                renderLabel={
                  <ScreenReaderContent>{I18n.t('Search Permissions')}</ScreenReaderContent>
                }
                placeholder={I18n.t('Search Permissions')}
                renderAfterInput={() => (
                  <span disabled={true}>
                    <IconSearchLine focusable={false} />
                  </span>
                )}
                onChange={onSearchStringChange}
                name="permission_search"
              />
            </Flex.Item>
            <Flex.Item shouldShrink={true} shouldGrow={true} padding="0 small">
              <CanvasMultiSelect
                id="permissions-role-filter"
                label={I18n.t('Permission role filter')}
                assistiveText={I18n.t(
                  'Filter Roles. Type or use arrow keys to navigate. Multiple selections are allowed.'
                )}
                onChange={onRoleFilterChange}
                selectedOptionIds={selectedIds}
              >
                {optionsToRender()}
              </CanvasMultiSelect>
            </Flex.Item>
            <Flex.Item shouldShrink={true} justifyItems="end">
              <Flex justifyItems="end">
                <Flex.Item>
                  <Button id="add_role" color="primary" onClick={props.setAndOpenAddTray}>
                    {I18n.t('Add Role')}
                  </Button>
                </Flex.Item>
              </Flex>
            </Flex.Item>
          </Flex>
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
          id="tab-panel-course"
          renderTitle={I18n.t('Course Roles')}
          isSelected={selectedTabId === 'tab-panel-course'}
        >
          {renderHeader()}
          <ConnectedPermissionsTable />
        </Tabs.Panel>
        <Tabs.Panel
          id="tab-panel-account"
          renderTitle={I18n.t('Account Roles')}
          isSelected={selectedTabId === 'tab-panel-account'}
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
  setAndOpenAddTray: func.isRequired,
  tabChanged: func.isRequired,
  selectedRoles: arrayOf(propTypes.filteredRole).isRequired,
}

function mapStateToProps(state, ownProps) {
  return {
    ...ownProps,
    roles: state.roles,
    selectedRoles: state.selectedRoles,
  }
}

const mapDispatchToProps = {
  filterRoles: actions.filterRoles,
  searchPermissions: actions.searchPermissions,
  setAndOpenAddTray: actions.setAndOpenAddTray,
  tabChanged: actions.tabChanged,
}

export const ConnectedPermissionsIndex = connect(
  mapStateToProps,
  mapDispatchToProps
)(PermissionsIndex)
