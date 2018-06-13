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

import I18n from 'i18n!discussions_v2'
import React, { Component } from 'react'
import { string, func, bool } from 'prop-types'
import { connect } from 'react-redux'
import { debounce } from 'lodash'
import { bindActionCreators } from 'redux'

import Button from '@instructure/ui-buttons/lib/components/Button'
import TextInput from '@instructure/ui-forms/lib/components/TextInput'
import Select from '@instructure/ui-core/lib/components/Select'
import Grid, { GridCol, GridRow } from '@instructure/ui-layout/lib/components/Grid'
import View from '@instructure/ui-layout/lib/components/View'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import PresentationContent from '@instructure/ui-a11y/lib/components/PresentationContent'
import IconPlus from '@instructure/ui-icons/lib/Line/IconPlus'
import IconSearchLine from '@instructure/ui-icons/lib/Line/IconSearch'
import DiscussionSettings from './DiscussionSettings'
import select from '../../shared/select'
import propTypes from '../propTypes'
import actions from '../actions'

const filters = {
  all: I18n.t('All'),
  unread: I18n.t('Unread')
}

const SEARCH_DELAY = 350

export default class IndexHeader extends Component {
  static propTypes = {
    contextId: string.isRequired,
    contextType: string.isRequired,
    courseSettings: propTypes.courseSettings,
    fetchCourseSettings: func.isRequired,
    fetchUserSettings: func.isRequired,
    isSavingSettings: bool.isRequired,
    isSettingsModalOpen: bool.isRequired,
    permissions: propTypes.permissions.isRequired,
    saveSettings: func.isRequired,
    searchDiscussions: func.isRequired,
    toggleModalOpen: func.isRequired,
    userSettings: propTypes.userSettings.isRequired,
  }

  static defaultProps = {
    courseSettings: {},
  }

  state = {
    searchTerm: "",
    filter: 'all',
  }

  componentDidMount() {
    this.props.fetchUserSettings()
    if(this.props.contextType === 'course' && this.props.permissions.change_settings) {
      this.props.fetchCourseSettings()
    }
  }

  onSearchStringChange = (e) => {
    this.setState({searchTerm: e.target.value}, this.filterDiscussions)
  }

  onFilterChange = (e) => {
    this.setState({filter: e.target.value}, this.filterDiscussions)
  }

  // This is needed to make the search results do not keep cutting each
  // other off when typing fasting and using a screen reader
  filterDiscussions = debounce(
    () => this.props.searchDiscussions(this.state),
    SEARCH_DELAY,
    {leading: false, trailing: true}
  )

  render () {
    return (
      <View>
        <View display="block">
          <Grid>
            <GridRow hAlign="space-between">
              <GridCol width={2}>
                <Select
                  name="filter-dropdown"
                  onChange={this.onFilterChange}
                  size="medium"
                  label={<ScreenReaderContent>{I18n.t('Discussion Filter')}</ScreenReaderContent>}>
                  {
                    Object.keys(filters).map((filter) => (<option key={filter} value={filter}>{filters[filter]}</option>))
                  }
                </Select>
              </GridCol>
              <GridCol width={4}>
                <TextInput
                  label={<ScreenReaderContent>{I18n.t('Search discussion by title')}</ScreenReaderContent>}
                  placeholder={I18n.t('Search')}
                  icon={() => <IconSearchLine />}
                  onChange={this.onSearchStringChange}
                  name="discussion_search"
                />
              </GridCol>
              <GridCol width={6} textAlign="end">
                {this.props.permissions.create &&
                  <Button
                    href={`/${this.props.contextType}s/${this.props.contextId}/discussion_topics/new`}
                    variant="primary"
                    id="add_discussion"
                  ><IconPlus />
                    <ScreenReaderContent>{I18n.t('Add discussion')}</ScreenReaderContent>
                    <PresentationContent>{I18n.t('Discussion')}</PresentationContent>
                  </Button>
                }
                {Object.keys(this.props.userSettings).length ?
                    <DiscussionSettings
                      courseSettings={this.props.courseSettings}
                      userSettings={this.props.userSettings}
                      permissions={this.props.permissions}
                      saveSettings={this.props.saveSettings}
                      toggleModalOpen={this.props.toggleModalOpen}
                      isSettingsModalOpen={this.props.isSettingsModalOpen}
                      isSavingSettings={this.props.isSavingSettings}
                    />
                    : null}
              </GridCol>
            </GridRow>
          </Grid>
        </View>
      </View>
    )
  }
}

const connectState = state => Object.assign({
}, select(state, [
  'contextType',
  'contextId',
  'permissions',
  'userSettings',
  'courseSettings',
  'isSavingSettings',
  'isSettingsModalOpen',
]))
const selectedActions = ['fetchUserSettings', 'searchDiscussions', 'fetchCourseSettings', 'saveSettings', 'toggleModalOpen']
const connectActions = dispatch => bindActionCreators(select(actions, selectedActions), dispatch)
export const ConnectedIndexHeader = connect(connectState, connectActions)(IndexHeader)
