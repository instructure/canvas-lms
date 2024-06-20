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

import {isNull} from 'lodash'
import React from 'react'
import ReactDOM from 'react-dom'
import TestUtils from 'react-dom/test-utils'
import DownloadLink from '../DownloadLink'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('epub_exports')

describe('DownloadLink', () => {
  let props

  beforeEach(() => {
    props = {
      course: {
        name: 'Maths 101',
        id: 1,
      },
    }
  })

  test('state showDownloadLink', () => {
    let DownloadLinkElement = <DownloadLink {...props} />
    let component = TestUtils.renderIntoDocument(DownloadLinkElement)
    expect(component.showDownloadLink()).toBeFalsy() // should be false without epub_export object

    props.course.epub_export = {permissions: {download: false}}
    DownloadLinkElement = <DownloadLink {...props} />
    component = TestUtils.renderIntoDocument(DownloadLinkElement)
    expect(component.showDownloadLink()).toBeFalsy() // should be false without permissions to download

    props.course.epub_export = {
      epub_attachment: {url: 'http://download.url'},
      permissions: {download: true},
    }
    DownloadLinkElement = <DownloadLink {...props} />
    component = TestUtils.renderIntoDocument(DownloadLinkElement)
    expect(component.showDownloadLink()).toBeTruthy() // should be true with permissions to download

    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(component).parentNode)
  })

  test('render', () => {
    let DownloadLinkElement = <DownloadLink {...props} />
    let component = TestUtils.renderIntoDocument(DownloadLinkElement)
    let node = ReactDOM.findDOMNode(component)
    expect(isNull(node)).toBeTruthy()

    props.course.epub_export = {
      epub_attachment: {url: 'http://download.url'},
      permissions: {download: true},
    }
    DownloadLinkElement = <DownloadLink {...props} />
    component = TestUtils.renderIntoDocument(DownloadLinkElement)
    node = ReactDOM.findDOMNode(component)

    const link = node.querySelectorAll('a')[0]
    expect(link.tagName).toBe('A') // tag should be link
    expect(link.textContent).toMatch(I18n.t('Download')) // should show download text

    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(component).parentNode)
  })
})
