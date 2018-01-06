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

import I18n from 'i18n!announcements_v2'
import React, { Component } from 'react'
import { func, bool, number } from 'prop-types'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'

import Spinner from 'instructure-ui/lib/components/Spinner'
import Heading from 'instructure-ui/lib/components/Heading'
import Typography from 'instructure-ui/lib/components/Typography'

import select from '../../shared/select'
import { selectPaginationState } from '../../shared/reduxPagination'
import propTypes from '../propTypes'
import actions from '../actions'

export default class AnnouncementsIndex extends Component {
  static propTypes = {
    announcements: propTypes.announcementList.isRequired,
    announcementsPage: number.isRequired,
    isLoadingAnnouncements: bool.isRequired,
    hasLoadedAnnouncements: bool.isRequired,
    getAnnouncements: func.isRequired,
  }

  componentDidMount () {
    if (!this.props.hasLoadedAnnouncements) {
      this.props.getAnnouncements()
    }
  }

  renderSpinner (condition, title) {
    if (condition) {
      return (
        <div style={{textAlign: 'center'}}>
          <Spinner size="small" title={title} />
          <Typography size="small" as="p">{title}</Typography>
        </div>
      )
    } else {
      return null
    }
  }

  renderAnnouncements () {
    if (this.props.hasLoadedAnnouncements) {
      return (
        <Typography as="p">
          {I18n.t('%{count} items on page %{page}', {
            count: this.props.announcements.length,
            page: this.props.announcementsPage,
          })}
        </Typography>
      )
    } else {
      return null
    }
  }

  render () {
    return (
      <div className="announcements-v2__wrapper">
        <Heading>{I18n.t('Announcements')}</Heading>
        {this.renderSpinner(this.props.isLoadingAnnouncements, I18n.t('Loading Announcements'))}
        {this.renderAnnouncements()}
      </div>
    )
  }
}

const connectState = state => Object.assign({
  // other props here
}, selectPaginationState(state, 'announcements'))
const connectActions = dispatch => bindActionCreators(select(actions, ['getAnnouncements']), dispatch)
export const ConnectedAnnouncementsIndex = connect(connectState, connectActions)(AnnouncementsIndex)
