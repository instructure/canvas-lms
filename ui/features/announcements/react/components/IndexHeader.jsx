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
import {useScope as createI18nScope} from '@canvas/i18n'
import React, {Component} from 'react'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {IconLockLine, IconPlusLine, IconTrashLine, IconUnlockLine} from '@instructure/ui-icons'
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
import {ActionDropDown} from '@canvas/announcements/react/components/ActionDropDown'
import ReadIcon from '@canvas/read-icon'

const I18n = createI18nScope('announcements_v2')

const instUINavEnabled = () => window.ENV?.FEATURES?.instui_nav

// Delay the search so as not to overzealously read out the number
// of search results to the user
const announcementsFilter = {
  all: {name: I18n.t('All Announcements'), title: I18n.t('Announcements')},
  unread: {name: I18n.t('Unread Announcements'), title: I18n.t('Unread Announcements')},
}
const getFilters = () => ({
  all: instUINavEnabled() ? announcementsFilter.all : I18n.t('All'),
  unread: instUINavEnabled() ? announcementsFilter.unread : I18n.t('Unread'),
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

  renderLockToggleButton(icon, label, screenReaderLabel, responsiveStyles, dataActionState) {
    return (
      <Button
        disabled={this.props.isBusy || this.props.selectedCount === 0}
        size="medium"
        display={responsiveStyles.buttonDisplay}
        id="lock_announcements"
        data-testid="lock_announcements"
        data-action-state={dataActionState}
        onClick={this.props.toggleSelectedAnnouncementsLock}
        renderIcon={icon}
        key="lockButton"
      >
        {instUINavEnabled() && <PresentationContent>{label}</PresentationContent>}
        <ScreenReaderContent>{screenReaderLabel}</ScreenReaderContent>
      </Button>
    )
  }

  renderButtonMenu = () => {
    return (
      <ActionDropDown
        label={I18n.t('More')}
        disabled={this.props.isBusy}
        key="actionDropDown"
        withArrow={false}
        actions={[
          {
            icon: IconTrashLine,
            label: I18n.t('Delete'),
            screenReaderLabel: I18n.t('Delete Selected Announcements'),
            action: this.onDelete,
            disabled: this.props.isBusy || this.props.selectedCount === 0,
          },
          {
            icon:
              !this.props.announcementsLocked && this.props.isToggleLocking
                ? IconLockLine
                : IconUnlockLine,
            label:
              !this.props.announcementsLocked && this.props.isToggleLocking
                ? I18n.t('Lock')
                : I18n.t('Unlock'),
            screenReaderLabel:
              !this.props.announcementsLocked && this.props.isToggleLocking
                ? I18n.t('Lock Selected Announcements')
                : I18n.t('Unlock Selected Announcements'),
            action: this.props.toggleSelectedAnnouncementsLock,
            disabled: this.props.isBusy || this.props.selectedCount === 0,
          },
        ]}
      />
    )
  }

  renderAddAnnouncementButton(responsiveStyles) {
    return (
      this.props.permissions.create && (
        <Button
          href={`/${this.props.contextType}s/${this.props.contextId}/discussion_topics/new?is_announcement=true`}
          color="primary"
          display={responsiveStyles.buttonDisplay}
          id="add_announcement"
          renderIcon={IconPlusLine}
          key="addAnnouncementButton"
        >
          {I18n.t('Add Announcement')}
        </Button>
      )
    )
  }

  renderMarkAllAsReadButton(responsiveStyles) {
    return (
      <Button
        id="mark_all_announcement_read"
        data-testid="mark-all-announcement-read"
        renderIcon={ReadIcon}
        display={responsiveStyles.buttonDisplay}
        onClick={this.props.markAllAnnouncementRead}
        disabled={this.props.isBusy}
        key="markAllAsReadButton"
      >
        <ScreenReaderContent>{I18n.t('Mark All Announcement Read')}</ScreenReaderContent>
        <PresentationContent>{I18n.t('Mark All as Read')}</PresentationContent>
      </Button>
    )
  }

  renderDeleteButton(responsiveStyles) {
    return (
      this.props.permissions.manage_course_content_delete && (
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
          key="deleteButton"
        >
          {instUINavEnabled() && <PresentationContent>{I18n.t('Delete')}</PresentationContent>}
          <ScreenReaderContent>{I18n.t('Delete Selected Announcements')}</ScreenReaderContent>
        </Button>
      )
    )
  }

  renderLockButton(responsiveStyles) {
    return (
      this.props.permissions.manage_course_content_edit &&
      !this.props.announcementsLocked &&
      (this.props.isToggleLocking
        ? this.renderLockToggleButton(
            <IconLockLine />,
            I18n.t('Lock'),
            I18n.t('Lock Selected Announcements'),
            responsiveStyles,
            'lockSelectedButton',
          )
        : this.renderLockToggleButton(
            <IconUnlockLine />,
            I18n.t('Unlock'),
            I18n.t('Unlock Selected Announcements'),
            responsiveStyles,
            'unlockSelectedButton',
          ))
    )
  }

  renderActionButtons(responsiveStyles) {
    const {breakpoints} = this.props

    const buttonsDirection = !instUINavEnabled() || breakpoints.ICEDesktop ? 'row' : 'column'
    const buttonsDesktop = [
      this.renderLockButton(responsiveStyles),
      this.renderDeleteButton(responsiveStyles),
      this.renderMarkAllAsReadButton(responsiveStyles),
      this.renderAddAnnouncementButton(responsiveStyles),
    ]

    const buttonsMobile = [
      this.renderAddAnnouncementButton(responsiveStyles),
      this.renderMarkAllAsReadButton(responsiveStyles),
      this.renderButtonMenu(),
    ]

    if (!instUINavEnabled()) {
      buttonsDesktop.reverse()
    }

    return (
      <Flex
        wrap="no-wrap"
        direction={buttonsDirection}
        gap="small"
        justifyItems="end"
        overflowX="hidden"
        overflowY="hidden"
        width="100%"
        height="100%"
      >
        {instUINavEnabled() && (breakpoints.ICEDesktop ? buttonsDesktop : buttonsMobile)}
        {!instUINavEnabled() && buttonsDesktop}
      </Flex>
    )
  }

  renderSearchField() {
    return (
      <SearchField
        id="announcements-search"
        name="announcements_search"
        searchInputRef={this.props.searchInputRef}
        onSearchEvent={this.onSearchChange}
        placeholder={I18n.t('Search...')}
      />
    )
  }

  renderOldHeader(breakpoints) {
    const ddSize = breakpoints.ICEDesktopOnly ? '100px' : '100%'
    const containerSize = breakpoints.tablet ? 'auto' : '100%'

    return (
      <View>
        <View margin="0 0 medium" display="block">
          <Flex wrap="wrap" justifyItems="end" gap="small">
            <Flex.Item size={ddSize} shouldGrow={true} shouldShrink={true}>
              <SimpleSelect
                renderLabel={
                  <ScreenReaderContent>{I18n.t('Announcement Filter')}</ScreenReaderContent>
                }
                id="announcement-filter"
                name="filter-dropdown"
                onChange={(_e, data) => this.props.searchAnnouncements({filter: data.value})}
              >
                {Object.entries(getFilters()).map(([filter, label]) => (
                  <SimpleSelect.Option key={filter} id={filter} value={filter}>
                    {label}
                  </SimpleSelect.Option>
                ))}
              </SimpleSelect>
            </Flex.Item>
            <Flex.Item size={containerSize} shouldGrow={true} shouldShrink={true}>
              {this.renderSearchField()}
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
    const {breakpoints} = this.props
    if (!instUINavEnabled()) {
      return this.renderOldHeader(breakpoints)
    }

    const flexBasis = breakpoints.ICEDesktop ? 'auto' : '100%'
    const buttonDisplay = breakpoints.ICEDesktop ? 'inline-block' : 'block'
    const headerShrink = !breakpoints.ICEDesktop
    const containerSize = breakpoints.tablet

    return (
      <Flex direction="column" as="div" gap="medium">
        <Flex.Item overflowY="visible">
          <Flex as="div" direction="row" justifyItems="space-between" wrap="wrap" gap="small">
            <Flex.Item
              width={flexBasis}
              shouldGrow={true}
              shouldShrink={headerShrink}
              overflowX="hidden"
              overflowY="hidden"
            >
              <HeadingMenu
                name={I18n.t('Announcement Filter')}
                filters={getFilters()}
                defaultSelectedFilter="all"
                onSelectFilter={this.onFilterChange}
                mobileHeader={!breakpoints.ICEDesktop}
              />
            </Flex.Item>
            <Flex.Item width={flexBasis} size={containerSize} overflowY="visible">
              {this.renderActionButtons({
                buttonDisplay,
              })}
            </Flex.Item>
          </Flex>
        </Flex.Item>
        {this.renderSearchField()}
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
  connect(connectState, connectActions)(IndexHeader),
)
