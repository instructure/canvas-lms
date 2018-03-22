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
import Autocomplete from '@instructure/ui-core/lib/components/Autocomplete'
import Container from '@instructure/ui-core/lib/components/Container'
import AccessibleContent from '@instructure/ui-core/lib/components/AccessibleContent'
import React from 'react'
import I18n from 'i18n!sections_autocomplete'
import PropTypes from 'prop-types'
import propTypes from './proptypes/sectionShape'

const ALL_SECTIONS_OBJ = {id: 'all', name: I18n.t('All Sections')}

function extractIds(arr) {
  return arr.map((element) => element.id)
}

export default class SectionsAutocomplete extends React.Component {
  static propTypes = {
    sections: propTypes.sectionList.isRequired,
    selectedSections: propTypes.sectionList,
    disabled: PropTypes.bool,
    disableDiscussionOptions: PropTypes.func,
    enableDiscussionOptions: PropTypes.func
  }
  static defaultProps = {
    selectedSections: [ALL_SECTIONS_OBJ],
    disabled: false,
    disableDiscussionOptions: (() => {}),
    enableDiscussionOptions: (() => {})
  }

  state = {
    sections: this.props.sections.concat([ALL_SECTIONS_OBJ]),
    selectedSectionsValue: extractIds(this.props.selectedSections),
    messages: []
  }

  componentWillMount() {
    this.updateDiscussionOptions()
  }

  componentDidUpdate() {
    this.updateDiscussionOptions()
  }

  onAutocompleteChange = (_, value) => {
    if(!value.length) {
      this.setState({selectedSectionsValue: [], messages: [{ text: I18n.t('A section is required'), type: 'error' }]})
    } else if (this.state.selectedSectionsValue.includes(ALL_SECTIONS_OBJ.id)) {
      this.setState({
        selectedSectionsValue: extractIds(value.filter((section) => section.id !== ALL_SECTIONS_OBJ.id)),
        messages: []
      })
    } else if (extractIds(value).includes(ALL_SECTIONS_OBJ.id)) {
      this.setState({selectedSectionsValue: [ALL_SECTIONS_OBJ.id], messages: []})
    } else {
      this.setState({selectedSectionsValue: extractIds(value), messages: []})
    }
  }

  updateDiscussionOptions() {
    if (this.state.selectedSectionsValue.includes(ALL_SECTIONS_OBJ.id)) {
      this.props.enableDiscussionOptions()
    } else {
      this.props.disableDiscussionOptions()
    }
  }

  render () {
    return (
      <Container
        display="block"
        margin="0 0 large 0"
      >
        <input
          name="specific_sections"
          type="hidden"
          value={this.state.selectedSectionsValue}/>
        <Autocomplete
          label={I18n.t('Post to')}
          selectedOption={this.state.selectedSectionsValue}
          messages={this.state.messages}
          multiple
          disabled={this.props.disabled}
          onChange={this.onAutocompleteChange}
          formatSelectedOption={(tag) => (
            <AccessibleContent alt={I18n.t(`Remove %{label}`, {label: tag.label})}>{tag.label}</AccessibleContent>
          )}
        >
          {this.state.sections.map((section) => (
            <option key={section.id} value={section.id}>
              {section.name}
            </option>
          ))}
        </Autocomplete>
      </Container>
    )
  }
}
