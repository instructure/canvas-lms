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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {Component} from 'react'
import {func, bool, number} from 'prop-types'
import {connect} from 'react-redux'
import {bindActionCreators} from 'redux'

import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Pagination} from '@instructure/ui-pagination'

import AnnouncementRow from '@canvas/announcements/react/components/AnnouncementRow'
import {ConnectedIndexHeader} from './IndexHeader'
import AnnouncementEmptyState from './AnnouncementEmptyState'
import {showConfirmDelete} from './ConfirmDeleteModal'

import select from '@canvas/obj-select'
import {selectPaginationState} from '@canvas/pagination/redux/actions'
import {announcementList} from '@canvas/announcements/react/proptypes/announcement'
import masterCourseDataShape from '@canvas/courses/react/proptypes/masterCourseData'
import actions from '../actions'
import propTypes from '../propTypes'

const I18n = useI18nScope('announcements_v2')

export default class AnnouncementsIndex extends Component {
  static propTypes = {
    announcements: announcementList.isRequired,
    announcementsPage: number.isRequired,
    announcementsLastPage: number.isRequired,
    isLoadingAnnouncements: bool.isRequired,
    hasLoadedAnnouncements: bool.isRequired,
    isCourseContext: bool.isRequired,
    getAnnouncements: func.isRequired,
    announcementSelectionChangeStart: func.isRequired,
    permissions: propTypes.permissions.isRequired,
    masterCourseData: masterCourseDataShape,
    deleteAnnouncements: func.isRequired,
    toggleAnnouncementsLock: func.isRequired,
    announcementsLocked: bool.isRequired,
  }

  static defaultProps = {
    masterCourseData: null,
  }

  componentDidMount() {
    if (!this.props.hasLoadedAnnouncements) {
      this.props.getAnnouncements()
    }
  }

  onManageAnnouncement = (e, {action, id, lock}) => {
    switch (action) {
      case 'delete':
        showConfirmDelete({
          selectedCount: 1,
          modalRef: modal => {
            this.deleteModal = modal
          },
          onConfirm: () => {
            this.props.deleteAnnouncements(id)
            if (this.searchInput) this.searchInput.focus()
          },
        })
        break
      case 'lock':
        this.props.toggleAnnouncementsLock(id, lock)
        break
      default:
        break
    }
  }

  selectPage(page) {
    return () => this.props.getAnnouncements({page, select: true})
  }

  renderEmptyAnnouncements() {
    if (this.props.hasLoadedAnnouncements && !this.props.announcements.length) {
      return <AnnouncementEmptyState canCreate={this.props.permissions.create} />
    } else {
      return null
    }
  }

  renderSpinner(condition, title) {
    if (condition) {
      return (
        <div style={{textAlign: 'center'}}>
          <Spinner size="small" renderTitle={title} />
          <Text size="small" as="p">
            {title}
          </Text>
        </div>
      )
    } else {
      return null
    }
  }

  renderAnnouncements() {
    if (this.props.hasLoadedAnnouncements && this.props.announcements.length) {
      return (
        <View margin="medium">
          <ScreenReaderContent>
            <Heading level="h2">{I18n.t('Announcements List')}</Heading>
          </ScreenReaderContent>
          {this.props.announcements.map(announcement => (
            <AnnouncementRow
              key={announcement.id}
              announcement={announcement}
              canManage={
                this.props.permissions.manage_course_content_edit && announcement.permissions.update
              }
              canDelete={this.props.permissions.manage_course_content_delete}
              masterCourseData={this.props.masterCourseData}
              onSelectedChanged={this.props.announcementSelectionChangeStart}
              onManageMenuSelect={this.onManageAnnouncement}
              canHaveSections={this.props.isCourseContext}
              announcementsLocked={this.props.announcementsLocked}
            />
          ))}
        </View>
      )
    } else {
      return null
    }
  }

  renderPageButton(page) {
    return (
      <Pagination.Page
        key={page}
        onClick={this.selectPage(page)}
        current={page === this.props.announcementsPage}
      >
        <ScreenReaderContent>{I18n.t('Page %{pageNum}', {pageNum: page})}</ScreenReaderContent>
        <span aria-hidden="true">{page}</span>
      </Pagination.Page>
    )
  }

  renderPagination() {
    const pages = Array.from(Array(this.props.announcementsLastPage)).map((_, i) =>
      this.renderPageButton(i + 1)
    )
    if (pages.length > 1 && !this.props.isLoadingAnnouncements) {
      return (
        <Pagination
          variant="compact"
          labelNext={I18n.t('Next Announcements Page')}
          labelPrev={I18n.t('Previous Announcements Page')}
        >
          {pages}
        </Pagination>
      )
    }
    return null
  }

  render() {
    return (
      <div className="announcements-v2__wrapper">
        <ScreenReaderContent>
          <Heading level="h1">{I18n.t('Announcements')}</Heading>
        </ScreenReaderContent>
        <ConnectedIndexHeader
          searchInputRef={c => {
            this.searchInput = c
          }}
        />
        {this.renderSpinner(this.props.isLoadingAnnouncements, I18n.t('Loading Announcements'))}
        {this.renderEmptyAnnouncements()}
        {this.renderAnnouncements()}
        {this.renderPagination()}
      </div>
    )
  }
}

const connectState = state => ({
  isCourseContext: state.contextType === 'course',
  ...selectPaginationState(state, 'announcements'),
  ...select(state, ['permissions', 'masterCourseData', 'announcementsLocked']),
})
const connectActions = dispatch =>
  bindActionCreators(
    select(actions, [
      'getAnnouncements',
      'announcementSelectionChangeStart',
      'deleteAnnouncements',
      'toggleAnnouncementsLock',
    ]),
    dispatch
  )

export const ConnectedAnnouncementsIndex = connect(connectState, connectActions)(AnnouncementsIndex)
