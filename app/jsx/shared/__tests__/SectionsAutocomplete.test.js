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
import SectionsAutocomplete from '../SectionsAutocomplete'

describe('Sections Autocomplete', () => {
  const defaultProps = () => ({
    sections: [{id: '1', name: 'awesome section'}]
  })

  it('renders SectionsAutocomplete', () => {
    const wrapper = shallow(<SectionsAutocomplete {...defaultProps()} />)
    const renderedAutocomplete = wrapper.find('Select')
    expect(renderedAutocomplete).toHaveLength(1)
  })

  it('rendered sectionAutocomplete contains the "all sections" option', () => {
    const wrapper = shallow(<SectionsAutocomplete {...defaultProps()} />)
    expect(
      wrapper.instance().state.sections.filter(section => section.name === 'All Sections')
    ).toHaveLength(1)
  })

  it('removes the all sections option when individual one is added', () => {
    const wrapper = shallow(<SectionsAutocomplete {...defaultProps()} />)
    wrapper.instance().onAutocompleteChange(null, [{id: '3', value: 'other thing'}])
    expect(wrapper.instance().state.selectedSectionsValue).toEqual(['3'])
  })

  it('shows an error message when removing all sections', () => {
    const wrapper = shallow(<SectionsAutocomplete {...defaultProps()} />)
    wrapper.instance().onAutocompleteChange(null, [])
    expect(wrapper.instance().state.messages).toEqual([
      {text: 'A section is required', type: 'error'}
    ])
  })

  it('removes the all sections except the all option when all section is added', () => {
    const wrapper = shallow(<SectionsAutocomplete {...defaultProps()} />)
    wrapper.instance().onAutocompleteChange(null, [{id: '3', value: 'other thing'}])
    wrapper.instance().onAutocompleteChange(null, [
      {id: '3', value: 'other thing'},
      {id: 'all', value: 'All Sections'}
    ])
    expect(wrapper.instance().state.selectedSectionsValue).toEqual(['all'])
  })

  it('adds sections accordingly', () => {
    const wrapper = shallow(<SectionsAutocomplete {...defaultProps()} />)
    wrapper.instance().onAutocompleteChange(null, [{id: '3', value: 'other thing'}])
    wrapper.instance().onAutocompleteChange(null, [
      {id: '3', value: 'other thing'},
      {id: '1', value: 'awesome section'}
    ])
    expect(wrapper.instance().state.selectedSectionsValue).toEqual(['3', '1'])
  })
})
