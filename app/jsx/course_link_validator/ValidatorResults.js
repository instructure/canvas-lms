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

import React from 'react'
import $ from 'jquery'
import 'compiled/jquery.rails_flash_notifications'
import I18n from 'i18n!link_validator'
import _ from 'underscore'
import ValidatorResultsRow from './ValidatorResultsRow'

export default class ValidatorResults extends React.Component {
  state = {
    showUnpublished: true
  }

  toggleShowUnpublished = () => {
    this.setState({showUnpublished: !this.state.showUnpublished})
  }

  getDisplayMessage = number =>
    I18n.t(
      {one: 'Found 1 broken link', other: 'Found %{count} broken links'},
      {count: number}
    )

  render() {
    let alertMessage,
      numberofBrokenLinks = 0,
      showUnpublishedBox
    const allResults = [],
      errorMessage = I18n.t('An error occured. Please try again.'),
      noBrokenLinksMessage = I18n.t('No broken links found')

    if (this.props.error) {
      alertMessage = <div className="alert alert-error">{errorMessage}</div>
      $.flashError(errorMessage)
    } else if (!this.props.displayResults) {
      return null
    } else {
      showUnpublishedBox = (
        <div className="ic-Checkbox-group">
          <div className="ic-Form-control ic-Form-control--checkbox">
            <input
              id="show_unpublished"
              type="checkbox"
              checked={this.state.showUnpublished}
              onChange={this.toggleShowUnpublished}
            />
            <label htmlFor="show_unpublished" className="ic-Label">
              {I18n.t('Show links to unpublished content')}
            </label>
          </div>
        </div>
      )

      let results = this.props.results
      if (!this.state.showUnpublished) {
        // filter out unpublished results
        results = _.map(results, result => {
          const new_result = _.clone(result)
          new_result.invalid_links = _.filter(
            result.invalid_links,
            link => link.reason !== 'unpublished_item'
          )
          return new_result
        })
        results = _.filter(results, result => result.invalid_links.length > 0)
      }

      if (results.length === 0) {
        alertMessage = <div className="alert alert-success">{noBrokenLinksMessage}</div>
        $.screenReaderFlashMessage(noBrokenLinksMessage)
      } else {
        results.forEach(result => {
          allResults.push(<ValidatorResultsRow key={result.content_url} result={result} />)
          numberofBrokenLinks += result.invalid_links.length
        })

        alertMessage = (
          <div className="alert alert-info">{this.getDisplayMessage(numberofBrokenLinks)}</div>
        )
        $.screenReaderFlashMessage(this.getDisplayMessage(numberofBrokenLinks))
      }
    }

    return (
      <div id="all-results">
        {!!showUnpublishedBox && showUnpublishedBox}
        {alertMessage}
        {allResults}
      </div>
    )
  }
}
