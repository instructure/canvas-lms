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
import {func} from 'prop-types'
import {connect} from 'react-redux'
import {debounce} from 'lodash'

import Container from '@instructure/ui-layout/lib/components/View'
import Grid, {GridCol, GridRow} from '@instructure/ui-layout/lib/components/Grid'
import IconSearchLine from '@instructure/ui-icons/lib/Line/IconSearch'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import TabList, {TabPanel} from '@instructure/ui-tabs/lib/components/TabList'
import TextInput from '@instructure/ui-forms/lib/components/TextInput'

import actions from '../actions'
import {COURSE, ACCOUNT} from '../propTypes'

import {ConnectedPermissionsTable} from './PermissionsTable'
import {ConnectedRoleTray} from './RoleTray'

const SEARCH_DELAY = 350
const COURSE_TAB_INDEX = 0

export default class PermissionsIndex extends Component {
  static propTypes = {
    searchPermissions: func.isRequired
  }

  state = {
    permissionSearchString: '',
    contextType: COURSE
  }

  onSearchStringChange = e => {
    this.setState({permissionSearchString: e.target.value}, this.filterPermissions)
  }

  onTabChanged = (newIndex, oldIndex) => {
    if (newIndex === oldIndex) return
    const newContextType = newIndex === COURSE_TAB_INDEX ? COURSE : ACCOUNT
    this.setState({permissionSearchString: '', contextType: newContextType}, () =>
      this.props.searchPermissions(this.state)
    )
  }

  filterPermissions = debounce(() => this.props.searchPermissions(this.state), SEARCH_DELAY, {
    leading: false,
    trailing: true
  })

  renderHeader() {
    return (
      <Container display="block">
        <Grid>
          <GridRow vAlign="middle">
            <GridCol width={4}>
              <TextInput
                label={<ScreenReaderContent>{I18n.t('Search Permissions')}</ScreenReaderContent>}
                placeholder={I18n.t('Search Permissions')}
                icon={() => <IconSearchLine />}
                onChange={this.onSearchStringChange}
                name="permission_search"
              />
            </GridCol>
            <GridCol width={7}>ROLE FILTER GOES HERE {/* TODO */}</GridCol>
            <GridCol width={1}>ADD ROLE BUTTON {/* TODO */}</GridCol>
          </GridRow>
        </Grid>
      </Container>
    )
  }

  render() {
    return (
      <div className="permissions-v2__wrapper">
        <ConnectedRoleTray />
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

function mapStateToProps(_state, ownProps) {
  return ownProps
}

const mapDispatchToProps = {
  searchPermissions: actions.searchPermissions
}

export const ConnectedPermissionsIndex = connect(mapStateToProps, mapDispatchToProps)(
  PermissionsIndex
)
