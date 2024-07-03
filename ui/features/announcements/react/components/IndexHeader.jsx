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
import {useScope as useI18nScope} from '@canvas/i18n'
import React, {Component} from 'react'
import {Button} from '@instructure/ui-buttons'
import {FormField} from '@instructure/ui-form-field'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {
  IconLockLine,
  IconPlusLine,
  IconTrashLine,
  IconUnlockLine,
  IconInvitationLine,
} from '@instructure/ui-icons'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y-content'

import actions from '../actions'
import ExternalFeedsTray from './ExternalFeedsTray'
import propTypes from '../propTypes'
import select from '@canvas/obj-select'
import {showConfirmDelete} from './ConfirmDeleteModal'
import {SimpleSelect} from '@instructure/ui-simple-select'
import WithBreakpoints, {breakpointsShape} from '@canvas/with-breakpoints'
import {HeadingMenu} from '@canvas/discussions/react/components/HeadingMenu'
import {SearchField} from '@canvas/discussions/react/components/SearchField'

const I18n = useI18nScope('announcements_v2')

const instUINavEnabled = () => window.ENV?.FEATURES?.instui_nav

// Delay the search so as not to overzealously read out the number
// of search results to the user

const getFilters = () => ({
  all: instUINavEnabled() ? I18n.t('All Announcements') : I18n.t('All'),
  unread: instUINavEnabled() ? I18n.t('Unread Announcements') : I18n.t('Unread'),
})

export default class IndexHeader extends Component {
  static propTypes = {
    breakpoints: breakpointsShape.isRequired,
    contextType: string,
    contextId: string,
    isBusy: bool,
    selectedCount: number,
    isToggleLocking: bool.isRequired,
    permissions: propTypes.permissions.isRequired,
    atomFeedUrl: string,
    searchAnnouncements: func.isRequired,
    toggleSelectedAnnouncementsLock: func.isRequired,
    deleteSelectedAnnouncements: func.isRequired,
    searchInputRef: func,
    markAllAnnouncementRead: func.isRequired,
    announcementsLocked: bool.isRequired,
  }

  static defaultProps = {
    isBusy: false,
    atomFeedUrl: null,
    selectedCount: 0,
    searchInputRef: null,
    breakpoints: {},
  }

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

  onFilterChange = data => {
    this.props.searchAnnouncements({filter: data.value})
  }

  onSearchChange = data => {
    this.props.searchAnnouncements({term: data.searchTerm})
  }

  renderLockToggleButton(icon, label, screenReaderLabel, responsiveStyles) {
    return (
      <Button
        disabled={this.props.isBusy || this.props.selectedCount === 0}
        size="medium"
        display={responsiveStyles.buttonDisplay}
        id="lock_announcements"
        data-testid="lock_announcements"
        onClick={this.props.toggleSelectedAnnouncementsLock}
        renderIcon={icon}
      >
        {instUINavEnabled() && <PresentationContent>{label}</PresentationContent>}
        <ScreenReaderContent>{screenReaderLabel}</ScreenReaderContent>
      </Button>
    )
  }

  renderActionButtons(responsiveStyles) {
    return (
      <>
        {this.props.permissions.manage_course_content_edit &&
          !this.props.announcementsLocked &&
          (this.props.isToggleLocking
            ? this.renderLockToggleButton(
                <IconLockLine />,
                I18n.t('Lock'),
                I18n.t('Lock Selected Announcements'),
                responsiveStyles
              )
            : this.renderLockToggleButton(
                <IconUnlockLine />,
                I18n.t('Unlock'),
                I18n.t('Unlock Selected Announcements'),
                responsiveStyles
              ))}
        {this.props.permissions.manage_course_content_delete && (
          <Button
            disabled={this.props.isBusy || this.props.selectedCount === 0}
            size="medium"
            display={responsiveStyles.buttonDisplay}
            id="delete_announcements"
            data-testid="delete-announcements-button"
            onClick={this.onDelete}
            renderIcon={<IconTrashLine />}
            ref={c => {
              this.deleteBtn = c
            }}
          >
            {instUINavEnabled() && <PresentationContent>{I18n.t('Delete')}</PresentationContent>}
            <ScreenReaderContent>{I18n.t('Delete Selected Announcements')}</ScreenReaderContent>
          </Button>
        )}
        <Button
          id="mark_all_announcement_read"
          data-testid="mark-all-announcement-read"
          renderIcon={IconInvitationLine}
          display={responsiveStyles.buttonDisplay}
          onClick={this.props.markAllAnnouncementRead}
          disabled={this.props.isBusy}
        >
          <ScreenReaderContent>{I18n.t('Mark all announcement read')}</ScreenReaderContent>
          <PresentationContent>{I18n.t('Mark all as read')}</PresentationContent>
        </Button>
        {this.props.permissions.create && (
          <Button
            href={`/${this.props.contextType}s/${this.props.contextId}/discussion_topics/new?is_announcement=true`}
            color="primary"
            display={responsiveStyles.buttonDisplay}
            id="add_announcement"
            renderIcon={IconPlusLine}
          >
            <ScreenReaderContent>{I18n.t('Add announcement')}</ScreenReaderContent>
            <PresentationContent>{I18n.t('Announcement')}</PresentationContent>
          </Button>
        )}
      </>
    )
  }

  renderOldHeader(breakpoints) {
    const ddSize = breakpoints.desktopOnly ? '100px' : '100%'
    const containerSize = breakpoints.tablet ? 'auto' : '100%'
    const {searchInputRef} = this.props

    return (
      <View>
        <View margin="0 0 medium" display="block">
          <Flex wrap="wrap" justifyItems="end" gap="small">
            <Flex.Item size={ddSize} shouldGrow={true} shouldShrink={true}>
              <FormField
                id="announcement-filter"
                label={<ScreenReaderContent>{I18n.t('Announcement Filter')}</ScreenReaderContent>}
              >
                <SimpleSelect
                  renderLabel=""
                  id="announcement-filter"
                  name="filter-dropdown"
                  onChange={(_e, data) => {
                    return this.props.searchAnnouncements({filter: data.value})
                  }}
                >
                  {Object.keys(getFilters()).map(filter => (
                    <SimpleSelect.Option key={filter} id={filter} value={filter}>
                      {getFilters()[filter]}
                    </SimpleSelect.Option>
                  ))}
                </SimpleSelect>
              </FormField>
            </Flex.Item>
            <Flex.Item size={containerSize} shouldGrow={true} shouldShrink={true}>
              <SearchField
                name="announcements_search"
                searchInputRef={searchInputRef}
                onSearchEvent={this.onSearchChange}
              />
            </Flex.Item>
            <Flex.Item>
              <Flex wrap="wrap" gap="small">
                {this.renderActionButtons({
                  buttonDisplay: 'inline-block',
                  buttonMargin: '0 0 0 small',
                })}
              </Flex>
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

  render() {
    const {breakpoints, searchInputRef} = this.props

    if (!instUINavEnabled()) {
      return this.renderOldHeader(breakpoints)
    }

    let flexBasis = 'auto'
    let buttonDisplay = 'inline-block'
    let flexDirection = 'row'
    let headerShrink = false

    if (breakpoints.mobileOnly) {
      flexBasis = '100%'
      buttonDisplay = 'block'
      flexDirection = 'column-reverse'
      headerShrink = true
    }

    return (
      <Flex direction="column" as="div" gap="medium">
        <Flex.Item overflow="hidden">
          <Flex as="div" direction="row" justifyItems="space-between" wrap="wrap" gap="small">
            <Flex.Item width={flexBasis} shouldGrow={true} shouldShrink={headerShrink}>
              <HeadingMenu
                name={I18n.t('Announcement Filter')}
                filters={getFilters()}
                defaultSelectedFilter="all"
                onSelectFilter={this.onFilterChange}
              />
            </Flex.Item>
            <Flex.Item width={flexBasis} overflowX="hidden" overflowY="hidden">
              <Flex direction={flexDirection} wrap="wrap" gap="small">
                {this.renderActionButtons({
                  buttonDisplay,
                })}
              </Flex>
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <SearchField
          name="announcements_search"
          searchInputRef={searchInputRef}
          onSearchEvent={this.onSearchChange}
        />
        <Flex.Item margin="large 0 0 0">
          <ExternalFeedsTray
            atomFeedUrl={this.props.atomFeedUrl}
            permissions={this.props.permissions}
          />
        </Flex.Item>
      </Flex>
    )
  }
}

const connectState = state => ({
  isBusy: state.isLockingAnnouncements || state.isDeletingAnnouncements || state.isMarkingAllRead,
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
  'markAllAnnouncementRead',
]

const connectActions = dispatch => bindActionCreators(select(actions, selectedActions), dispatch)
export const ConnectedIndexHeader = WithBreakpoints(
  connect(connectState, connectActions)(IndexHeader)
)
