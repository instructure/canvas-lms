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

define(
  ['react', 'react-addons-test-utils', 'jsx/collaborations/GettingStartedCollaborations'],
  (React, TestUtils, GettingStartedCollaborations) => {
    QUnit.module('GettingStartedCollaborations')

    function setEnvironment(roles, context) {
      ENV.context_asset_string = context
      ENV.current_user_roles = roles
    }

    test('renders the Getting Startted app div', () => {
      setEnvironment([], 'course_4')
      let props = {ltiCollaborators: {ltiCollaboratorsData: ['test']}}
      let component = TestUtils.renderIntoDocument(<GettingStartedCollaborations {...props} />)
      ok(TestUtils.findRenderedDOMComponentWithClass(component, 'GettingStartedCollaborations'))
    })

    test('renders the correct content with lti tools configured as a teacher', () => {
      setEnvironment(['teacher'], 'course_4')
      let props = {ltiCollaborators: {ltiCollaboratorsData: ['test']}}
      let component = TestUtils.renderIntoDocument(<GettingStartedCollaborations {...props} />)
      let actualHeader = TestUtils.findRenderedDOMComponentWithClass(
        component,
        'ic-Action-header__Heading'
      ).getDOMNode().innerText
      const actualContent = TestUtils.findRenderedDOMComponentWithTag(component, 'p').getDOMNode()
        .innerText
      const actualLinkText = TestUtils.findRenderedDOMComponentWithTag(component, 'a').getDOMNode()
        .innerText
      const expectedHeader = 'Getting started with Collaborations'
      const expectedContent =
        'Collaborations are web-based tools to work collaboratively on tasks like taking notes or grouped papers. Get started by clicking on the "+ Collaboration" button.'
      const expectedLinkText = 'Learn more about collaborations'
      ok(expectedHeader === actualHeader)
      ok(expectedContent === actualContent)
      ok(expectedLinkText === actualLinkText)
    })

    test('renders the correct content with no lti tools configured data as a teacher', () => {
      setEnvironment(['teacher'], 'course_4')
      let props = {ltiCollaborators: {ltiCollaboratorsData: []}}
      let component = TestUtils.renderIntoDocument(<GettingStartedCollaborations {...props} />)
      const actualContent = TestUtils.findRenderedDOMComponentWithTag(component, 'p').getDOMNode()
        .innerText
      const actualHeader = TestUtils.findRenderedDOMComponentWithClass(
        component,
        'ic-Action-header__Heading'
      ).getDOMNode().innerText
      const actualLinkText = TestUtils.findRenderedDOMComponentWithTag(component, 'a').getDOMNode()
        .innerText
      const expectedHeader = 'No Collaboration Apps'
      const expectedContent =
        'Collaborations are web-based tools to work collaboratively on tasks like taking notes or grouped papers. Get started by adding a collaboration app.'
      const expectedLinkText = 'Learn more about collaborations'
      ok(expectedHeader === actualHeader)
      ok(expectedContent === actualContent)
      ok(expectedLinkText === actualLinkText)
    })

    test('renders the correct content with no collaborations data as a student', () => {
      setEnvironment(['student'], 'course_4')
      let props = {ltiCollaborators: {ltiCollaboratorsData: []}}
      let component = TestUtils.renderIntoDocument(<GettingStartedCollaborations {...props} />)
      const actualContent = TestUtils.findRenderedDOMComponentWithTag(component, 'p').getDOMNode()
        .innerText
      const actualHeader = TestUtils.findRenderedDOMComponentWithClass(
        component,
        'ic-Action-header__Heading'
      ).getDOMNode().innerText
      const expectedHeader = 'No Collaboration Apps'
      const expectedContent =
        'You have no Collaboration apps configured. Talk to your teacher to get some set up.'
      ok(expectedHeader === actualHeader)
      ok(expectedContent === actualContent)
      ok(TestUtils.scryRenderedDOMComponentsWithTag(component, 'a').length === 0)
    })

    test('renders the correct content with lti tools configured as a student', () => {
      setEnvironment(['student'], 'course_4')
      let props = {ltiCollaborators: {ltiCollaboratorsData: ['test']}}
      let component = TestUtils.renderIntoDocument(<GettingStartedCollaborations {...props} />)
      let actualHeader = TestUtils.findRenderedDOMComponentWithClass(
        component,
        'ic-Action-header__Heading'
      ).getDOMNode().innerText
      const actualContent = TestUtils.findRenderedDOMComponentWithTag(component, 'p').getDOMNode()
        .innerText
      const actualLinkText = TestUtils.findRenderedDOMComponentWithTag(component, 'a').getDOMNode()
        .innerText
      const expectedHeader = 'Getting started with Collaborations'
      const expectedContent =
        'Collaborations are web-based tools to work collaboratively on tasks like taking notes or grouped papers. Get started by clicking on the "+ Collaboration" button.'
      const expectedLinkText = 'Learn more about collaborations'
      ok(expectedHeader === actualHeader)
      ok(expectedContent === actualContent)
      ok(expectedLinkText === actualLinkText)
    })
  }
)
