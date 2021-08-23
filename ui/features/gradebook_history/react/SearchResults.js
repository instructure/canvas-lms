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

import React, {Component} from 'react'
import {connect} from 'react-redux'
import {arrayOf, bool, func, node, shape, string} from 'prop-types'
import $ from 'jquery'
import '@canvas/datetime'
import I18n from 'i18n!gradebook_history'
import {View} from '@instructure/ui-view'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import {Table} from '@instructure/ui-table'
import {getHistoryNextPage} from './actions/SearchResultsActions'
import SearchResultsRow from './SearchResultsRow'

const colHeaders = [
  I18n.t('Date'),
  <ScreenReaderContent>{I18n.t('Anonymous Grading')}</ScreenReaderContent>,
  I18n.t('Student'),
  I18n.t('Grader'),
  I18n.t('Artifact'),
  I18n.t('Before'),
  I18n.t('After'),
  I18n.t('Current')
]

const nearPageBottom = () =>
  document.body.clientHeight - (window.innerHeight + window.scrollY) < 100

class SearchResultsComponent extends Component {
  static propTypes = {
    getNextPage: func.isRequired,
    fetchHistoryStatus: string.isRequired,
    caption: node.isRequired,
    historyItems: arrayOf(
      shape({
        assignment: shape({
          name: string.isRequired,
          muted: bool.isRequired
        }),
        date: string.isRequired,
        displayAsPoints: bool.isRequired,
        gradedAnonymously: bool.isRequired,
        grader: string.isRequired,
        gradeAfter: string.isRequired,
        gradeBefore: string.isRequired,
        gradeCurrent: string.isRequired,
        id: string.isRequired,
        pointsPossibleAfter: string.isRequired,
        pointsPossibleBefore: string.isRequired,
        pointsPossibleCurrent: string.isRequired,
        student: string.isRequired
      })
    ).isRequired,
    nextPage: string.isRequired,
    requestingResults: bool.isRequired
  }

  componentDidMount() {
    this.attachListeners()
  }

  componentDidUpdate(prevProps) {
    // if the page doesn't have a scrollbar, scroll event listener can't be triggered
    if (document.body.clientHeight <= window.innerHeight) {
      this.getNextPage()
    }

    if (prevProps.historyItems.length < this.props.historyItems.length) {
      $.screenReaderFlashMessage(I18n.t('More results were added at the bottom of the page.'))
    }

    this.attachListeners()
  }

  componentWillUnmount() {
    this.detachListeners()
  }

  getNextPage = () => {
    if (!this.props.requestingResults && this.props.nextPage && nearPageBottom()) {
      this.props.getNextPage(this.props.nextPage)
      this.detachListeners()
    }
  }

  attachListeners = () => {
    if (this.props.requestingResults || !this.props.nextPage) {
      return
    }

    document.addEventListener('scroll', this.getNextPage)
    window.addEventListener('resize', this.getNextPage)
  }

  detachListeners = () => {
    document.removeEventListener('scroll', this.getNextPage)
    window.removeEventListener('resize', this.getNextPage)
  }

  hasHistory() {
    return this.props.historyItems.length > 0
  }

  noResultsFound() {
    return this.props.fetchHistoryStatus === 'success' && !this.hasHistory()
  }

  showResults = () => (
    <div>
      <Table caption={this.props.caption}>
        <Table.Head>
          <Table.Row>
            {colHeaders.map(header => (
              <Table.ColHeader key={`${header}-column`}>{header}</Table.ColHeader>
            ))}
          </Table.Row>
        </Table.Head>
        <Table.Body>
          {this.props.historyItems.map(item => (
            <SearchResultsRow key={`history-items-${item.id}`} item={item} />
          ))}
        </Table.Body>
      </Table>
    </div>
  )

  showStatus = () => {
    if (this.props.requestingResults) {
      $.screenReaderFlashMessage(I18n.t('Loading more gradebook history results.'))

      return <Spinner size="small" renderTitle={I18n.t('Loading Results')} />
    }

    if (this.noResultsFound()) {
      return <Text>{I18n.t('No results found.')}</Text>
    }

    if (!this.props.requestingResults && !this.props.nextPage && this.hasHistory()) {
      return <Text>{I18n.t('No more results to load.')}</Text>
    }

    return null
  }

  render() {
    return (
      <div>
        {this.hasHistory() && this.showResults()}
        <View as="div" textAlign="center" margin="medium 0 0 0">
          {this.showStatus()}
        </View>
      </div>
    )
  }
}

const mapStateToProps = state => ({
  fetchHistoryStatus: state.history.fetchHistoryStatus || '',
  historyItems: state.history.items || [],
  nextPage: state.history.nextPage || '',
  requestingResults: state.history.loading || false
})

const mapDispatchToProps = dispatch => ({
  getNextPage: url => {
    dispatch(getHistoryNextPage(url))
  }
})

export default connect(mapStateToProps, mapDispatchToProps)(SearchResultsComponent)

export {SearchResultsComponent}
