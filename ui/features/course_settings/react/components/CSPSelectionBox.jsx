/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'
import {bool, func, shape, string} from 'prop-types'
import {Checkbox} from '@instructure/ui-checkbox'
import {Spinner} from '@instructure/ui-spinner'
import {Tooltip} from '@instructure/ui-tooltip'

import {showFlashError} from '@canvas/alerts/react/FlashAlert'

const I18n = useI18nScope('course_settings')

export default class CSPSelectionBox extends Component {
  static propTypes = {
    apiLibrary: shape({
      get: func.isRequired,
      put: func.isRequired,
    }).isRequired,
    courseId: string.isRequired,
    canManage: bool,
  }

  static defaultProps = {
    canManage: false,
  }

  state = {
    disabled: false,
    loading: true,
    failedToLoad: false,
  }

  componentDidMount() {
    this.props.apiLibrary
      .get(`/api/v1/courses/${this.props.courseId}/csp_settings`)
      .then(response => {
        this.setState({
          disabled: !response.data.enabled,
          loading: false,
        })
      })
      .catch(() => {
        this.setState({failedToLoad: true, loading: false})
      })
  }

  handleChange = e => {
    const initialState = this.state.disabled
    const checked = e.currentTarget.checked
    this.setState(
      {
        disabled: checked,
      },
      () => {
        this.props.apiLibrary
          .put(`/api/v1/courses/${this.props.courseId}/csp_settings`, {
            status: checked ? 'disabled' : 'enabled',
          })
          .then(response => {
            this.setState({
              disabled: !response.data.enabled,
            })
          })
          .catch(() => {
            // Something bad happened, revert to the original value
            this.setState(
              {
                disabled: initialState,
              },
              showFlashError(I18n.t('Saving the CSP status failed, please try again.'))
            )
          })
      }
    )
  }

  render() {
    if (!this.state.loading && this.state.failedToLoad) {
      return <div>{I18n.t('Failed to load CSP information, try refreshing the page.')}</div>
    }

    const checkbox = (
      <Checkbox
        label={I18n.t('Disable Content Security Policy')}
        checked={this.state.disabled}
        onChange={this.handleChange}
        disabled={!this.props.canManage}
      />
    )

    return (
      <div>
        {this.state.loading ? (
          <Spinner renderTitle={I18n.t('Loading')} size="x-small" />
        ) : this.props.canManage ? (
          checkbox
        ) : (
          <Tooltip
            color="primary"
            renderTip={I18n.t('Only account administrators can change this setting.')}
            placement="start"
          >
            {checkbox}
          </Tooltip>
        )}
      </div>
    )
  }
}
