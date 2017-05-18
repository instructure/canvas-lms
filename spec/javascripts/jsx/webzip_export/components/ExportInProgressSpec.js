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

define([
  'react',
  'react-dom',
  'enzyme',
  'jsx/webzip_export/components/ExportInProgress',
], (React, ReactDOM, enzyme, ExportInProgress) => {
  QUnit.module('ExportInProgress')

  test('renders the ExportInProgress component', () => {
    const webzip = {progressId: '117'}
    const tree = enzyme.shallow(<ExportInProgress webzip={webzip} loadExports={() => {}} />)

    const node = tree.find('.webzipexport__inprogress')

    ok(node.exists())
  })

  test('doesnt render when completed is true', () => {
    const webzip = {progressId: '117'}
    const tree = enzyme.shallow(<ExportInProgress webzip={webzip} loadExports={() => {}} />)

    tree.setState({completed: true})

    const node = tree.find('.webzipexport__inprogress')

    equal(node.length, 0)
  })
})
