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
import UsageRightsIndicator from '@canvas/files/react/components/UsageRightsIndicator'
import Folder from '@canvas/files/backbone/models/Folder'
import File from '@canvas/files/backbone/models/File'

QUnit.module('UsageRightsIndicator')

test('returns null for folders', () => {
  const props = {
    model: new Folder({id: 3}),
    usageRightsRequiredForContext: true,
    modalOptions: {
      openModal() {},
    },
    userCanEditFilesForContext: false,
  }
  const uRI = TestUtils.renderIntoDocument(<UsageRightsIndicator {...props} />)
  equal(ReactDOM.findDOMNode(uRI), null, 'returns null')
})

test('returns null if no usageRightsRequiredForContext and the model has no usage_rights', () => {
  const props = {
    model: new File({id: 4}),
    usageRightsRequiredForContext: true,
    userCanEditFilesForContext: false,
    modalOptions: {
      openModal() {},
    },
  }
  const uRI = TestUtils.renderIntoDocument(<UsageRightsIndicator {...props} />)
  equal(ReactDOM.findDOMNode(uRI), null, 'returns null')
})

test('returns button if usageRightsRequiredForContext, userCanEditFilesForContext and the model has no usage_rights', () => {
  const props = {
    model: new File({id: 4}),
    usageRightsRequiredForContext: true,
    userCanEditFilesForContext: true,
    modalOptions: {
      openModal() {},
    },
  }
  const uRI = TestUtils.renderIntoDocument(<UsageRightsIndicator {...props} />)
  equal(ReactDOM.findDOMNode(uRI).type, 'submit', 'submit type')
  equal(ReactDOM.findDOMNode(uRI).tagName, 'BUTTON', 'tag name is a button')
  ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(uRI).parentNode)
})

test('handleClick opens a modal with UsageRightsDialog', () => {
  let openedModal = false
  const props = {
    model: new File({id: 4}),
    usageRightsRequiredForContext: true,
    userCanEditFilesForContext: true,
    modalOptions: {
      openModal() {
        return (openedModal = true)
      },
    },
  }
  const uRI = TestUtils.renderIntoDocument(<UsageRightsIndicator {...props} />)
  TestUtils.Simulate.click(ReactDOM.findDOMNode(uRI))
  ok(openedModal, 'tried to open the modal')
  ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(uRI).parentNode)
})

test('displays publish warning', () => {
  const props = {
    model: new File({id: 4}),
    usageRightsRequiredForContext: true,
    userCanEditFilesForContext: true,
    modalOptions: {
      openModal() {},
    },
    suppressWarning: false,
  }
  const uRI = TestUtils.renderIntoDocument(<UsageRightsIndicator {...props} />)
  equal(
    ReactDOM.findDOMNode(uRI).getAttribute('title'),
    'Before publishing this file, you must specify usage rights.',
    'has warning text'
  )
  equal(
    ReactDOM.findDOMNode(uRI).textContent,
    'Before publishing this file, you must specify usage rights.',
    'has warning text'
  )
  ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(uRI).parentNode)
})

test('suppresses publish warning', () => {
  const props = {
    model: new File({id: 4}),
    usageRightsRequiredForContext: true,
    userCanEditFilesForContext: true,
    modalOptions: {
      openModal() {},
    },
    suppressWarning: true,
  }
  const uRI = TestUtils.renderIntoDocument(<UsageRightsIndicator {...props} />)
  notEqual(
    ReactDOM.findDOMNode(uRI).getAttribute('title'),
    'Before publishing this file, you must specify usage rights.',
    'has warning text'
  )
  notEqual(
    ReactDOM.findDOMNode(uRI).textContent,
    'Before publishing this file, you must specify usage rights.',
    'has warning text'
  )
  ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(uRI).parentNode)
})

QUnit.module('UsageRightsIndicator: Icon Classess & Screenreader text', {
  teardown() {
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.uRI).parentNode)
  },

  renderIndicator(usage_rights) {
    const props = {
      model: new File({id: 4, usage_rights}),
      usageRightsRequiredForContext: false,
      userCanEditFilesForContext: true,
      modalOptions: {
        openModal() {},
      },
    }
    return (this.uRI = TestUtils.renderIntoDocument(<UsageRightsIndicator {...props} />))
  },
})

test('own_copyright class and screenreader text', function () {
  const usage_rights = {
    use_justification: 'own_copyright',
    license_name: 'best license ever',
  }
  const uRI = this.renderIndicator(usage_rights)
  equal(uRI.refs.icon.className, 'icon-files-copyright', 'has correct class')
  equal(uRI.refs.screenreaderText.innerHTML, 'Own Copyright', 'has correct screenreader text')
})

test('public_domain class', function () {
  const usage_rights = {
    use_justification: 'public_domain',
    license_name: 'best license ever',
  }
  const uRI = this.renderIndicator(usage_rights)
  equal(uRI.refs.icon.className, 'icon-files-public-domain', 'has correct class')
  equal(uRI.refs.screenreaderText.innerHTML, 'Public Domain', 'has correct screenreader text')
})

test('used_by_permission class', function () {
  const usage_rights = {
    use_justification: 'used_by_permission',
    license_name: 'best license ever',
  }
  const uRI = this.renderIndicator(usage_rights)
  equal(uRI.refs.icon.className, 'icon-files-obtained-permission', 'has correct class')
  equal(uRI.refs.screenreaderText.innerHTML, 'Used by Permission', 'has correct screenreader text')
})

test('fair_use class', function () {
  const usage_rights = {
    use_justification: 'fair_use',
    license_name: 'best license ever',
  }
  const uRI = this.renderIndicator(usage_rights)
  equal(uRI.refs.icon.className, 'icon-files-fair-use', 'has correct class')
  equal(uRI.refs.screenreaderText.innerHTML, 'Fair Use', 'has correct screenreader text')
})

test('creative_commons class', function () {
  const usage_rights = {
    use_justification: 'creative_commons',
    license_name: 'best license ever',
  }
  const uRI = this.renderIndicator(usage_rights)
  equal(uRI.refs.icon.className, 'icon-files-creative-commons', 'has correct class')
  equal(uRI.refs.screenreaderText.innerHTML, 'Creative Commons', 'has correct screenreader text')
})
