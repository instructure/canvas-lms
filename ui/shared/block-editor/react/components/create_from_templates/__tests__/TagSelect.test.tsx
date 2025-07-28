/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import {TagSelect, AvailableTags} from '../TagSelect'

const renderComponent = (props = {}) => {
  return render(
    <TagSelect
      onChange={jest.fn()}
      selectedTags={Object.keys(AvailableTags)}
      interaction="enabled"
      {...props}
    />,
  )
}

const isMenuItemChecked = (li: HTMLLIElement): boolean => {
  return li.querySelector('svg[name="IconCheck"]') !== null
}

describe('TagSelect', () => {
  it('renders', () => {
    const {getByText} = renderComponent()
    expect(getByText('Apply Filters')).toBeInTheDocument()
  })

  it('shows the menu', () => {
    const {getByText} = renderComponent()
    const trigger = getByText('Apply Filters').closest('button')
    
    trigger?.click()
    expect(getByText('Home')).toBeInTheDocument()
    expect(getByText('Resource')).toBeInTheDocument()
    expect(getByText('Module Overview')).toBeInTheDocument()
    expect(getByText('Introduction')).toBeInTheDocument()
    expect(getByText('General Content')).toBeInTheDocument()
  })

  it('checks the selected tags', () => {
    const selectedTags = ['home', 'resource', 'intro']
    const {getByText, debug} = renderComponent({selectedTags})
    const trigger = getByText('Apply Filters').closest('button')
    trigger?.click()

    for (const tag of Object.keys(AvailableTags)) {
      const li = getByText(AvailableTags[tag]).parentElement
      const isChecked = selectedTags.includes(tag)
      expect(isMenuItemChecked(li as HTMLLIElement)).toBe(isChecked)
    }
  })

  it('calls onChange when a tag is selected', () => {
    const onChange = jest.fn()
    const selectedTags = ['resource']
    const {getByText} = renderComponent({selectedTags, onChange})
    const trigger = getByText('Apply Filters').closest('button')
    trigger?.click()

    const li = getByText('Home')
    li?.click()
    expect(onChange).toHaveBeenCalledWith(['resource', 'home'])
  })
})
