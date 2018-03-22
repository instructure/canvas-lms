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
import TestUtils from 'react-addons-test-utils'
import $ from 'jquery'
import UsageRightsIndicator from 'jsx/files/UsageRightsIndicator'
import Folder from 'compiled/models/Folder'
import File from 'compiled/models/File'

QUnit.module('UsageRightsIndicator')

test('returns null for folders', () => {
  const props = {
    model: new Folder({id: 3}),
    usageRightsRequiredForContext: true,
    modalOptions: {
      openModal() {}
    },
    userCanManageFilesForContext: false
  }
  const uRI = TestUtils.renderIntoDocument(<UsageRightsIndicator {...props} />)
  equal(uRI.getDOMNode(), null, 'returns null')
})

test('returns null if no usageRightsRequiredForContext and the model has no usage_rights', () => {
  const props = {
    model: new File({id: 4}),
    usageRightsRequiredForContext: true,
    userCanManageFilesForContext: false,
    modalOptions: {
      openModal() {}
    }
  }
  const uRI = TestUtils.renderIntoDocument(<UsageRightsIndicator {...props} />)
  equal(uRI.getDOMNode(), null, 'returns null')
})

test('returns button if usageRightsRequiredForContext, userCanManageFilesForContext and the model has no usage_rights', () => {
  const props = {
    model: new File({id: 4}),
    usageRightsRequiredForContext: true,
    userCanManageFilesForContext: true,
    modalOptions: {
      openModal() {}
    }
  }
  const uRI = TestUtils.renderIntoDocument(<UsageRightsIndicator {...props} />)
  equal(uRI.getDOMNode().type, 'submit', 'submit type')
  equal(uRI.getDOMNode().tagName, 'BUTTON', 'tag name is a button')
  ReactDOM.unmountComponentAtNode(uRI.getDOMNode().parentNode)
})

test('handleClick opens a modal with UsageRightsDialog', () => {
  let openedModal = false
  const props = {
    model: new File({id: 4}),
    usageRightsRequiredForContext: true,
    userCanManageFilesForContext: true,
    modalOptions: {
      openModal() {
        return (openedModal = true)
      }
    }
  }
  const uRI = TestUtils.renderIntoDocument(<UsageRightsIndicator {...props} />)
  TestUtils.Simulate.click(uRI.getDOMNode())
  ok(openedModal, 'tried to open the modal')
  ReactDOM.unmountComponentAtNode(uRI.getDOMNode().parentNode)
})

QUnit.module('UsageRightsIndicator: Icon Classess & Screenreader text', {
  teardown() {
    ReactDOM.unmountComponentAtNode(this.uRI.getDOMNode().parentNode)
  },

  renderIndicator(usage_rights) {
    const props = {
      model: new File({id: 4, usage_rights}),
      usageRightsRequiredForContext: false,
      userCanManageFilesForContext: true,
      modalOptions: {
        openModal() {}
      }
    }
    return (this.uRI = TestUtils.renderIntoDocument(<UsageRightsIndicator {...props} />))
  }
})

test('own_copyright class and screenreader text', function() {
  const usage_rights = {
    use_justification: 'own_copyright',
    license_name: 'best license ever'
  }
  const uRI = this.renderIndicator(usage_rights)
  equal(uRI.refs.icon.getDOMNode().className, 'icon-files-copyright', 'has correct class')
  equal(
    uRI.refs.screenreaderText.getDOMNode().innerHTML,
    'Own Copyright',
    'has correct screenreader text'
  )
})

test('public_domain class', function() {
  const usage_rights = {
    use_justification: 'public_domain',
    license_name: 'best license ever'
  }
  const uRI = this.renderIndicator(usage_rights)
  equal(uRI.refs.icon.getDOMNode().className, 'icon-files-public-domain', 'has correct class')
  equal(
    uRI.refs.screenreaderText.getDOMNode().innerHTML,
    'Public Domain',
    'has correct screenreader text'
  )
})

test('used_by_permission class', function() {
  const usage_rights = {
    use_justification: 'used_by_permission',
    license_name: 'best license ever'
  }
  const uRI = this.renderIndicator(usage_rights)
  equal(uRI.refs.icon.getDOMNode().className, 'icon-files-obtained-permission', 'has correct class')
  equal(
    uRI.refs.screenreaderText.getDOMNode().innerHTML,
    'Used by Permission',
    'has correct screenreader text'
  )
})

test('fair_use class', function() {
  const usage_rights = {
    use_justification: 'fair_use',
    license_name: 'best license ever'
  }
  const uRI = this.renderIndicator(usage_rights)
  equal(uRI.refs.icon.getDOMNode().className, 'icon-files-fair-use', 'has correct class')
  equal(
    uRI.refs.screenreaderText.getDOMNode().innerHTML,
    'Fair Use',
    'has correct screenreader text'
  )
})

test('creative_commons class', function() {
  const usage_rights = {
    use_justification: 'creative_commons',
    license_name: 'best license ever'
  }
  const uRI = this.renderIndicator(usage_rights)
  equal(uRI.refs.icon.getDOMNode().className, 'icon-files-creative-commons', 'has correct class')
  equal(
    uRI.refs.screenreaderText.getDOMNode().innerHTML,
    'Creative Commons',
    'has correct screenreader text'
  )
})
