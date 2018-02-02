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
import { func, bool } from 'prop-types'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'

import Container from '@instructure/ui-core/lib/components/Container'
import Spinner from '@instructure/ui-core/lib/components/Spinner'
import Heading from '@instructure/ui-core/lib/components/Heading'
import Text from '@instructure/ui-core/lib/components/Text'

import DiscussionRow from '../../shared/components/DiscussionRow'
import select from '../../shared/select'
import { selectPaginationState } from '../../shared/reduxPagination'
import { discussionList } from '../../shared/proptypes/discussion'
import masterCourseDataShape from '../../shared/proptypes/masterCourseData'
import propTypes from '../propTypes'
import actions from '../actions'

export default class DiscussionsIndex extends Component {
  static propTypes = {
    discussions: discussionList.isRequired,
    isLoadingDiscussions: bool.isRequired,
    hasLoadedDiscussions: bool.isRequired,
    getDiscussions: func.isRequired,
    permissions: propTypes.permissions.isRequired,
    masterCourseData: masterCourseDataShape,
  }

  static defaultProps = {
    masterCourseData: null,
  }

  componentDidMount () {
    if (!this.props.hasLoadedDiscussions) {
      this.props.getDiscussions()
    }
  }

  selectPage (page) {
    return () => this.props.getDiscussions({ page, select: true })
  }

  renderSpinner (condition, title) {
    if (condition) {
      return (
        <div style={{textAlign: 'center'}}>
          <Spinner size="small" title={title} />
          <Text size="small" as="p">{title}</Text>
        </div>
      )
    } else {
      return null
    }
  }

  renderDiscussions () {
    if (this.props.hasLoadedDiscussions) {
      return this.props.discussions.map(discussion => (
        <DiscussionRow
          key={discussion.id}
          discussion={discussion}
          canManage={this.props.permissions.manage_content}
          masterCourseData={this.props.masterCourseData}
        />
      ))
    } else {
      return null
    }
  }

  render () {
    return (
      <div className="discussions-v2__wrapper">
        <Heading>{I18n.t('Disccussions')}</Heading>
        {this.renderSpinner(this.props.isLoadingDiscussions, I18n.t('Loading Discussions'))}
        <Container margin="medium">
          {this.renderDiscussions()}
        </Container>
      </div>
    )
  }
}

const connectState = state => Object.assign({
  // other props here
}, selectPaginationState(state, 'discussions'), select(state, ['permissions', 'masterCourseData']))
const connectActions = dispatch => bindActionCreators(select(actions, ['getDiscussions']), dispatch)
export const ConnectedDiscussionsIndex = connect(connectState, connectActions)(DiscussionsIndex)
