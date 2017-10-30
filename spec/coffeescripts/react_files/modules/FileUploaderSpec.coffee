#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'compiled/react_files/modules/FileUploader'
  'jquery'
  'jquery.ajaxJSON'
], (FileUploader, $) ->

  mockFileOptions =  (name, type, size) ->
    fileOptions =
      file:
        name: name
        type: type
        size: size

  QUnit.module 'FileUploader',
    setup: ->
      folder = {id: 1}
      @uploader = new FileUploader(mockFileOptions('foo', 'bar', 1), folder)

    teardown: ->
      delete @uploader


  test 'posts to the files endpoint to kick off upload', ->
    @stub($, 'ajaxJSON')

    @uploader.upload()
    equal($.ajaxJSON.calledWith('/api/v1/folders/1/files'), true, 'kicks off upload')

  test 'stores params from preflight for actual upload', ->
    server = sinon.fakeServer.create()
    server.respondWith('POST',
                       '/api/v1/folders/1/files',
                       [ 200,
                         {"Content-Type": "application/json"},
                         '{"upload_url": "/upload/url", "upload_params": {"key": "value"}}'
                       ]
    )

    @stub(@uploader, '_actualUpload')
    @uploader.upload()

    server.respond()

    equal @uploader.uploadData.upload_url, '/upload/url'
    equal @uploader.uploadData.upload_params.key, 'value'

    server.restore()

  test 'pings success_url after upload if set (S3)', ->
    server = sinon.fakeServer.create()
    server.respondWith('POST',
                       '/api/v1/folders/1/files',
                       [ 200,
                         {"Content-Type": "application/json"},
                         '{"upload_url": "/s3/upload/url", "upload_params": {"success_url": "/success/url"}}'
                       ]
    )
    server.respondWith('POST',
                       '/s3/upload/url',
                       [ 201,
                         {"Content-Type": "application/xml"},
                         '<s3metadata />'
                       ]
    )
    server.respondWith('GET',
                       '/success/url',
                       [ 200,
                         {"Content-Type": "application/json"},
                         '{ "id": "s3-id" }'
                       ]
    )
    @stub(@uploader, 'addFileToCollection')
    promise = @uploader.upload()
    server.respond() # preflight
    server.respond() # upload to s3
    server.respond() # success_url
    ok(@uploader.addFileToCollection.calledWith(id: "s3-id"), "got metadata from success_url")
    server.restore()

  test 'reads location after upload if 201 but no success_url (inst-fs)', ->
    server = sinon.fakeServer.create()
    server.respondWith('POST',
                       '/api/v1/folders/1/files',
                       [ 200,
                         {"Content-Type": "application/json"},
                         '{"upload_url": "/inst-fs/upload/url", "upload_params": {}}'
                       ]
    )
    server.respondWith('POST',
                       '/inst-fs/upload/url',
                       [ 201,
                         {"Content-Type": "application/json"},
                         '{ "location": "/attachment/url" }'
                       ]
    )
    server.respondWith('GET',
                       '/attachment/url',
                       [ 200,
                         {"Content-Type": "application/json"},
                         '{ "id": "inst-fs-id" }'
                       ]
    )
    @stub(@uploader, 'addFileToCollection')
    promise = @uploader.upload()
    server.respond() # preflight
    server.respond() # upload to inst-fs
    server.respond() # location
    ok(@uploader.addFileToCollection.calledWith(id: "inst-fs-id"), "got metadata from location")
    server.restore()

  test 'takes response body directly if 200 instead of 201 (local storage)', ->
    server = sinon.fakeServer.create()
    server.respondWith('POST',
                       '/api/v1/folders/1/files',
                       [ 200,
                         {"Content-Type": "application/json"},
                         '{"upload_url": "/inst-fs/upload/url", "upload_params": {}}'
                       ]
    )
    server.respondWith('POST',
                       '/inst-fs/upload/url',
                       [ 200,
                         {"Content-Type": "application/json"},
                         '{ "id": "local-storage-id" }'
                       ]
    )
    @stub(@uploader, 'addFileToCollection')
    promise = @uploader.upload()
    server.respond() # preflight
    server.respond() # upload to local storage
    ok(@uploader.addFileToCollection.calledWith(id: "local-storage-id"), "got metadata from response")
    server.restore()

  test 'roundProgress returns back rounded values', ->
    @stub(@uploader, 'getProgress').returns(0.18) # progress is [0 .. 1]
    equal @uploader.roundProgress(), 18

  test 'roundProgress returns back values no greater than 100', ->
    @stub(@uploader, 'getProgress').returns(1.1) # something greater than 100%
    equal @uploader.roundProgress(), 100

  test 'getFileName returns back the option name if one exists', ->
    folder = {id: 1}
    options = mockFileOptions('foo', 'bar', 1)
    options.name = 'use this one'
    @uploader = new FileUploader(options, folder)
    equal @uploader.getFileName(), 'use this one'

  test 'getFileName returns back the actual file if no optinal name is given', ->
    folder = {id: 1}
    options = mockFileOptions('foo', 'bar', 1)
    @uploader = new FileUploader(options, folder)
    equal @uploader.getFileName(), 'foo'
