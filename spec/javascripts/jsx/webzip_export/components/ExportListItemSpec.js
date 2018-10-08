/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import enzyme from 'enzyme'
import ExportListItem from 'jsx/webzip_export/components/ExportListItem'

QUnit.module('ExportListItem')

test('renders the ExportListItem component', () => {
  const props = {
    date: 'Sept 11, 2001 at 8:46am',
    link: 'https://example.com/neverforget',
    workflowState: 'generated',
    newExport: false
  }
  const tree = enzyme.shallow(<ExportListItem {...props} />)
  const node = tree.find('.webzipexport__list__item')
  ok(node.exists())
})

test('renders different text for last success', () => {
  const props = {
    date: '2017-01-13T2:30:00Z',
    link: 'https://example.com/alwaysremember',
    workflowState: 'generated',
    newExport: true
  }
  const tree = enzyme.shallow(<ExportListItem {...props} />)
  const node = tree.find('.webzipexport__list__item')
  ok(node.text().startsWith('Most recent export'))
})

test('renders error text if last object failed', () => {
  const props = {
    date: '2017-01-13T2:30:00Z',
    link: 'https://example.com/alwaysremember',
    workflowState: 'failed',
    newExport: true
  }
  const tree = enzyme.shallow(<ExportListItem {...props} />)
  const node = tree.find('.text-error')
  ok(node.text().startsWith('Export failed'))
})
