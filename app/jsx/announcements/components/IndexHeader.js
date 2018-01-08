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
import { string, func } from 'prop-types'
import { connect } from 'react-redux'
import { debounce } from 'lodash'

import { bindActionCreators } from 'redux'

import Button from '@instructure/ui-core/lib/components/Button'
import TextInput from '@instructure/ui-core/lib/components/TextInput'
import Grid, { GridCol, GridRow } from '@instructure/ui-core/lib/components/Grid'
import Container from '@instructure/ui-core/lib/components/Container'
import IconPlus from 'instructure-icons/lib/Line/IconPlusLine'
import IconSearchLine from 'instructure-icons/lib/Line/IconSearchLine'
import ScreenReaderContent from '@instructure/ui-core/lib/components/ScreenReaderContent'
import Select from '@instructure/ui-core/lib/components/Select'

import select from '../../shared/select'
import ExternalFeedsTray from './ExternalFeedsTray'
import propTypes from '../propTypes'
import actions from '../actions'

export const SEARCH_TIME_DELAY = 300
const filters = {
  all: I18n.t('All'),
  unread: I18n.t('Unread')
}
export default class IndexHeader extends Component {
  static propTypes = {
    courseId: string.isRequired,
    permissions: propTypes.permissions.isRequired,
    atomFeedUrl: string,
    searchAnnouncements: func.isRequired,
  }

  static defaultProps = {
    atomFeedUrl: null,
  }

  onSearch = debounce(() => {
    const term = this.searchInput.value
    this.props.searchAnnouncements({ term })
  }, SEARCH_TIME_DELAY, {
    leading: false,
    trailing: true,
  })

  render () {
    return (
      <Container>
        <Container margin="0 0 medium" display="block">
          <Grid>
            <GridRow hAlign="space-between">
              <GridCol width={2}>
                <Select
                  name="filter-dropdown"
                  onChange={(e) => this.props.searchAnnouncements({filter: e.target.value})}
                  size="medium"
                  label={<ScreenReaderContent>{I18n.t('Announcement Filter')}</ScreenReaderContent>}>
                  {
                    Object.keys(filters).map((filter) => (<option key={filter} value={filter}>{filters[filter]}</option>))
                  }
                </Select>
              </GridCol>
              <GridCol width={4}>
                <TextInput
                  label={<ScreenReaderContent>{I18n.t('Search')}</ScreenReaderContent>}
                  placeholder={I18n.t('Search')}
                  icon={() => <IconSearchLine />}
                  ref={(c) => { this.searchInput = c }}
                  onChange={this.onSearch}
                  name="announcements_search"
                />
              </GridCol>
              <GridCol width={6} textAlign="end">
                {this.props.permissions.create &&
                  <Button
                    href={`/courses/${this.props.courseId}/discussion_topics/new?is_announcement=true`}
                    variant="primary"
                    id="add_announcement"
                  >
                  <IconPlus />
                  {I18n.t('Announcement')}
                </Button>}
              </GridCol>
            </GridRow>
          </Grid>
        </Container>
        <ExternalFeedsTray atomFeedUrl={this.props.atomFeedUrl} />
      </Container>
    )
  }
}

const connectState = state => Object.assign({
  // props derived from state here
}, select(state, ['courseId', 'permissions', 'atomFeedUrl']))
const connectActions = dispatch => bindActionCreators(select(actions, ['searchAnnouncements']), dispatch)
export const ConnectedIndexHeader = connect(connectState, connectActions)(IndexHeader)
