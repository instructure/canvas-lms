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
import {fireEvent, render, waitFor} from '@testing-library/react'
import Filter, {useFilterSettings} from '../Filter'
import {ICON_MAKER_ICONS} from '../../instructure_icon_maker/svg/constants'

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

  describe('"Content Subtype" field', () => {
    beforeEach(() => {
      renderComponent({userContextType: 'course', use_rce_icon_maker: true})
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

    it('sets content subtype to "all" when "All" is selected', () => {
      selectContentSubtype('Media')
      selectContentSubtype('All')
      expect(currentFilterSettings.contentSubtype).toEqual('all')
      // side-effect of changing the contentType to User
      expect(currentFilterSettings.contentType).toEqual('user_files')
    })

    it('does not change content type when changed', () => {
      expect(currentFilterSettings.contentType).toEqual('user_files')
      selectContentSubtype('Media')
      expect(currentFilterSettings.contentType).toEqual('user_files')
    })

    it('does not change sort value when changed', () => {
      selectContentSubtype('Documents')
      selectSortBy('Date Added')
      expect(currentFilterSettings.sortValue).toEqual('date_added')
      selectContentSubtype('Media')
      expect(currentFilterSettings.sortValue).toEqual('date_added')
    })

    describe('when "Icon Maker Icons" is selected', () => {
      beforeEach(() => {
        selectContentSubtype('Icon Maker Icons')
      })

      it('sets the content subtype to "icon_maker_icons"', () => {
        expect(currentFilterSettings.contentSubtype).toEqual(ICON_MAKER_ICONS)
      })

      it('sets the content type to "course_files"', () => {
        expect(currentFilterSettings.contentType).toEqual('course_files')
      })

      it('does not render "User Files" content type', () => {
        expect(component.queryByTitle('User Files')).toBeNull()
      })

      it('renders the "Course Files" content type', () => {
        expect(component.getByTitle('Course Files')).toBeInTheDocument()
      })
    })
  })

  describe('deals with switching to and from Links', () => {
    it('changes to "all" when type changes from "Links" to "Files"', () => {
      renderComponent({userContextType: 'course'})

      // our initial state
      expect(currentFilterSettings.contentType).toEqual('course_files')
      expect(currentFilterSettings.contentSubtype).toEqual('documents')

      // switch to Links, the subtype remains unchanged (though we don't care what it is)
      selectContentType('Links')
      expect(currentFilterSettings.contentType).toEqual('links')
      expect(currentFilterSettings.contentSubtype).toEqual('documents')

      // the other content type is now just "Files", and it shows all files
      // subtype is "all" so we can query for the media, which is only returned
      // in the user context
      selectContentType('Files')
      expect(currentFilterSettings.contentType).toEqual('user_files')
      expect(currentFilterSettings.contentSubtype).toEqual('all')

      // Switch from "All" to "Documents"
      selectContentSubtype('Documents')
      expect(currentFilterSettings.contentType).toEqual('user_files')
      expect(currentFilterSettings.contentSubtype).toEqual('documents')
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

    it('sets sort value to "date_added" when "Date Added" is selected', () => {
      selectSortBy('Alphabetical')
      selectSortBy('Date Added')
      expect(currentFilterSettings.sortValue).toEqual('date_added')
    })

    it('does not change content type when changed', () => {
      selectSortBy('Alphabetical')
      expect(currentFilterSettings.contentType).toEqual('course_files')
    })

    it('does not change content subtype when changed', () => {
      selectContentSubtype('Media')
      selectSortBy('Alphabetical')
      expect(currentFilterSettings.contentSubtype).toEqual('media')
    })
  })

  describe('"Search" field', () => {
    it('is visible when the contentSubtype is documents', () => {
      renderComponent({
        userContextType: 'course',
        contentType: 'course_files',
        contentSubtype: 'documents',
      })
      expect(component.getByPlaceholderText('Search')).toBeInTheDocument()
    })

    it('is visible when the contentSubtype is images', () => {
      renderComponent({
        userContextType: 'course',
        contentType: 'course_files',
        contentSubtype: 'images',
      })
      expect(component.getByPlaceholderText('Search')).toBeInTheDocument()
    })

    it('is visible when the contentSubtype is media', () => {
      renderComponent({
        userContextType: 'course',
        contentType: 'course_files',
        contentSubtype: 'media',
      })
      expect(component.queryByPlaceholderText('Search')).toBeInTheDocument()
    })

    it('is visible when the contentType is links', () => {
      renderComponent({
        userContextType: 'course',
        contentType: 'links',
      })
      expect(component.queryByPlaceholderText('Search')).toBeInTheDocument()
    })

    it('is visible when the contentSubtype is all', () => {
      renderComponent({
        userContextType: 'course',
        contentType: 'course_files',
        contentSubtype: 'all',
      })
      expect(component.queryByPlaceholderText('Search')).toBeInTheDocument()
    })

    it('updates filter settings when the search string is > 3 chars long', async () => {
      renderComponent({
        userContextType: 'course',
        contentType: 'course_files',
        contentSubtype: 'documents',
      })
      const searchInput = component.getByPlaceholderText('Search')
      expect(currentFilterSettings.searchString).toBe('')
      fireEvent.change(searchInput, {target: {value: 'abc'}})
      await waitFor(() => {
        expect(currentFilterSettings.searchString).toBe('abc')
      })
    })

    it('clears search when clear button is clicked', async () => {
      renderComponent({
        userContextType: 'course',
        contentType: 'course_files',
        contentSubtype: 'documents',
      })
      const searchInput = component.getByPlaceholderText('Search')
      expect(currentFilterSettings.searchString).toBe('')
      fireEvent.change(searchInput, {target: {value: 'abc'}})
      await waitFor(() => {
        expect(currentFilterSettings.searchString).toBe('abc')
      })
      fireEvent.click(component.getByText('Clear'))
      await waitFor(() => {
        expect(currentFilterSettings.searchString).toBe('')
      })
    })

    it('is not readonly while content is loading', () => {
      renderComponent({
        userContextType: 'course',
        contentType: 'course_files',
        contentSubtype: 'documents',
        isContentLoading: true,
        searchString: 'abc',
      })
      const searchInput = component.getByPlaceholderText('Search')
      expect(searchInput.hasAttribute('readonly')).toBe(false)

      const clearBtn = component.getByText('Clear').closest('button')
      expect(clearBtn.hasAttribute('disabled')).toBe(false)
    })

    it('shows the search message when not loading', () => {
      renderComponent()
      expect(component.getByText('Enter at least 3 characters to search')).toBeInTheDocument()
    })

    it('shows the loading message when loading', () => {
      renderComponent({isContentLoading: true})
      // screenreader message + hint under the search input box
      expect(component.getByText('Loading, please wait')).toBeInTheDocument()
    })
  })
})
