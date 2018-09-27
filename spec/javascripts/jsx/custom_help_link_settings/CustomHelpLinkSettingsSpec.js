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

import React from 'react'

import ReactDOM from 'react-dom'
import CustomHelpLinkSettings from 'jsx/custom_help_link_settings/CustomHelpLinkSettings'
import $ from 'jquery'

const container = document.getElementById('fixtures')

QUnit.module('<CustomHelpLinkSettings/>', {
  render(overrides = {}) {
    const props = {
      name: 'Help',
      icon: 'help',
      links: [],
      defaultLinks: [
        {
          available_to: ['student'],
          text: 'Ask Your Instructor a Question',
          subtext: 'Questions are submitted to your instructor',
          url: '#teacher_feedback',
          type: 'default'
        },
        {
          available_to: ['user', 'student', 'teacher', 'admin'],
          text: 'Search the Canvas Guides',
          subtext: 'Find answers to common questions',
          url: 'http://community.canvaslms.com/community/answers/guides',
          type: 'default'
        },
        {
          available_to: ['user', 'student', 'teacher', 'admin'],
          text: 'Report a Problem',
          subtext: 'If Canvas misbehaves, tell us about it',
          url: '#create_ticket',
          type: 'default'
        }
      ],
      ...overrides
    }

    return ReactDOM.render(<CustomHelpLinkSettings {...props} />, container)
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(container)
  }
})

test('render()', function() {
  const subject = this.render()
  ok(ReactDOM.findDOMNode(subject))
})

test('accepts properly formatted urls', function() {
  const subject = this.render()

  const link = {
    text: 'test link',
    available_to: ['user', 'student', 'teacher', 'admin'],
    url: ''
  }

  link.url = 'http://testurl.com'
  ok(subject.validate(link))

  link.url = 'https://testurl.com'
  ok(subject.validate(link))

  link.url = 'ftp://test.url/.test'
  ok(subject.validate(link))

  link.url = 'tel:1-999-999-9999'
  ok(subject.validate(link))

  link.url = 'mailto:test@test.com'
  ok(subject.validate(link))
})

test('assigns unique link ids', function() {
  const subject = this.render({
    links: [
      {
        id: 'link1',
        available_to: ['student'],
        text: 'Blah',
        url: '#blah',
        type: 'custom'
      },
      {
        id: 'link3',
        available_to: ['student'],
        text: 'Bleh',
        url: '#bleh',
        type: 'custom'
      }
    ]
  })
  subject.add({text: 'eh', url: 'ftp://eh', available_to: ['student']})
  equal(subject.state.links.find(link => link.text === 'eh').id, 'link4')
})

test('calls flashScreenreaderAlert when appropriate', function() {
  sinon.spy($, 'screenReaderFlashMessage')
  const subject = this.render({name: ''})
  subject.validateName({target: subject})
  // flash message when transitions to invalid
  equal($.screenReaderFlashMessage.callCount, 1)

  // no flash message as long as is invalid
  subject.validateName({target: subject})
  equal($.screenReaderFlashMessage.callCount, 1)
  equal(subject.state.isNameValid, false)

  // it's valid now
  subject.value = 'foo'
  subject.validateName({target: subject})
  equal($.screenReaderFlashMessage.callCount, 1)
  equal(subject.state.isNameValid, true)

  // and invalid again, show message
  subject.value = ''
  subject.validateName({target: subject})
  equal($.screenReaderFlashMessage.callCount, 2)
  equal(subject.state.isNameValid, false)

  $.screenReaderFlashMessage.restore()
})
