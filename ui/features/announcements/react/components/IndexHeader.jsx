/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import {bindActionCreators} from 'redux'
import {bool, func, number, string} from 'prop-types'
import {connect} from 'react-redux'
import {debounce} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import React, {Component} from 'react'
import {Button} from '@instructure/ui-buttons'
import {FormField} from '@instructure/ui-form-field'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {
  IconLockLine,
  IconPlusLine,
  IconSearchLine,
  IconTrashLine,
  IconUnlockLine,
} from '@instructure/ui-icons'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TextInput} from '@instructure/ui-text-input'

import actions from '../actions'
import ExternalFeedsTray from './ExternalFeedsTray'
import propTypes from '../propTypes'
import select from '@canvas/obj-select'
import {showConfirmDelete} from './ConfirmDeleteModal'

const I18n = useI18nScope('announcements_v2')

// Delay the search so as not to overzealously read out the number
// of search results to the user
export const SEARCH_TIME_DELAY = 750
const filters = {
  all: I18n.t('All'),
  unread: I18n.t('Unread'),
}
export default class IndexHeader extends Component {
  static propTypes = {
    contextType: string.isRequired,
    contextId: string.isRequired,
    isBusy: bool,
    selectedCount: number,
    isToggleLocking: bool.isRequired,
    permissions: propTypes.permissions.isRequired,
    atomFeedUrl: string,
    searchAnnouncements: func.isRequired,
    toggleSelectedAnnouncementsLock: func.isRequired,
    deleteSelectedAnnouncements: func.isRequired,
    searchInputRef: func,
    announcementsLocked: bool.isRequired,
  }

  static defaultProps = {
    isBusy: false,
    atomFeedUrl: null,
    selectedCount: 0,
    searchInputRef: null,
  }

  onSearch = debounce(
    () => {
      const term = this.searchInput.value
      this.props.searchAnnouncements({term})
    },
    SEARCH_TIME_DELAY,
    {
      leading: false,
      trailing: true,
    }
  )

  onDelete = () => {
    showConfirmDelete({
      modalRef: modal => {
        this.deleteModal = modal
      },
      selectedCount: this.props.selectedCount,
      onConfirm: () => this.props.deleteSelectedAnnouncements(),
      onHide: () => {
        const {deleteBtn, searchInput} = this
        if (deleteBtn && deleteBtn._button && !deleteBtn._button.disabled) {
          deleteBtn.focus()
        } else if (searchInput) {
          searchInput.focus()
        }
      },
    })
  }

  searchInputRef = input => {
    this.searchInput = input
    if (this.props.searchInputRef) this.props.searchInputRef(input)
  }

  render() {
    return (
      <View>
        <View margin="0 0 medium" display="block">
          <Flex wrap="wrap" justifyItems="end">
            <Flex.Item shouldGrow={true}>
              <FormField
                id="announcement-filter"
                label={<ScreenReaderContent>{I18n.t('Announcement Filter')}</ScreenReaderContent>}
              >
                <select
                  id="announcement-filter"
                  name="filter-dropdown"
                  onChange={e => this.props.searchAnnouncements({filter: e.target.value})}
                  style={{
                    margin: '0',
                    width: '100%',
                  }}
                >
                  {Object.keys(filters).map(filter => (
                    <option key={filter} value={filter}>
                      {filters[filter]}
                    </option>
                  ))}
                </select>
              </FormField>
            </Flex.Item>

            <Flex.Item shouldGrow={true} margin="0 0 0 small">
              <TextInput
                renderLabel={
                  <ScreenReaderContent>
                    {I18n.t('Search announcements by title')}
                  </ScreenReaderContent>
                }
                placeholder={I18n.t('Search')}
                renderAfterInput={() => <IconSearchLine />}
                ref={this.searchInputRef}
                onChange={this.onSearch}
                name="announcements_search"
              />
            </Flex.Item>
            <Flex.Item margin="0 0 0 small">
              {this.props.permissions.manage_course_content_edit &&
                !this.props.announcementsLocked &&
                (this.props.isToggleLocking ? (
                  <Button
                    disabled={this.props.isBusy || this.props.selectedCount === 0}
                    size="medium"
                    margin="0 small 0 0"
                    id="lock_announcements"
                    onClick={this.props.toggleSelectedAnnouncementsLock}
                  >
                    <IconLockLine />
                    <ScreenReaderContent>
                      {I18n.t('Lock Selected Announcements')}
                    </ScreenReaderContent>
                  </Button>
                ) : (
                  <Button
                    disabled={this.props.isBusy || this.props.selectedCount === 0}
                    size="medium"
                    margin="0 small 0 0"
                    id="lock_announcements"
                    onClick={this.props.toggleSelectedAnnouncementsLock}
                  >
                    <IconUnlockLine />
                    <ScreenReaderContent>
                      {I18n.t('Unlock Selected Announcements')}
                    </ScreenReaderContent>
                  </Button>
                ))}
              {this.props.permissions.manage_course_content_delete && (
                <Button
                  disabled={this.props.isBusy || this.props.selectedCount === 0}
                  size="medium"
                  margin="0 small 0 0"
                  id="delete_announcements"
                  onClick={this.onDelete}
                  ref={c => {
                    this.deleteBtn = c
                  }}
                >
                  <IconTrashLine />
                  <ScreenReaderContent>
                    {I18n.t('Delete Selected Announcements')}
                  </ScreenReaderContent>
                </Button>
              )}
              {this.props.permissions.create && (
                <Button
                  href={`/${this.props.contextType}s/${this.props.contextId}/discussion_topics/new?is_announcement=true`}
                  color="primary"
                  id="add_announcement"
                >
                  <IconPlusLine />
                  <ScreenReaderContent>{I18n.t('Add announcement')}</ScreenReaderContent>
                  <PresentationContent>{I18n.t('Announcement')}</PresentationContent>
                </Button>
              )}
            </Flex.Item>
          </Flex>
        </View>
        <ExternalFeedsTray
          atomFeedUrl={this.props.atomFeedUrl}
          permissions={this.props.permissions}
        />
      </View>
    )
  }
}

const connectState = state => ({
  isBusy: state.isLockingAnnouncements || state.isDeletingAnnouncements,
  selectedCount: state.selectedAnnouncements.length,
  isToggleLocking: state.isToggleLocking,
  ...select(state, [
    'contextType',
    'contextId',
    'permissions',
    'atomFeedUrl',
    'announcementsLocked',
  ]),
})
const selectedActions = [
  'searchAnnouncements',
  'toggleSelectedAnnouncementsLock',
  'deleteSelectedAnnouncements',
]
const connectActions = dispatch => bindActionCreators(select(actions, selectedActions), dispatch)
export const ConnectedIndexHeader = connect(connectState, connectActions)(IndexHeader)
