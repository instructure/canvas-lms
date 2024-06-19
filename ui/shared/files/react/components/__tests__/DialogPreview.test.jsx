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
import ReactDOM from 'react-dom'
import TestUtils from 'react-dom/test-utils'
import File from '../../../backbone/models/File'
import DialogPreview from '../DialogPreview'
import FilesystemObjectThumbnail from '../FilesystemObjectThumbnail'
import sinon from 'sinon'

const sandbox = sinon.createSandbox()

describe('DialogPreview', () => {
  test('DP: single item rendered with FilesystemObjectThumbnail', () => {
    const file = new File({name: 'Test File', thumbnail_url: 'blah'})
    file.url = () => 'some_url'
    const fsObjStub = sandbox.stub(FilesystemObjectThumbnail.prototype, 'render').returns(<div />)
    const dialogPreview = TestUtils.renderIntoDocument(<DialogPreview itemsToShow={[file]} />)
    expect(fsObjStub.calledOnce).toBeTruthy()
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(dialogPreview).parentNode)
  })

  test('DP: multiple file items rendered in i elements', () => {
    const url = () => 'some_url'
    const file = new File({name: 'Test File', thumbnail_url: 'blah'})
    const file2 = new File({name: 'Test File', thumbnail_url: 'blah'})
    file.url = url
    file2.url = url
    const dialogPreview = TestUtils.renderIntoDocument(
      <DialogPreview itemsToShow={[file, file2]} />
    )
    // 'there are two files rendered'
    expect(ReactDOM.findDOMNode(dialogPreview).getElementsByTagName('i').length).toBe(2)
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(dialogPreview).parentNode)
  })
})
