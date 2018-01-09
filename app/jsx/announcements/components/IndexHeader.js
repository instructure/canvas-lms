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
import { string } from 'prop-types'
import { connect } from 'react-redux'

// we'll need actions in here once we add lock/etc buttons
// import { bindActionCreators } from 'redux'

import Button from '@instructure/ui-core/lib/components/Button'
import Container from '@instructure/ui-core/lib/components/Container'
import IconPlus from 'instructure-icons/lib/Line/IconPlusLine'

import select from '../../shared/select'
import ExternalFeedsTray from './ExternalFeedsTray'
import propTypes from '../propTypes'

// disable suggestion to make functional component, this component will get more complex soon
// eslint-disable-next-line
export default class IndexHeader extends Component {
  static propTypes = {
    courseId: string.isRequired,
    permissions: propTypes.permissions.isRequired,
    atomFeedUrl: string,
  }

  static defaultProps = {
    atomFeedUrl: null,
   }

  render () {
    return (
      <Container>
        <Container margin="0 0 medium" display="block" textAlign="end">
          {this.props.permissions.create && <Button
            href={`/courses/${this.props.courseId}/discussion_topics/new?is_announcement=true`}
            variant="primary"
            size="medium"
            id="add_announcement"
          >
            <IconPlus />
            {I18n.t('Announcement')}
          </Button>}
        </Container>
        <ExternalFeedsTray atomFeedUrl={this.props.atomFeedUrl} />
      </Container>
    )
  }
}

const connectState = state => Object.assign({
  // props derived from state here
}, select(state, ['courseId', 'permissions', 'atomFeedUrl']))
// const connectActions = dispatch => bindActionCreators(select(actions, ['getAnnouncements']), dispatch)
export const ConnectedIndexHeader = connect(connectState)(IndexHeader)
