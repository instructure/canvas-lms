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

import PropTypes from 'prop-types'
import I18n from 'i18n!conversations'
import React from 'react'
import Select from '@instructure/ui-core/lib/components/Select'
import ScreenReaderContent from '@instructure/ui-core/lib/components/ScreenReaderContent'

export default class ConversationStatusFilter extends React.Component {
  static propTypes = {
    filters: PropTypes.arrayOf(
      PropTypes.shape({value: PropTypes.string.isRequired, label: PropTypes.string.isRequired})
    ).isRequired,
    onChange: PropTypes.func.isRequired,
    // This just says that defaultFilter is required and must be a filter
    defaultFilter: isAFilter,
    initialFilter: PropTypes.string
  }

  static defaultProps = {
    initialFilter: null,
    defaultFilter: 'inbox'  // Make eslint happy, but this prop is required
  }

  constructor(props) {
    super(props)
    const initialFilter = this.props.initialFilter
    const filterIsValid = this.props.filters.some(f => f.value === initialFilter)
    if (filterIsValid) {
      this.state = {selected: initialFilter}
    } else {
      // default to inbox if the url is bad
      this.state = {selected: this.props.defaultFilter}
    }
  }

  componentWillReceiveProps(nextProps) {
    const initialFilter = nextProps.initialFilter
    const filterIsValid = this.props.filters.some(f => f.value === initialFilter)
    if (filterIsValid) {
      this.setState({selected: initialFilter})
    } else {
      // default to inbox if the url is bad
      this.setState({selected: this.props.defaultFilter})
    }
  }

  onChange = (e) => {
    const filterValue = e.target.value
    this.setState({selected: filterValue})
    this.props.onChange(filterValue)
  }

  render() {
    return (
      <Select
        layout="inline"
        width="211"
        id="conversation-filter-select"
        label={<ScreenReaderContent>{ I18n.t("Filter conversations by type") }</ScreenReaderContent>}
        value={this.state.selected}
        defaultValue={this.props.defaultFilter}
        onChange={this.onChange}
      >
        {this.props.filters.map(filter => (
          <option key={filter.value} value={filter.value}>
            {filter.label}
          </option>
        ))}
      </Select>
    )
  }
}

function isAFilter(props, propName, componentName) {
  const potentialFilter = props[propName]
  if (props.filters.some(filter => (filter.value === potentialFilter))) {
    return null
  }
  return new Error(
    `Error in props for ${componentName}: ${propName} ${potentialFilter} is not a member of ${props.filters}`
  )
}
