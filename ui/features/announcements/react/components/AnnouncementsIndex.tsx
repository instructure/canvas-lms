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

import {useScope as createI18nScope} from '@canvas/i18n'
import React, {Component} from 'react'
import {func, bool, number} from 'prop-types'
import {connect} from 'react-redux'
import {bindActionCreators} from 'redux'

import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Pagination} from '@instructure/ui-pagination'

import AnnouncementRow from '@canvas/announcements/react/components/AnnouncementRow'
import AnnouncementEmptyState from './AnnouncementEmptyState'
import {showConfirmDelete} from './ConfirmDeleteModal'

import select from '@canvas/obj-select'
import {selectPaginationState} from '@canvas/pagination/redux/actions'
import {announcementList} from '@canvas/announcements/react/proptypes/announcement'
import masterCourseDataShape from '@canvas/courses/react/proptypes/masterCourseData'
import actions from '../actions'
import propTypes from '../propTypes'
import {ConnectedIndexHeader} from './IndexHeader'
import TopNavPortalWithDefaults from '@canvas/top-navigation/react/TopNavPortalWithDefaults'

const I18n = createI18nScope('announcements_v2')

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
    // @ts-expect-error TS2339 (typescriptify)
    if (!this.props.hasLoadedAnnouncements) {
      // @ts-expect-error TS2339 (typescriptify)
      this.props.getAnnouncements()
    }
  }

  // @ts-expect-error TS7006,TS7031 (typescriptify)
  onManageAnnouncement = (_e, {action, id, lock}) => {
    switch (action) {
      case 'delete':
        showConfirmDelete({
          selectedCount: 1,
          // @ts-expect-error TS7006 (typescriptify)
          modalRef: modal => {
            // @ts-expect-error TS2339 (typescriptify)
            this.deleteModal = modal
          },
          onConfirm: () => {
            // @ts-expect-error TS2339 (typescriptify)
            this.props.deleteAnnouncements(id)
            // @ts-expect-error TS2339 (typescriptify)
            if (this.searchInput) this.searchInput.focus()
          },
        })
        break
      case 'lock':
        // @ts-expect-error TS2339 (typescriptify)
        this.props.toggleAnnouncementsLock(id, lock)
        break
      default:
        break
    }
  }

  // @ts-expect-error TS7006 (typescriptify)
  selectPage(page) {
    // @ts-expect-error TS2339 (typescriptify)
    return () => this.props.getAnnouncements({page, select: true})
  }

  renderEmptyAnnouncements() {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.hasLoadedAnnouncements && !this.props.announcements.length) {
      // @ts-expect-error TS2339 (typescriptify)
      return <AnnouncementEmptyState canCreate={this.props.permissions.create} />
    } else {
      return null
    }
  }

  // @ts-expect-error TS7006 (typescriptify)
  renderSpinner(condition, title) {
    if (condition) {
      return (
        <div style={{textAlign: 'center'}}>
          <Spinner size="small" delay={500} renderTitle={title} />
        </div>
      )
    } else {
      return null
    }
  }

  renderAnnouncements() {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.hasLoadedAnnouncements && this.props.announcements.length) {
      return (
        <View margin="medium">
          <ScreenReaderContent>
            <Heading level="h2">{I18n.t('Announcements List')}</Heading>
          </ScreenReaderContent>
          {/* @ts-expect-error TS2339,TS7006 (typescriptify) */}
          {this.props.announcements.map(announcement => (
            <AnnouncementRow
              key={announcement.id}
              announcement={announcement}
              canManage={
                // @ts-expect-error TS2339 (typescriptify)
                this.props.permissions.manage_course_content_edit && announcement.permissions.update
              }
              // @ts-expect-error TS2339 (typescriptify)
              canDelete={this.props.permissions.manage_course_content_delete}
              // @ts-expect-error TS2339 (typescriptify)
              masterCourseData={this.props.masterCourseData}
              // @ts-expect-error TS2339 (typescriptify)
              onSelectedChanged={this.props.announcementSelectionChangeStart}
              onManageMenuSelect={this.onManageAnnouncement}
              // @ts-expect-error TS2339 (typescriptify)
              canHaveSections={this.props.isCourseContext}
              // @ts-expect-error TS2339 (typescriptify)
              announcementsLocked={this.props.announcementsLocked}
            />
          ))}
        </View>
      )
    } else {
      return null
    }
  }

  // @ts-expect-error TS7006 (typescriptify)
  renderPageButton(page) {
    return (
      <Pagination.Page
        key={page}
        onClick={this.selectPage(page)}
        // @ts-expect-error TS2339 (typescriptify)
        current={page === this.props.announcementsPage}
      >
        <ScreenReaderContent>{I18n.t('Page %{pageNum}', {pageNum: page})}</ScreenReaderContent>
        <span aria-hidden="true">{page}</span>
      </Pagination.Page>
    )
  }

  renderPagination() {
    // @ts-expect-error TS2339 (typescriptify)
    const pages = Array.from(Array(this.props.announcementsLastPage)).map((_, i) =>
      this.renderPageButton(i + 1),
    )
    // @ts-expect-error TS2339 (typescriptify)
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
      <>
        {window.ENV.FEATURES?.instui_nav && (
          <TopNavPortalWithDefaults
            currentPageName={I18n.t('Announcements')}
            useStudentView={true}
          />
        )}
        <div className="announcements-v2__wrapper">
          <ScreenReaderContent>
            <Heading level="h1">{I18n.t('Announcements')}</Heading>
          </ScreenReaderContent>
          <ConnectedIndexHeader
            // @ts-expect-error TS7006 (typescriptify)
            searchInputRef={c => {
              // @ts-expect-error TS2339 (typescriptify)
              this.searchInput = c
            }}
          />
          {/* @ts-expect-error TS2339 (typescriptify) */}
          {this.renderSpinner(this.props.isLoadingAnnouncements, I18n.t('Loading Announcements'))}
          {this.renderEmptyAnnouncements()}
          {this.renderAnnouncements()}
          {this.renderPagination()}
        </div>
      </>
    )
  }
}

// @ts-expect-error TS7006 (typescriptify)
const connectState = state => ({
  isCourseContext: state.contextType === 'course',
  ...selectPaginationState(state, 'announcements'),
  ...select(state, ['permissions', 'masterCourseData', 'announcementsLocked']),
})
// @ts-expect-error TS7006 (typescriptify)
const connectActions = dispatch =>
  bindActionCreators(
    // @ts-expect-error TS2769 (typescriptify)
    select(actions, [
      'getAnnouncements',
      'announcementSelectionChangeStart',
      'deleteAnnouncements',
      'toggleAnnouncementsLock',
    ]),
    dispatch,
  )

export const ConnectedAnnouncementsIndex = connect(connectState, connectActions)(AnnouncementsIndex)
