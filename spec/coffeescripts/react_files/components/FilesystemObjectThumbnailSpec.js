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
import File from 'compiled/models/File'
import Folder from 'compiled/models/Folder'
import FilesystemObject from 'compiled/models/FilesystemObject'
import FilesystemObjectThumbnail from 'jsx/files/FilesystemObjectThumbnail'

QUnit.module('Filesystem Object Thumbnail: file', {
  setup() {
    const file = new File({
      id: 65,
      thumbnail_url: 'sweet_thumbnail_url'
    })
    this.fOT = React.createFactory(FilesystemObjectThumbnail)
    this.clock = sinon.useFakeTimers()
    this.thumbnail = TestUtils.renderIntoDocument(
      this.fOT({
        model: file,
        className: 'customClassname'
      })
    )
    return this.clock.tick(20000)
  },
  teardown() {
    this.clock.restore()
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.thumbnail).parentNode)
  }
})

test('displays the thumbnail image', function() {
  equal(
    $(ReactDOM.findDOMNode(this.thumbnail)).attr('style'),
    "background-image: url(\"sweet_thumbnail_url\");",
    'set background image to correct url'
  )
})

test('adds class name from props to the span', function() {
  ok($(ReactDOM.findDOMNode(this.thumbnail)).hasClass('customClassname'), 'finds the custom className')
})

QUnit.module('Filesystem Object Thumbnail: folder', {
  setup() {
    const folder = new Folder({id: 65})
    this.fOT = React.createFactory(FilesystemObjectThumbnail)
    this.clock = sinon.useFakeTimers()
    this.thumbnail = TestUtils.renderIntoDocument(
      this.fOT({
        model: folder,
        className: 'customClassname'
      })
    )
    return this.clock.tick(20000)
  },
  teardown() {
    this.clock.restore()
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.thumbnail).parentNode)
  }
})

test("adds mimeClass-Folder if it's a folder", function() {
  ok($(ReactDOM.findDOMNode(this.thumbnail)).hasClass('mimeClass-folder'), 'adds mimeClass for folder')
})

test('adds on className to i tag if set in props', function() {
  ok($(ReactDOM.findDOMNode(this.thumbnail)).hasClass('customClassname'), 'finds the custom className')
})

QUnit.module('Filesystem Object Thumbnail: other')

test('adds on className to i tag if set in props', function() {
  const fso = new FilesystemObject({id: 65})
  fso.url = () => 'foo'
  this.fOT = React.createFactory(FilesystemObjectThumbnail)
  const clock = sinon.useFakeTimers()
  const thumbnail = TestUtils.renderIntoDocument(
    this.fOT({
      model: fso,
      className: 'customClassname'
    })
  )
  clock.tick(20000)
  ok($(ReactDOM.findDOMNode(thumbnail)).hasClass('customClassname'), 'finds the custom className')
  clock.restore()
  ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(thumbnail).parentNode)
})

QUnit.module('Filesystem Object Thumbnail: checkForThumbnail', {
  setup() {
    const url = '/api/v1/files/65'
    this.server = sinon.fakeServer.create()
    this.server.respondWith(url, [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify({thumbnail_url: 'sweet_thumbnail_url'})
    ])
    const file = new File({id: 65})
    this.fOT = React.createFactory(FilesystemObjectThumbnail)
    this.clock = sinon.useFakeTimers()
    this.thumbnail = TestUtils.renderIntoDocument(this.fOT({model: file}))
    this.clock.tick(20000)
    return this.server.respond()
  },
  teardown() {
    this.server.restore()
    this.clock.restore()
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.thumbnail).parentNode)
  }
})

test('fetches thumbnail_url and puts it into state', function() {
  this.clock.tick(1000)
  ok(
    this.thumbnail.state.thumbnail_url === 'sweet_thumbnail_url',
    'fetches and set thumbnail url into state'
  )
})
