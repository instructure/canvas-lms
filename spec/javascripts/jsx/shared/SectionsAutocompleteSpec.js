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
import {shallow} from 'enzyme'
import SectionsAutocomplete from 'jsx/shared/SectionsAutocomplete'
import Autocomplete from 'instructure-ui/lib/components/Autocomplete'

QUnit.module('Sections Autocomplete')

const defaultProps = () => ({
  sections: [{
    id: '1',
    name: 'awesome section',
  }],
})

test('renders SectionsAutocomplete', () => {
  const wrapper = shallow(<SectionsAutocomplete {...defaultProps()}/>)
  const renderedAutocomplete = wrapper.find(Autocomplete)
  equal(renderedAutocomplete.length, 1)
})

test('rendered sectionAutocomplete containes the all sections option', () => {
  const wrapper = shallow(<SectionsAutocomplete {...defaultProps()}/>)
  equal(wrapper.instance().state.sections.filter((section) => section.name === 'All my sections').length, 1)
})

test('remove the all sections option when individual one is added', () => {
  const wrapper = shallow(<SectionsAutocomplete {...defaultProps()}/>)
  wrapper.instance().onAutocompleteChange(null, [{id: "3", value: "other thing"}])
  deepEqual(wrapper.instance().state.selectedSectionsValue, ["3"])
})

test('removing all sections shows an error message', () => {
  const wrapper = shallow(<SectionsAutocomplete {...defaultProps()}/>)
  wrapper.instance().onAutocompleteChange(null, [])
  deepEqual(wrapper.instance().state.messages, [{ text: 'A section is required', type: 'error' }])
})

test('remove the all sections except the all option when all section is added', () => {
  const wrapper = shallow(<SectionsAutocomplete {...defaultProps()}/>)
  wrapper.instance().onAutocompleteChange(null, [{id: "3", value: "other thing"}])
  wrapper.instance().onAutocompleteChange(null, [{id: "3", value: "other thing"}, {id: "all", value: "All my sections"}])
  deepEqual(wrapper.instance().state.selectedSectionsValue, ["all"])
})

test('add sections accordingly', () => {
  const wrapper = shallow(<SectionsAutocomplete {...defaultProps()}/>)
  wrapper.instance().onAutocompleteChange(null, [{id: "3", value: "other thing"}])
  wrapper.instance().onAutocompleteChange(null, [{id: "3", value: "other thing"}, {id: "1", value: "awesome section"}])
  deepEqual(wrapper.instance().state.selectedSectionsValue, ["3", "1"])
})
