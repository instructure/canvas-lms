/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import {setupFilesEnv} from '../../../../fixtures/fakeFilesEnv'
import Breadcrumbs from '../Breadcrumbs'
import {FileManagementContext} from '../../Contexts'

const rootCourseFolder = {
  id: '1',
  name: 'course files',
  full_name: 'course files',
  context_id: '1',
  context_type: 'course',
  parent_folder_id: null,
  created_at: '',
  updated_at: '',
  lock_at: null,
  unlock_at: null,
  position: 0,
  locked: false,
  folders_url: '',
  files_url: '',
  files_count: 0,
  folders_count: 0,
  hidden: false,
  locked_for_user: false,
  hidden_for_user: false,
  for_submissions: false,
  can_upload: true,
}

const childCourseFolder = {
  id: '2',
  name: 'Documents',
  full_name: 'course files/Documents',
  context_id: '1',
  context_type: 'course',
  parent_folder_id: '1',
  created_at: '',
  updated_at: '',
  lock_at: null,
  unlock_at: null,
  position: 0,
  locked: false,
  folders_url: '',
  files_url: '',
  files_count: 0,
  folders_count: 0,
  hidden: false,
  locked_for_user: false,
  hidden_for_user: false,
  for_submissions: false,
  can_upload: true,
}

const child2CourseFolder = {
  id: '3',
  name: 'PDFs',
  full_name: 'course files/Documents/PDFs',
  context_id: '1',
  context_type: 'course',
  parent_folder_id: '2',
  created_at: '',
  updated_at: '',
  lock_at: null,
  unlock_at: null,
  position: 0,
  locked: false,
  folders_url: '',
  files_url: '',
  files_count: 0,
  folders_count: 0,
  hidden: false,
  locked_for_user: false,
  hidden_for_user: false,
  for_submissions: false,
  can_upload: true,
}

const defaultProps = {
  folders: [rootCourseFolder, childCourseFolder, child2CourseFolder],
  size: 'medium' as 'small' | 'medium' | 'large',
  showingAllContexts: false,
}

const renderComponent = (props = {}, context = {}) => {
  const defaultContext = {
    contextType: 'course',
    contextId: '1',
    folderId: '1',
    showingAllContexts: false,
  }
  return render(
    <FileManagementContext.Provider value={{...defaultContext, ...context}}>
      <Breadcrumbs {...defaultProps} {...props} />
    </FileManagementContext.Provider>,
  )
}

jest.mock('react-router-dom', () => ({
  Link: (props: any) => <a href={props.to}>{props.children}</a>,
}))

describe('Breadcrumbs', () => {
  beforeEach(() => {
    setupFilesEnv(false)
  })

  describe('with small size', () => {
    it('renders', () => {
      renderComponent({size: 'small'})
      expect(screen.getByText('Documents').closest('a')).toHaveAttribute(
        'href',
        '/folder/Documents',
      )
    })

    it('renders with a single breadcrumb', () => {
      renderComponent({folders: [rootCourseFolder]})
      expect(screen.getByText('Course 1')).toBeInTheDocument()
    })

    it('renders for all contexts', () => {
      setupFilesEnv(true)
      renderComponent({}, {showingAllContexts: true})
      expect(screen.getByText('Documents').closest('a')).toHaveAttribute(
        'href',
        '/folder/courses_1/Documents',
      )
    })
  })

  describe('with large size', () => {
    it('renders', () => {
      renderComponent()
      expect(screen.getByText('Course 1').closest('a')).toHaveAttribute('href', '/')
      expect(screen.getByText('Documents').closest('a')).toHaveAttribute(
        'href',
        '/folder/Documents',
      )
      expect(screen.getByText('PDFs')).toBeInTheDocument()
    })

    it('renders with a single breadcrumb', () => {
      renderComponent({folders: [rootCourseFolder]})
      expect(screen.getByText('Course 1')).toBeInTheDocument()
    })

    it('renders for all contexts', () => {
      setupFilesEnv(true)
      renderComponent({}, {showingAllContexts: true})
      expect(screen.getByText('All My Files').closest('a')).toHaveAttribute('href', '/')
      expect(screen.getByText('Course 1').closest('a')).toHaveAttribute(
        'href',
        '/folder/courses_1/',
      )
      expect(screen.getByText('Documents').closest('a')).toHaveAttribute(
        'href',
        '/folder/courses_1/Documents',
      )
      expect(screen.getByText('PDFs')).toBeInTheDocument()
    })
  })
})
