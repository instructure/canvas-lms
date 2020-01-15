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
import {fireEvent, render} from '@testing-library/react'

import Filter, {useFilterSettings} from '../Filter'

describe('RCE Plugins > Filter', () => {
  let currentFilterSettings
  let component

  beforeEach(() => {
    currentFilterSettings = null
  })

  function FilterWithHooks(props = {}) {
    const [filterSettings, setFilterSettings] = useFilterSettings()
    currentFilterSettings = filterSettings

    return <Filter {...filterSettings} onChange={setFilterSettings} {...props} />
  }

  function renderComponent(props) {
    component = render(<FilterWithHooks {...props} />)
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

  describe('initially', () => {
    beforeEach(() => {
      renderComponent()
    })
    it('sets content type to "links"', () => {
      expect(currentFilterSettings.contentType).toEqual('links')
    })

    it('sets content subtype to "all"', () => {
      expect(currentFilterSettings.contentSubtype).toEqual('all')
    })

    it('sets sort value to "date_added"', () => {
      expect(currentFilterSettings.sortValue).toEqual('date_added')
    })
  })

  describe('"Content Type" field', () => {
    beforeEach(() => {
      renderComponent({userContextType: 'course'})
    })
    it('sets content type to "user_files" when "User Files" is selected', () => {
      selectContentType('User Files')
      expect(currentFilterSettings.contentType).toEqual('user_files')
    })

    it('sets content type to "course_files" when "Course Files" is selected', () => {
      selectContentType('Course Files')
      expect(currentFilterSettings.contentType).toEqual('course_files')
    })

    it('sets content type to "links" when "Links" is selected', () => {
      selectContentType('User Files')
      selectContentType('Links')
      expect(currentFilterSettings.contentType).toEqual('links')
    })

    it.skip('does not change content subtype when changed', () => {
      selectContentType('User Files')
      selectContentSubtype('Media')
      selectContentType('Links')
      expect(currentFilterSettings.contentSubtype).toEqual('media')
    })

    it('does not change sort value when changed', () => {
      selectContentType('User Files')
      selectContentSubtype('Documents')
      selectSortBy('Date Published')
      selectContentType('Links')
      expect(currentFilterSettings.sortValue).toEqual('date_published')
    })
  })

  describe('"Content Type" in context', () => {
    it('has "Course" options', () => {
      renderComponent({userContextType: 'course'})

      selectContentType('Course Files')
      expect(currentFilterSettings.contentType).toEqual('course_files')
      expect(component.getByLabelText('Content Type').value).toEqual('Course Files')
    })

    it('has "My" options', () => {
      renderComponent({userContextType: 'course'})

      selectContentType('User Files')
      expect(currentFilterSettings.contentType).toEqual('user_files')
      expect(component.getByLabelText('Content Type').value).toEqual('User Files')
    })

    it('includes the Course and My options in course context', () => {
      renderComponent({userContextType: 'course'})
      const contentTypeField = component.getByLabelText('Content Type')
      fireEvent.click(contentTypeField)
      expect(component.getByText('Links')).toBeInTheDocument()
      expect(component.getByText('User Files')).toBeInTheDocument()
      expect(component.getByText('Course Files')).toBeInTheDocument()
    })

    it('includes only My option in user context', () => {
      renderComponent({userContextType: 'user'})
      const contentTypeField = component.getByLabelText('Content Type')
      fireEvent.click(contentTypeField)
      expect(component.getByText('Links')).toBeInTheDocument()
      expect(component.getByText('User Files')).toBeInTheDocument()
      expect(component.queryByText('Course Files')).toBeNull()
    })
  })

  describe('"Content Subtype" field', () => {
    beforeEach(() => {
      renderComponent()
      selectContentType('User Files')
    })

    it('is visible when the Content Type is "User Files"', () => {
      expect(getContentSubtypeField()).toBeVisible()
    })

    it('is not visible when the Content Type is "Links"', () => {
      selectContentType('Links')
      expect(getContentSubtypeField()).toBeNull()
    })

    it('sets content subtype to "images" when "Images" is selected', () => {
      selectContentSubtype('Images')
      expect(currentFilterSettings.contentSubtype).toEqual('images')
    })

    it('sets content subtype to "documents" when "Documents" is selected', () => {
      selectContentSubtype('Documents')
      expect(currentFilterSettings.contentSubtype).toEqual('documents')
    })

    it('sets content subtype to "media" when "Media" is selected', () => {
      selectContentSubtype('Media')
      expect(currentFilterSettings.contentSubtype).toEqual('media')
    })

    it.skip('sets content subtype to "all" when "All" is selected', () => {
      selectContentSubtype('Media')
      selectContentSubtype('All')
      expect(currentFilterSettings.contentSubtype).toEqual('all')
    })

    it('does not change content type when changed', () => {
      expect(currentFilterSettings.contentType).toEqual('user_files')
      selectContentSubtype('Media')
      expect(currentFilterSettings.contentType).toEqual('user_files')
    })

    it('does not change sort value when changed', () => {
      selectContentSubtype('Documents')
      selectSortBy('Date Published')
      expect(currentFilterSettings.sortValue).toEqual('date_published')
      selectContentSubtype('Media')
      expect(currentFilterSettings.sortValue).toEqual('date_published')
    })
  })

  describe('"Sort By" field', () => {
    beforeEach(() => {
      renderComponent({userContextType: 'course'})
      selectContentType('Course Files')
      selectContentSubtype('Documents')
    })

    it('is visible when the Content Type is "Files"', () => {
      expect(getSortByField()).toBeVisible()
    })

    it('is not visible when the Content Type is "Links"', () => {
      selectContentType('Links')
      expect(getSortByField()).toBeNull()
    })

    it('sets sort value to "alphabetical" when "Alphabetical" is selected', () => {
      selectSortBy('Alphabetical')
      expect(currentFilterSettings.sortValue).toEqual('alphabetical')
    })

    it('sets sort value to "date_published" when "Date Published" is selected', () => {
      selectSortBy('Date Published')
      expect(currentFilterSettings.sortValue).toEqual('date_published')
    })

    it('sets sort value to "date_added" when "Date Added" is selected', () => {
      selectSortBy('Date Published')
      selectSortBy('Date Added')
      expect(currentFilterSettings.sortValue).toEqual('date_added')
    })

    it('does not change content type when changed', () => {
      selectSortBy('Alphabetical')
      expect(currentFilterSettings.contentType).toEqual('course_files')
    })

    it.skip('does not change content subtype when changed', () => {
      selectContentSubtype('Media')
      selectSortBy('Alphabetical')
      expect(currentFilterSettings.contentSubtype).toEqual('media')
    })
  })
})
