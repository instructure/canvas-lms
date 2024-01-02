/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import PropTypes from 'prop-types'
import {map, groupBy, reject, isEmpty, find, some, union, uniq, includes, isDate} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import TokenInput, {Option as ComboboxOption} from 'react-tokeninput'

const I18n = useI18nScope('EnrollmentTermInput')

const groupByTagType = function (options) {
  const now = new Date()
  return groupBy(options, option => {
    const noStartDate = !isDate(option.startAt)
    const noEndDate = !isDate(option.endAt)
    const started = option.startAt < now
    const ended = option.endAt < now

    if ((started && !ended) || (started && noEndDate) || (!ended && noStartDate)) {
      return 'active'
    } else if (!started) {
      return 'future'
    } else if (ended) {
      return 'past'
    }
    return 'undated'
  })
}

class EnrollmentTermInput extends React.Component {
  static propTypes = {
    enrollmentTerms: PropTypes.array.isRequired,
    setSelectedEnrollmentTermIDs: PropTypes.func.isRequired,
    selectedIDs: PropTypes.array.isRequired,
  }

  handleChange = termIDs => {
    this.props.setSelectedEnrollmentTermIDs(termIDs)
  }

  handleSelect = (value, _combobox) => {
    const termIDs = map(this.props.enrollmentTerms, 'id')
    if (includes(termIDs, value)) {
      const selectedIDs = uniq(this.props.selectedIDs.concat([value]))
      this.handleChange(selectedIDs)
    }
  }

  handleRemove = termToRemove => {
    const selectedTermIDs = reject(this.props.selectedIDs, termID => termToRemove.id === termID)
    this.handleChange(selectedTermIDs)
  }

  selectableTerms = () =>
    reject(this.props.enrollmentTerms, term => includes(this.props.selectedIDs, term.id))

  filteredTagsForType = type => {
    const groupedTags = groupByTagType(this.selectableTerms())
    return (groupedTags && groupedTags[type]) || []
  }

  selectableOptions = type =>
    map(this.filteredTagsForType(type), term => this.selectableOption(term))

  selectableOption = term => (
    <ComboboxOption key={term.id} value={term.id}>
      {term.displayName}
    </ComboboxOption>
  )

  optionsForAllTypes = () => {
    if (isEmpty(this.selectableTerms())) {
      return [this.headerOption('none')]
    } else {
      return union(
        this.optionsForType('active'),
        this.optionsForType('undated'),
        this.optionsForType('future'),
        this.optionsForType('past')
      )
    }
  }

  optionsForType = optionType => {
    const header = this.headerOption(optionType)
    const options = this.selectableOptions(optionType)
    return some(options) ? union([header], options) : []
  }

  headerOption = heading => {
    const headerText = {
      active: I18n.t('Active'),
      undated: I18n.t('Undated'),
      future: I18n.t('Future'),
      past: I18n.t('Past'),
      none: I18n.t('No unassigned terms'),
    }[heading]
    return (
      <ComboboxOption className="ic-tokeninput-header" value={heading} key={heading}>
        {headerText}
      </ComboboxOption>
    )
  }

  suppressKeys = event => {
    const code = event.keyCode || event.which
    if (code === 13) {
      event.preventDefault()
    }
  }

  selectedEnrollmentTerms = () =>
    map(this.props.selectedIDs, id => {
      const term = find(this.props.enrollmentTerms, {id})
      const termForDisplay = {...term}
      termForDisplay.name = term.displayName
      return termForDisplay
    })

  render() {
    return (
      // eslint-disable-next-line jsx-a11y/no-static-element-interactions
      <div className="ic-Form-control" onKeyDown={this.suppressKeys}>
        {/* eslint-disable-next-line jsx-a11y/label-has-associated-control */}
        <label
          className="ic-Label"
          title={I18n.t('Attach terms')}
          aria-label={I18n.t('Attach terms')}
        >
          {I18n.t('Attach terms')}
        </label>
        <div className="ic-Input">
          <TokenInput
            menuContent={this.optionsForAllTypes()}
            selected={this.selectedEnrollmentTerms()}
            onChange={this.handleChange}
            onSelect={this.handleSelect}
            onRemove={this.handleRemove}
            onInput={function () {}}
            value={true}
            showListOnFocus={true}
            ref="input"
          />
        </div>
      </div>
    )
  }
}

export default EnrollmentTermInput
