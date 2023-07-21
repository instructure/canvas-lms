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

import Backbone from '@canvas/backbone'
import {decodeQueryString} from '@canvas/query-string-encoding'
import {FormField} from '@instructure/ui-form-field'
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const I18n = useI18nScope('ConversationStatusFilter')

export default class ConversationStatusFilter extends React.Component {
  static propTypes = {
    defaultFilter: PropTypes.string.isRequired,
    initialFilter: PropTypes.string.isRequired,
    router: PropTypes.instanceOf(Backbone.Router).isRequired,
    filters: PropTypes.objectOf((obj, key) => {
      if (typeof key !== 'string' || typeof obj[key] !== 'string') {
        return new Error("Keys and values of 'filter' prop must be strings")
      }
    }).isRequired,
  }

  constructor(props) {
    super(props)
    this.state = {selected: props.initialFilter}
    this.props.router.header.changeTypeFilter(props.initialFilter)
  }

  UNSAFE_componentWillMount() {
    this.props.router.on('route', this.handleBackboneHistory)
  }

  componentWillUnmount() {
    this.props.router.off('route', this.handleBackboneHistory)
  }

  getUrlFilter(params) {
    const types = decodeQueryString(params).filter(i => i.type !== undefined)
    if (types.length === 1 && this.validFilter(types[0].type)) {
      return types[0].type
    }
    return this.props.defaultFilter
  }

  validFilter(filter) {
    return Object.keys(this.props.filters).includes(filter)
  }

  updateBackboneState(newFilter) {
    const filter = this.validFilter(newFilter) ? newFilter : this.props.defaultFilter
    const state = {selected: filter}

    // The state needs to finished being set before we call out to backbone,
    // because that will lead to the url being changed and causing the
    // handleBackboneHistory to be triggered. If the state hasn't finished
    // being saved by this state, it will lead to this function being called
    // again.
    this.setState(state, () => this.props.router.header.changeTypeFilter(newFilter))
  }

  handleBackboneHistory = (route, params) => {
    const filterParam = params[0]
    const newState =
      filterParam === null ? this.props.defaultFilter : this.getUrlFilter(filterParam)

    // We don't need to update the backbone state if the state hasn't actually
    // changed. This occurs due to the state changing on the select option
    // being changed, and then again as the history gets updated as a result
    // of that change
    if (newState !== this.state.selected) {
      this.updateBackboneState(newState)
    }
  }

  render() {
    return (
      <FormField
        id="conversation_filter"
        label={<ScreenReaderContent>{I18n.t('Filter conversations by type')}</ScreenReaderContent>}
      >
        <select
          id="conversation_filter_select"
          onChange={e => this.updateBackboneState(e.target.value)}
          style={{
            width: '115%',
          }}
          value={this.state.selected}
        >
          {Object.keys(this.props.filters).map(key => (
            <option value={key} key={key}>
              {this.props.filters[key]}
            </option>
          ))}
        </select>
      </FormField>
    )
  }
}
