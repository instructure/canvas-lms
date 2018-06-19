/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import React, { Component } from 'react'
import Pagination, {PaginationButton} from '@instructure/ui-core/lib/components/Pagination'
import Spinner from '@instructure/ui-core/lib/components/Spinner'
import { array, func, string, shape, oneOf } from 'prop-types'
import I18n from 'i18n!account_course_user_search'
import Alert from '@instructure/ui-alerts/lib/components/Alert'

const linkPropType = shape({
  url: string.isRequired,
  page: string.isRequired
}).isRequired


export default class SearchMessage extends Component {

  static propTypes = {
    collection: shape({
      data: array.isRequired,
      links: shape({
        current: linkPropType,
        last: linkPropType
      })
    }).isRequired,
    setPage: func.isRequired,
    noneFoundMessage: string.isRequired,
    getLiveAlertRegion: func,
    dataType: oneOf(['Course', 'User']).isRequired
  }

  static defaultProps = {
    getLiveAlertRegion () {
      return document.getElementById('flash_screenreader_holder')
    }
  }

  constructor (props) {
    super(props);
    this.state = {
      pageNumbers: []
    }

  }

  componentWillReceiveProps (nextProps) {
    if (!nextProps.collection.loading) {
      const newState = {
        hasLoaded: true
      };

      if (nextProps.collection.links.last) {
        newState.lastKnownPage = nextProps.collection.links.last;
      } else {
        newState.lastKnownPage = nextProps.collection.links.next;
        newState.lastUnknown = true
      }
      if (this.state.pageNumbers.length !== Number(newState.lastKnownPage.page)) {
        newState.pageNumbers = Array.from(Array(Number(newState.lastKnownPage.page)))
      }
      newState.currentPage = this.state.pageBecomingCurrent || Number(nextProps.collection.links.current.page)

      if (this.state.pageBecomingCurrent) {
        newState.pageBecomingCurrent = null
      }

      this.setState(newState)
    }


  }

  handleSetPage = (page) => {
    this.setState({
      pageBecomingCurrent: page,
    }, () => {
      this.props.setPage(page);
    });
  }

  renderSearchDoneAlert = (isLoading, message) => {
    if (isLoading) {
      return null;
    }
    return (
      <Alert screenReaderOnly liveRegion={this.props.getLiveAlertRegion}>
        {message}
      </Alert>
    );
  };


  render () {
    const { collection, noneFoundMessage } = this.props
    let resultsFoundMessage = ''
    switch (this.props.dataType) {
      case 'User':
        resultsFoundMessage = I18n.t('User results updated.')
        break;
      case 'Course':
        resultsFoundMessage = I18n.t('Course results updated.');
        break;
      default:
        break;
    }
    const errorLoadingMessage = I18n.t('There was an error with your query; please try a different search')

    if (collection.error) {
      return (
        <div className="text-center pad-box">
          <div className="alert alert-error">
            {this.renderSearchDoneAlert(collection.loading, errorLoadingMessage)}
            {errorLoadingMessage}
          </div>
        </div>
      )
    } else if (!collection.data.length) {
      return (
        <div className="text-center pad-box">
          {this.renderSearchDoneAlert(collection.loading, noneFoundMessage)}
          <div className="alert alert-info">{noneFoundMessage}</div>
        </div>
      )
    } else if (collection.links) {
      return (
        <div>
          {this.renderSearchDoneAlert(collection.loading, resultsFoundMessage)}
          <Pagination
            variant="compact"
            labelNext={I18n.t('Next Page')}
            labelPrev={I18n.t('Previous Page')}
          >
            {this.state.pageNumbers.map((v, i) => {
              const pageNumber = i + 1
              const isCurrent = (this.state.pageBecomingCurrent) ?
                              pageNumber === this.state.pageBecomingCurrent :
                              pageNumber === this.state.currentPage;
              return (
                <PaginationButton
                  key={pageNumber}
                  onClick={() => this.handleSetPage(pageNumber)}
                  current={isCurrent}
                >
                    { isCurrent && this.state.pageBecomingCurrent ? (
                      <Spinner size="x-small" title={I18n.t('Loading...')} />
                    ) : (
                      I18n.n(pageNumber)
                    )}
                </PaginationButton>
              )
            }).concat(this.state.lastUnknown
              ? <span key="page-count-is-unknown-indicator" aria-hidden>...</span>
              : []
            )}
          </Pagination>
        </div>
      )
    } else {
      return (
        <div>
          {this.renderSearchDoneAlert(collection.loading, resultsFoundMessage)}
        </div>
      )
    }
  }
}



