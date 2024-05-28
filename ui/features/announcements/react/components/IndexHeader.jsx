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
import {Button, IconButton} from '@instructure/ui-buttons'
import {FormField} from '@instructure/ui-form-field'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Menu} from '@instructure/ui-menu'
import {
  IconArrowOpenDownLine,
  IconArrowOpenUpLine,
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
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Heading} from '@instructure/ui-heading'
import WithBreakpoints, {breakpointsShape} from '@canvas/with-breakpoints'

const I18n = useI18nScope('announcements_v2')

const instUINavEnabled = () => window.ENV?.FEATURES?.instui_nav

// Delay the search so as not to overzealously read out the number
// of search results to the user
export const SEARCH_TIME_DELAY = 750
const getFilters = () => ({
  all: instUINavEnabled() ? I18n.t('All Announcements') : I18n.t('All'),
  unread: instUINavEnabled() ? I18n.t('Unread Announcements') : I18n.t('Unread'),
})

export default class IndexHeader extends Component {
  static propTypes = {
    breakpoints: breakpointsShape.isRequired,
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
    breakpoints: {},
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

  constructor(props) {
    super(props)

    this.state = {
      selectedAnnouncementFilter: 'all',
      announcementFilterOpened: false,
    }
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

  searchInputRef = input => {
    this.searchInput = input
    if (this.props.searchInputRef) this.props.searchInputRef(input)
  }

  renderLockToggleButton(icon, label, screenReaderLabel) {
    return (
      <Button
        disabled={this.props.isBusy || this.props.selectedCount === 0}
        size="medium"
        margin={instUINavEnabled() ? '0 small 0 0' : 'auto'}
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

  renderActionButtons() {
    const buttonsContent = (
      <>
        {this.props.permissions.manage_course_content_edit &&
          !this.props.announcementsLocked &&
          (this.props.isToggleLocking
            ? this.renderLockToggleButton(
                <IconLockLine />,
                I18n.t('Lock'),
                I18n.t('Lock Selected Announcements')
              )
            : this.renderLockToggleButton(
                <IconUnlockLine />,
                I18n.t('Unlock'),
                I18n.t('Unlock Selected Announcements')
              ))}
        {this.props.permissions.manage_course_content_delete && (
          <Button
            disabled={this.props.isBusy || this.props.selectedCount === 0}
            size="medium"
            margin={instUINavEnabled() ? '0 small 0 0' : 'auto'}
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
        {this.props.permissions.create && (
          <Button
            href={`/${this.props.contextType}s/${this.props.contextId}/discussion_topics/new?is_announcement=true`}
            color="primary"
            id="add_announcement"
            renderIcon={IconPlusLine}
          >
            <ScreenReaderContent>{I18n.t('Add announcement')}</ScreenReaderContent>
            <PresentationContent>{I18n.t('Announcement')}</PresentationContent>
          </Button>
        )}
      </>
    )

    return instUINavEnabled() ? (
      buttonsContent
    ) : (
      <Flex wrap="no-wrap" gap="small" justifyItems="end">
        {buttonsContent}
      </Flex>
    )
  }

  renderSearchField() {
    return (
      <TextInput
        renderLabel={
          <ScreenReaderContent>{I18n.t('Search announcements by title')}</ScreenReaderContent>
        }
        placeholder={I18n.t('Search...')}
        renderBeforeInput={<IconSearchLine />}
        ref={this.searchInputRef}
        onChange={this.onSearch}
        name="announcements_search"
      />
    )
  }

  renderOldHeader(breakpoints) {
    const ddSize = breakpoints.desktopOnly ? '100px' : '100%'
    const containerSize = breakpoints.tablet ? 'auto' : '100%'

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
              {this.renderSearchField()}
            </Flex.Item>
            <Flex.Item>{this.renderActionButtons()}</Flex.Item>
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

    return (
      <Flex direction="column" as="div">
        <Flex.Item margin="0 0 large" overflow="hidden">
          <Flex as="div" direction="row" justifyItems="space-between">
            <Flex.Item shouldGrow={true} shouldShrink={false}>
              <Flex as="div" direction="row" justifyItems="start" alignItems="center">
                <Flex.Item margin="0 x-small 0 0">
                  <Heading level="h1">
                    {getFilters()[this.state.selectedAnnouncementFilter]}
                  </Heading>
                </Flex.Item>
                <Flex.Item>
                  <Menu
                    trigger={
                      <IconButton
                        size="small"
                        withBackground={false}
                        withBorder={false}
                        renderIcon={
                          this.state.announcementFilterOpened ? (
                            <IconArrowOpenUpLine />
                          ) : (
                            <IconArrowOpenDownLine />
                          )
                        }
                        screenReaderLabel={I18n.t('Announcement Filter')}
                      />
                    }
                    onToggle={() =>
                      this.setState({
                        announcementFilterOpened: !this.state.announcementFilterOpened,
                      })
                    }
                  >
                    <Menu.Group
                      selected={[this.state.selectedAnnouncementFilter]}
                      onSelect={(_, selected) => {
                        this.setState({selectedAnnouncementFilter: selected[0]})
                        this.props.searchAnnouncements({filter: selected[0]})
                      }}
                      label={I18n.t('View')}
                    >
                      {Object.keys(getFilters()).map(filter => (
                        <Menu.Item key={filter} value={filter}>
                          {getFilters()[filter]}
                        </Menu.Item>
                      ))}
                    </Menu.Group>
                  </Menu>
                </Flex.Item>
              </Flex>
            </Flex.Item>
            <Flex.Item overflowX="hidden" overflowY="hidden">
              {this.renderActionButtons()}
            </Flex.Item>
          </Flex>
        </Flex.Item>
        {this.renderSearchField()}
        <Flex.Item margin="large 0 0">
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
export const ConnectedIndexHeader = WithBreakpoints(
  connect(connectState, connectActions)(IndexHeader)
)
