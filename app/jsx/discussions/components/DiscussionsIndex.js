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
import { func, bool, number } from 'prop-types'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'

import Spinner from '@instructure/ui-core/lib/components/Spinner'
import Heading from '@instructure/ui-core/lib/components/Heading'
import Text from '@instructure/ui-core/lib/components/Text'


import select from '../../shared/select'
import { selectPaginationState } from '../../shared/reduxPagination'
import propTypes from '../propTypes'
import actions from '../actions'

export default class DiscussionsIndex extends Component {
  static propTypes = {
    discussions: propTypes.discussionList.isRequired,
    discussionsPage: number.isRequired,
    isLoadingDiscussions: bool.isRequired,
    hasLoadedDiscussions: bool.isRequired,
    getDiscussions: func.isRequired,
  }

  componentDidMount () {
    if (!this.props.hasLoadedDiscussions) {
      this.props.getDiscussions()
    }
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

  renderAnnouncements () {
    if (this.props.hasLoadedDiscussions) {
      return (
        <Text as="p">
          {I18n.t('%{count} items on page %{page}', {
            count: this.props.discussions.length,
            page: this.props.discussionsPage,
          })}
        </Text>
      )
    } else {
      return null
    }
  }

  render () {
    return (
      <div className="discussions-v2__wrapper">
        <Heading>{I18n.t('Disccussions')}</Heading>
        {this.renderSpinner(this.props.isLoadingDiscussions, I18n.t('Loading Discussions'))}
        {this.renderAnnouncements()}
      </div>
    )
  }
}

const connectState = state => Object.assign({
  // other props here
}, selectPaginationState(state, 'discussions'))
const connectActions = dispatch => bindActionCreators(select(actions, ['getDiscussions']), dispatch)
export const ConnectedDiscussionsIndex = connect(connectState, connectActions)(DiscussionsIndex)
