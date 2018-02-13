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
  'react'
  'react-dom'
  'react-addons-test-utils'
  'jquery'
  'jsx/files/UsageRightsIndicator'
  'compiled/models/Folder'
  'compiled/models/File'
], (React, ReactDOM, TestUtils, $, UsageRightsIndicator, Folder, File) ->

  QUnit.module 'UsageRightsIndicator'

  test 'returns null for folders', ->
    props = {
      model: new Folder(id: 3)
      usageRightsRequiredForContext: true
      modalOptions: {openModal: ()-> }
      userCanManageFilesForContext: false
    }

    uRI = TestUtils.renderIntoDocument(React.createElement(UsageRightsIndicator, props))
    equal uRI.getDOMNode(), null, "returns null"

  test 'returns null if no usageRightsRequiredForContext and the model has no usage_rights', ->
    props = {
      model: new File(id: 4)
      usageRightsRequiredForContext: true
      userCanManageFilesForContext: false
      modalOptions: {openModal: ()-> }
    }

    uRI = TestUtils.renderIntoDocument(React.createElement(UsageRightsIndicator, props))
    equal uRI.getDOMNode(), null, "returns null"

  test 'returns button if usageRightsRequiredForContext, userCanManageFilesForContext and the model has no usage_rights', ->
    props = {
      model: new File(id: 4)
      usageRightsRequiredForContext: true
      userCanManageFilesForContext: true
      modalOptions: {openModal: ()-> }
    }

    uRI = TestUtils.renderIntoDocument(React.createElement(UsageRightsIndicator, props))

    equal uRI.getDOMNode().type, "submit", "submit type"
    equal uRI.getDOMNode().tagName, "BUTTON", "tag name is a button"

    ReactDOM.unmountComponentAtNode(uRI.getDOMNode().parentNode)

  test "handleClick opens a modal with UsageRightsDialog", ->
    openedModal = false

    props = {
      model: new File(id: 4)
      usageRightsRequiredForContext: true
      userCanManageFilesForContext: true
      modalOptions: {openModal: ()-> openedModal = true}
    }

    uRI = TestUtils.renderIntoDocument(React.createElement(UsageRightsIndicator, props))
    TestUtils.Simulate.click(uRI.getDOMNode())

    ok openedModal, "tried to open the modal"

    ReactDOM.unmountComponentAtNode(uRI.getDOMNode().parentNode)


  QUnit.module "UsageRightsIndicator: Icon Classess & Screenreader text",
    teardown: ->
      ReactDOM.unmountComponentAtNode(@uRI.getDOMNode().parentNode)

    renderIndicator: (usage_rights) ->
      props = {
        model: new File(id: 4, usage_rights: usage_rights)
        usageRightsRequiredForContext: false
        userCanManageFilesForContext: true
        modalOptions: {openModal: ()-> }
      }

      @uRI = TestUtils.renderIntoDocument(React.createElement(UsageRightsIndicator, props))

  test "own_copyright class and screenreader text", ->
    usage_rights = {
      use_justification: "own_copyright"
      license_name: "best license ever"
    }

    uRI = @renderIndicator(usage_rights)

    equal uRI.refs.icon.getDOMNode().className, "icon-files-copyright", "has correct class"
    equal uRI.refs.screenreaderText.getDOMNode().innerHTML, "Own Copyright", "has correct screenreader text"

  test "public_domain class", ->
    usage_rights = {
      use_justification: "public_domain"
      license_name: "best license ever"
    }

    uRI = @renderIndicator(usage_rights)

    equal uRI.refs.icon.getDOMNode().className, "icon-files-public-domain", "has correct class"
    equal uRI.refs.screenreaderText.getDOMNode().innerHTML, "Public Domain", "has correct screenreader text"

  test "used_by_permission class", ->
    usage_rights = {
      use_justification: "used_by_permission"
      license_name: "best license ever"
    }

    uRI = @renderIndicator(usage_rights)

    equal uRI.refs.icon.getDOMNode().className, "icon-files-obtained-permission", "has correct class"
    equal uRI.refs.screenreaderText.getDOMNode().innerHTML, "Used by Permission", "has correct screenreader text"

  test "fair_use class", ->
    usage_rights = {
      use_justification: "fair_use"
      license_name: "best license ever"
    }

    uRI = @renderIndicator(usage_rights)

    equal uRI.refs.icon.getDOMNode().className, "icon-files-fair-use", "has correct class"
    equal uRI.refs.screenreaderText.getDOMNode().innerHTML, "Fair Use", "has correct screenreader text"

  test "creative_commons class", ->
    usage_rights = {
      use_justification: "creative_commons"
      license_name: "best license ever"
    }

    uRI = @renderIndicator(usage_rights)

    equal uRI.refs.icon.getDOMNode().className, "icon-files-creative-commons", "has correct class"
    equal uRI.refs.screenreaderText.getDOMNode().innerHTML, "Creative Commons", "has correct screenreader text"
