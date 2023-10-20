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
import CanvasMultiSelect from '@canvas/multi-select'
import {View} from '@instructure/ui-view'
import React from 'react'
import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import propTypes from './proptypes/sectionShape'

const I18n = useI18nScope('sections_autocomplete')

const ALL_SECTIONS_OBJ = {id: 'all', name: I18n.t('All Sections')}

function extractIds(arr) {
  return arr.map(element => element.id)
}

function sortSectionName(a, b) {
  if (a.name.toLowerCase() < b.name.toLowerCase()) return -1
  if (a.name.toLowerCase() > b.name.toLowerCase()) return 1
  return 0
}

function setDiff(first, second) {
  const diff = new Set(first)
  for (const elt of second) {
    diff.delete(elt)
  }
  return [...diff]
}

export default class SectionsAutocomplete extends React.Component {
  static propTypes = {
    sections: propTypes.sectionList.isRequired,
    selectedSections: propTypes.sectionList,
    disabled: PropTypes.bool,
    disableDiscussionOptions: PropTypes.func,
    enableDiscussionOptions: PropTypes.func,
    flashMessage: PropTypes.func,
  }

  static defaultProps = {
    selectedSections: [ALL_SECTIONS_OBJ],
    disabled: false,
    disableDiscussionOptions: () => {},
    enableDiscussionOptions: () => {},
    flashMessage: $.screenReaderFlashMessage,
  }

  state = {
    sections: this.props.sections.concat([ALL_SECTIONS_OBJ]).sort(sortSectionName),
    selectedSectionsValue: extractIds(this.props.selectedSections),
    messages: [],
  }

  UNSAFE_componentWillMount() {
    this.updateDiscussionOptions()
  }

  componentDidUpdate() {
    this.updateDiscussionOptions()
  }

  announceSectionDifference(newValues) {
    // going to assume we only add or remove one at a time. "All Sections"
    // complicates it a bit, but this still announces the right thing
    const addedId = setDiff(newValues, this.state.selectedSectionsValue)[0]
    const removedId = setDiff(this.state.selectedSectionsValue, newValues)[0]
    const changedId = addedId || removedId
    const changedValue = this.state.sections.find(section => section.id === changedId)
    if (addedId) {
      this.props.flashMessage(I18n.t('%{section} added', {section: changedValue.name}))
    } else if (removedId) {
      this.props.flashMessage(I18n.t('%{section} removed', {section: changedValue.name}))
    }
  }

  onAutocompleteChange = values => {
    this.announceSectionDifference(values)
    if (values.length === 0) {
      this.setState({
        selectedSectionsValue: [],
        messages: [{text: I18n.t('A section is required'), type: 'error'}],
      })
    } else if (this.state.selectedSectionsValue.includes(ALL_SECTIONS_OBJ.id)) {
      this.setState({
        selectedSectionsValue: values.filter(id => id !== ALL_SECTIONS_OBJ.id),
        messages: [],
      })
    } else if (values.includes(ALL_SECTIONS_OBJ.id)) {
      this.setState({selectedSectionsValue: [ALL_SECTIONS_OBJ.id], messages: []})
    } else {
      this.setState({selectedSectionsValue: values, messages: []})
    }
  }

  updateDiscussionOptions() {
    if (this.state.selectedSectionsValue.includes(ALL_SECTIONS_OBJ.id)) {
      this.props.enableDiscussionOptions()
    } else {
      this.props.disableDiscussionOptions()
    }
  }

  render() {
    // NOTE: the hidden input is used by the erb that this component is rendered in
    // If we do not have the hidden component then the erb tries to grab the element
    // and will block the submission because it does not exist
    // One day we should probably try to decouple this
    if (this.props.disabled) {
      return (
        <div id="disabled_sections_autocomplete">
          <input name="specific_sections" type="hidden" value={this.state.selectedSectionsValue} />
        </div>
      )
    }

    return (
      <View display="block" margin="0 0 large 0">
        <input name="specific_sections" type="hidden" value={this.state.selectedSectionsValue} />
        <CanvasMultiSelect
          label={I18n.t('Post to')}
          selectedOptionIds={this.state.selectedSectionsValue}
          messages={this.state.messages}
          disabled={this.props.disabled}
          onChange={this.onAutocompleteChange}
        >
          {this.state.sections.map(section => (
            <CanvasMultiSelect.Option id={section.id} key={section.id} value={section.id}>
              {section.name}
            </CanvasMultiSelect.Option>
          ))}
        </CanvasMultiSelect>
      </View>
    )
  }
}
