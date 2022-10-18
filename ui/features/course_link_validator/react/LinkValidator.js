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

import $ from 'jquery'
import '@canvas/rails-flash-notifications'
import React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import ValidatorResults from './ValidatorResults'
import {number} from 'prop-types'
import {Confetti} from '@canvas/confetti'
import {Spinner} from '@instructure/ui-spinner'

const I18n = useI18nScope('link_validator')

class LinkValidator extends React.Component {
  state = {
    results: [],
    displayResults: false,
    error: false,
    showConfetti: false,
  }

  UNSAFE_componentWillMount() {
    this.setLoadingState()
    this.getResults(true)
  }

  getResults = initial_load => {
    $.ajax({
      url: ENV.validation_api_url,
      dataType: 'json',
      success: data => {
        // Keep trying until the request has been completed
        if (data.workflow_state === 'queued' || data.workflow_state === 'running') {
          setTimeout(() => {
            this.getResults()
          }, this.props.pollTimeout)
        } else if (data.workflow_state === 'completed' && data.results.version == 2) {
          this.setState({
            buttonMessage: I18n.t('Restart Link Validation'),
            buttonDisabled: false,
            results: data.results.issues,
            displayResults: true,
            error: false,
            showConfetti: !initial_load && data.results.issues.length === 0,
          })
          $('#all-results').show()
        } else {
          this.setState({
            buttonMessage: I18n.t('Start Link Validation'),
            buttonDisabled: false,
          })
          if (data.workflow_state === 'failed' && !initial_load) {
            this.setState({
              error: true,
            })
          }
        }
      },
      error: () => {
        this.setState({
          error: true,
        })
      },
    })
  }

  setLoadingState = () => {
    this.setState({
      buttonMessage: I18n.t('Loading...'),
      buttonDisabled: true,
      displayResults: false,
      results: [],
    })
  }

  startValidation = () => {
    $('#all-results').hide()

    this.setState({
      showConfetti: false,
    })

    this.setLoadingState()
    $.screenReaderFlashMessage(I18n.t('Link validation is running'))

    // You need to send a POST request to the API to initialize validation
    $.ajax({
      url: ENV.validation_api_url,
      type: 'POST',
      data: {},
      success: () => {
        const getResults = this.getResults
        setTimeout(() => {
          getResults()
        }, this.props.pollTimeoutInitial)
      },
      error: () => {
        this.setState({
          error: true,
        })
      },
    })
  }

  render() {
    return (
      <div>
        <button
          onClick={this.startValidation}
          className="Button Button--primary"
          disabled={this.state.buttonDisabled}
          style={this.state.buttonMessageStyle}
          type="button"
          data-testid="validate-button"
        >
          {this.state.buttonMessage}
        </button>
        {this.state.buttonDisabled && (
          <Spinner
            renderTitle={I18n.t('Link validation is running')}
            size="x-small"
            margin="0 0 0 x-small"
          />
        )}
        {window.ENV.VALIDATION_CONFETTI_ENABLED && this.state.showConfetti && <Confetti />}
        <ValidatorResults
          results={this.state.results}
          displayResults={this.state.displayResults}
          error={this.state.error}
        />
      </div>
    )
  }
}

LinkValidator.propTypes = {
  pollTimeout: number.isRequired,
  pollTimeoutInitial: number.isRequired,
}

export default LinkValidator
