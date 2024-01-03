/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {SourceLink} from '../source_link'
import type {ContentMigrationItem, ContentMigrationItemAttachment} from '../types'

const item: ContentMigrationItem = {
  id: '1',
  migration_type: 'course_copy_importer',
  migration_type_title: 'Course Copy',
  workflow_state: 'completed',
  migration_issues_count: 0,
  created_at: '1997-04-15T00:00:00Z',
  settings: {
    source_course_id: '1',
    source_course_name: 'My Course',
    source_course_html_url: 'https://localhost/courses/1',
  },
  progress_url: 'https://mock.progress.url',
  migration_issues_url: 'https://mock.issues.url',
}

const attachment: ContentMigrationItemAttachment = {
  display_name: 'file.zip',
  url: 'https://localhost/files/1/download',
}

const renderComponent = (overrideProps?: any) =>
  render(<SourceLink item={{...item, ...overrideProps}} />)

describe('SourceLink', () => {
  describe('for Copy Canvas Course', () => {
    it('renders the correct link', () => {
      const component = renderComponent()
      expect(component.getByRole('link', {name: 'My Course'})).toHaveAttribute(
        'href',
        'https://localhost/courses/1'
      )
    })
  })

  describe('for Canvas Cartrige', () => {
    it('renders the correct link', () => {
      const component = renderComponent({migration_type: 'canvas_cartridge_importer'})
      expect(component.getByRole('link', {name: 'My Course'})).toHaveAttribute(
        'href',
        'https://localhost/courses/1'
      )
    })

    it('does not break on undefined settings', () => {
      const component = renderComponent({
        migration_type: 'canvas_cartridge_importer',
        settings: undefined,
        attachment,
      })
      expect(component.getByRole('link', {name: 'file.zip'})).toHaveAttribute(
        'href',
        'https://localhost/files/1/download'
      )
    })

    it('renders the correct link when is not completed', () => {
      const component = renderComponent({
        migration_type: 'canvas_cartridge_importer',
        workflow_state: 'running',
        attachment,
      })
      expect(component.getByRole('link', {name: 'file.zip'})).toHaveAttribute(
        'href',
        'https://localhost/files/1/download'
      )
    })

    it('renders the text when attachment is not available', () => {
      const component = renderComponent({
        migration_type: 'canvas_cartridge_importer',
        workflow_state: 'running',
      })
      expect(component.getByText('File not available')).toBeInTheDocument()
    })
  })

  describe('for .zip file', () => {
    it('renders the correct link', () => {
      const component = renderComponent({migration_type: 'zip_file_importer', attachment})
      expect(component.getByRole('link', {name: 'file.zip'})).toHaveAttribute(
        'href',
        'https://localhost/files/1/download'
      )
    })

    it('renders the text when attachment is not available', () => {
      const component = renderComponent({migration_type: 'zip_file_importer'})
      expect(component.getByText('File not available')).toBeInTheDocument()
    })
  })

  describe('for Common Cartrige', () => {
    it('renders the correct link', () => {
      const component = renderComponent({migration_type: 'common_cartridge_importer', attachment})
      expect(component.getByRole('link', {name: 'file.zip'})).toHaveAttribute(
        'href',
        'https://localhost/files/1/download'
      )
    })

    it('renders the text when attachment is not available', () => {
      const component = renderComponent({migration_type: 'common_cartridge_importer'})
      expect(component.getByText('File not available')).toBeInTheDocument()
    })
  })

  describe('for Moodle', () => {
    it('renders the correct link', () => {
      const component = renderComponent({migration_type: 'moodle_converter', attachment})
      expect(component.getByRole('link', {name: 'file.zip'})).toHaveAttribute(
        'href',
        'https://localhost/files/1/download'
      )
    })

    it('renders the text when attachment is not available', () => {
      const component = renderComponent({migration_type: 'moodle_converter'})
      expect(component.getByText('File not available')).toBeInTheDocument()
    })
  })

  describe('for QTI .zip file', () => {
    it('renders the correct link', () => {
      const component = renderComponent({migration_type: 'qti_converter', attachment})
      expect(component.getByRole('link', {name: 'file.zip'})).toHaveAttribute(
        'href',
        'https://localhost/files/1/download'
      )
    })

    it('renders the text when attachment is not available', () => {
      const component = renderComponent({migration_type: 'qti_converter'})
      expect(component.getByText('File not available')).toBeInTheDocument()
    })
  })
})
