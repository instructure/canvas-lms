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

import React from 'react'
import {fireEvent, render} from 'react-testing-library'

import Filter from '../Filter'

describe('RCE Plugins > Filter', () => {
  let props
  let component

  beforeEach(() => {
    props = {
      contentSubtype: null,
      contentType: 'links',
      onChange: jest.fn(),
      sortValue: 'date_added'
    }
  })

  function renderComponent() {
    component = render(<Filter {...props} />)
  }

  function selectContentType(contentTypeLabel) {
    const contentTypeField = component.getByLabelText('Content Type')
    fireEvent.click(contentTypeField)
    fireEvent.click(component.getByText(contentTypeLabel))
  }

  function getContentSubtypeField() {
    return component.queryByLabelText('Content Subtype')
  }

  function selectContentSubtype(contentSubtypeLabel) {
    const contentTypeField = getContentSubtypeField()
    fireEvent.click(contentTypeField)
    fireEvent.click(component.getByText(contentSubtypeLabel))
  }

  function getSortByField() {
    return component.queryByLabelText('Sort By')
  }

  function selectSortBy(sortByLabel) {
    const sortByField = getSortByField()
    fireEvent.click(sortByField)
    fireEvent.click(component.getByText(sortByLabel))
  }

  describe('"Content Type" field', () => {
    it('calls the onChange prop when the value is changed', () => {
      renderComponent()
      selectContentType('Files')
      expect(props.onChange).toHaveBeenCalledTimes(1)
    })

    it('includes the updated filter settings when calling the onChange prop', () => {
      renderComponent()
      selectContentType('Files')
      expect(props.onChange).toHaveBeenCalledWith({contentType: 'files'})
    })
  })

  describe('"Content Subtype" field', () => {
    beforeEach(() => {
      props.contentType = 'files'
    })

    it('is visible when the Content Type is "Files"', () => {
      renderComponent()
      expect(getContentSubtypeField()).toBeVisible()
    })

    it('is not visible when the Content Type is "Links"', () => {
      props.contentType = 'links'
      renderComponent()
      expect(getContentSubtypeField()).toBeNull()
    })

    it('calls the onChange prop when the value is changed', () => {
      renderComponent()
      selectContentSubtype('Images')
      expect(props.onChange).toHaveBeenCalledTimes(1)
    })

    it('includes the updated filter settings when calling the onChange prop', () => {
      renderComponent()
      selectContentSubtype('Images')
      expect(props.onChange).toHaveBeenCalledWith({contentSubtype: 'images'})
    })
  })

  describe('"Sort By" field', () => {
    beforeEach(() => {
      props.contentType = 'files'
    })

    it('is visible when the Content Type is "Files"', () => {
      renderComponent()
      expect(getSortByField()).toBeVisible()
    })

    it('is not visible when the Content Type is "Links"', () => {
      props.contentType = 'links'
      renderComponent()
      expect(getSortByField()).toBeNull()
    })

    it('calls the onChange prop when the value is changed', () => {
      renderComponent()
      selectSortBy('Alphabetical')
      expect(props.onChange).toHaveBeenCalledTimes(1)
    })

    it('includes the updated filter settings when calling the onChange prop', () => {
      renderComponent()
      selectSortBy('Alphabetical')
      expect(props.onChange).toHaveBeenCalledWith({sortValue: 'alphabetical'})
    })
  })
})
