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
import {func, arrayOf} from 'prop-types'
import {connect} from 'react-redux'
import {debounce} from 'lodash'

import AccessibleContent from '@instructure/ui-a11y/lib/components/AccessibleContent'
import Button from '@instructure/ui-buttons/lib/components/Button'
import Container from '@instructure/ui-layout/lib/components/View'
import Grid, {GridCol, GridRow} from '@instructure/ui-layout/lib/components/Grid'
import IconSearchLine from '@instructure/ui-icons/lib/Line/IconSearch'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import TabList, {TabPanel} from '@instructure/ui-tabs/lib/components/TabList'
import TextInput from '@instructure/ui-forms/lib/components/TextInput'
import Select from '@instructure/ui-forms/lib/components/Select'
import Heading from '@instructure/ui-elements/lib/components/Heading'

import actions from '../actions'
import propTypes, {COURSE, ACCOUNT, ALL_ROLES_VALUE, ALL_ROLES_LABEL} from '../propTypes'

import {ConnectedPermissionsTable} from './PermissionsTable'
import {ConnectedPermissionTray} from './PermissionTray'
import {ConnectedRoleTray} from './RoleTray'
import {ConnectedAddTray} from './AddTray'

const SEARCH_DELAY = 350
const COURSE_TAB_INDEX = 0

export default class PermissionsIndex extends Component {
  static propTypes = {
    filterRoles: func.isRequired,
    roles: arrayOf(propTypes.role).isRequired,
    searchPermissions: func.isRequired,
    setAndOpenAddTray: func.isRequired,
    tabChanged: func.isRequired,
    selectedRoles: arrayOf(propTypes.filteredRole).isRequired
  }

  state = {
    permissionSearchString: '',
    contextType: COURSE
  }

  onRoleFilterChange = (_, value) => {
    const valueCopy = value.filter(option => option.value !== ALL_ROLES_VALUE)
    this.props.filterRoles({
      selectedRoles: valueCopy,
      contextType: this.state.contextType
    })
  }

  onSearchStringChange = e => {
    this.setState({permissionSearchString: e.target.value}, this.filterPermissions)
  }

  onTabChanged = (newIndex, oldIndex) => {
    if (newIndex === oldIndex) return
    const newContextType = newIndex === COURSE_TAB_INDEX ? COURSE : ACCOUNT
    this.props.filterRoles({
      selectedRoles: [{value: ALL_ROLES_VALUE, label: ALL_ROLES_LABEL}],
      contextType: this.state.contextType
    })
    this.setState(
      {
        permissionSearchString: '',

        contextType: newContextType
      },
      () => {
        this.props.tabChanged(newContextType)
      }
    )
  }

  onAutocompleteBlur = e => {
    if (e.target.value === '' && this.props.selectedRoles.length === 0) {
      this.props.filterRoles({
        selectedRoles: [{value: ALL_ROLES_VALUE, label: ALL_ROLES_LABEL}],
        contextType: this.state.contextType
      })
    }
  }

  filterPermissions = debounce(() => this.props.searchPermissions(this.state), SEARCH_DELAY, {
    leading: false,
    trailing: true
  })

  renderHeader() {
    return (
      <div className="permissions-v2__header_contianer">
        <Container display="block">
          <Grid>
            <GridRow vAlign="middle">
              <GridCol width={3}>
                <TextInput
                  label={<ScreenReaderContent>{I18n.t('Search Permissions')}</ScreenReaderContent>}
                  placeholder={I18n.t('Search Permissions')}
                  icon={() => (
                    <span disabled="true">
                      <IconSearchLine focusable={false} />
                    </span>
                  )}
                  onChange={this.onSearchStringChange}
                  name="permission_search"
                />
              </GridCol>
              <GridCol width={8}>
                <Select
                  id="permissions-role-filter"
                  label={<ScreenReaderContent>{I18n.t('Filter Roles')}</ScreenReaderContent>}
                  selectedOption={this.props.selectedRoles}
                  onBlur={this.onAutocompleteBlur}
                  multiple
                  editable
                  assistiveText={I18n.t(
                    'Start typing to search. Press the down arrow to navigate results.'
                  )}
                  onChange={this.onRoleFilterChange}
                  formatSelectedOption={tag => (
                    <AccessibleContent
                      alt={I18n.t(`Remove role filter %{label}`, {label: tag.label})}
                    >
                      {tag.label}
                    </AccessibleContent>
                  )}
                >
                  {this.props.roles
                    .filter(role => role.contextType === this.state.contextType)
                    .map(role => (
                      <option key={`${role.id}`} value={`${role.id}`}>
                        {role.label}
                      </option>
                    ))}
                </Select>
              </GridCol>
              <GridCol width={2}>
                <Button
                  id="add_role"
                  variant="primary"
                  margin="0 x-small 0 0"
                  onClick={this.props.setAndOpenAddTray}
                >
                  {I18n.t('Add Role')}
                </Button>
              </GridCol>
            </GridRow>
          </Grid>
        </Container>
      </div>
    )
  }

  render() {
    return (
      <div className="permissions-v2__wrapper">
        <ScreenReaderContent>
          <Heading level="h1">{I18n.t('Permissions')}</Heading>
        </ScreenReaderContent>
        <ConnectedRoleTray />
        <ConnectedAddTray />
        <ConnectedPermissionTray
          tab={
            this.props.roles.length
              ? this.props.roles.find(role => !!role.displayed).contextType
              : COURSE
          }
        />
        <TabList onChange={this.onTabChanged}>
          <TabPanel title={I18n.t('Course Roles')}>
            {this.renderHeader()}
            <ConnectedPermissionsTable />
          </TabPanel>
          <TabPanel title={I18n.t('Account Roles')}>
            {this.renderHeader()}
            <ConnectedPermissionsTable />
          </TabPanel>
        </TabList>
      </div>
    )
  }
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
