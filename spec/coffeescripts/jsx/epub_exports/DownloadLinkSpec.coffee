#
# Copyright (C) 2015 - present Instructure, Inc.
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
  'underscore',
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jsx/epub_exports/DownloadLink',
  'i18n!epub_exports',
], (_, React, ReactDOM, TestUtils, DownloadLink, I18n) ->

  QUnit.module 'DownloadLink',
    setup: ->
      @props = {
        course: {
          name: 'Maths 101',
          id: 1
        }
      }

  test 'state showDownloadLink', ->
    DownloadLinkElement = React.createElement(DownloadLink, @props)
    component = TestUtils.renderIntoDocument(DownloadLinkElement)
    ok !component.showDownloadLink(), 'should be false without epub_export object'

    @props.course.epub_export = {
      permissions: {
        download: false
      }
    }
    DownloadLinkElement = React.createElement(DownloadLink, @props)
    component = TestUtils.renderIntoDocument(DownloadLinkElement)
    ok !component.showDownloadLink(), 'should be false without permissions to download'

    @props.course.epub_export = {
      epub_attachment: {
        url: 'http://download.url'
      },
      permissions: {
        download: true
      }
    }
    DownloadLinkElement = React.createElement(DownloadLink, @props)
    component = TestUtils.renderIntoDocument(DownloadLinkElement)
    ok component.showDownloadLink(), 'should be true with permissions to download'
    ReactDOM.unmountComponentAtNode(component.getDOMNode().parentNode)

  test 'render', ->
    DownloadLinkElement = React.createElement(DownloadLink, @props)
    component = TestUtils.renderIntoDocument(DownloadLinkElement)
    node = component.getDOMNode()
    ok _.isNull(node)

    @props.course.epub_export = {
      epub_attachment: {
        url: 'http://download.url'
      },
      permissions: {
        download: true
      }
    }
    DownloadLinkElement = React.createElement(DownloadLink, @props)
    component = TestUtils.renderIntoDocument(DownloadLinkElement)
    node = component.getDOMNode()
    link = node.querySelectorAll('a')[0]
    equal link.tagName, 'A', 'tag should be link'
    ok link.textContent.match(I18n.t("Download")),
      'should show download text'
    ReactDOM.unmountComponentAtNode(component.getDOMNode().parentNode)
