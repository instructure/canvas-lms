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
import Filter from '../Filter'
import {useFilterSettings} from '../useFilterSettings'

describe('RCE Plugins > Filter', () => {
  let currentFilterSettings
  let component
  let default_filter_settings

  beforeEach(() => {
    currentFilterSettings = null
    default_filter_settings = {
      contentType: 'course_files',
      contentSubtype: 'documents',
      sortValue: 'date_added',
      searchString: '',
    }
  })

  function FilterWithHooks(props = {}) {
    const [filterSettings, setFilterSettings] = useFilterSettings(default_filter_settings)
    currentFilterSettings = filterSettings

    return <Filter {...filterSettings} onChange={setFilterSettings} {...props} />
  }

  function renderComponent(props) {
    component = render(<FilterWithHooks containingContextType="course" {...props} />)
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

  it('does not render "Icon Maker Icons" option when the feature is disabled', () => {
    renderComponent({use_rce_icon_maker: false})
    fireEvent.click(getContentSubtypeField())
    expect(component.queryByText('Icon Maker Icons')).toBeNull()
  })

  it('renders "Icon Maker Icons" option when the feature is enabled', () => {
    renderComponent({use_rce_icon_maker: true})
    fireEvent.click(getContentSubtypeField())
    expect(component.queryByText('Icon Maker Icons')).toBeInTheDocument()
  })

  describe('initially', () => {
    beforeEach(() => {
      renderComponent()
    })
    it('sets content type to default', () => {
      expect(currentFilterSettings.contentType).toEqual(default_filter_settings.contentType)
    })

    it('sets content subtype to defualt', () => {
      expect(currentFilterSettings.contentSubtype).toEqual(default_filter_settings.contentSubtype)
    })

    it('sets sort value to default', () => {
      expect(currentFilterSettings.sortValue).toEqual(default_filter_settings.sortValue)
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

    it('does not change content subtype when changed', () => {
      selectContentType('User Files')
      selectContentSubtype('Media')
      selectContentType('Links')
      expect(currentFilterSettings.contentSubtype).toEqual('media')
    })

    it('does not change sort value when changed', () => {
      selectContentType('User Files')
      selectContentSubtype('Documents')
      selectSortBy('Date Added')
      selectContentType('Links')
      expect(currentFilterSettings.sortValue).toEqual('date_added')
    })
  })

  describe('"Content Type" in context', () => {
    it('has "Course" options', () => {
      renderComponent({userContextType: 'course'})

      selectContentType('Course Files')
      expect(currentFilterSettings.contentType).toEqual('course_files')
      expect(component.getByLabelText('Content Type').value).toEqual('Course Files')
    })

    it('has "Group" options', () => {
      renderComponent({userContextType: 'group'})

      selectContentType('Group Files')
      expect(currentFilterSettings.contentType).toEqual('group_files')
      expect(component.getByLabelText('Content Type').value).toEqual('Group Files')
    })

    it('has "User" options', () => {
      renderComponent({userContextType: 'course'})

      selectContentType('User Files')
      expect(currentFilterSettings.contentType).toEqual('user_files')
      expect(component.getByLabelText('Content Type').value).toEqual('User Files')
    })

    it('includes the Link, Course, and User options in course context', () => {
      renderComponent({userContextType: 'course'})
      const contentTypeField = component.getByLabelText('Content Type')
      fireEvent.click(contentTypeField)
      expect(component.getByText('Links')).toBeInTheDocument()
      expect(component.getByText('User Files')).toBeInTheDocument()
      expect(component.getByText('Course Files')).toBeInTheDocument()
    })

    it('includes only User option in user context', () => {
      renderComponent({userContextType: 'user', containingContextType: 'user'})
      const contentTypeField = component.queryByLabelText('Content Type')
      expect(contentTypeField).toBeNull() // we replaced the Select with a View
      expect(component.queryByText('Links')).toBeNull()
      expect(component.getByText('User Files')).toBeInTheDocument()
      expect(component.queryByText('Course Files')).toBeNull()
    })

    it('includes the Link and User options in group context', () => {
      renderComponent({userContextType: 'group'})
      const contentTypeField = component.getByLabelText('Content Type')
      fireEvent.click(contentTypeField)
      expect(component.getByText('Links')).toBeInTheDocument()
      expect(component.getByText('User Files')).toBeInTheDocument()
      expect(component.queryByText('Course Files')).toBeNull()
    })

    it('does not render Content Type when in Edit Course Link Tray', () => {
      renderComponent({contentSubtype: 'edit'})
      const contentTypeField = component.queryByLabelText('Content Type')
      expect(contentTypeField).not.toBeInTheDocument()
    })
  })
})
