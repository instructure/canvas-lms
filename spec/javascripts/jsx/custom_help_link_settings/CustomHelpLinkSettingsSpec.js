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

define([
  'react',
  'react-dom',
  'jsx/custom_help_link_settings/CustomHelpLinkSettings'
], (React, ReactDOM, CustomHelpLinkSettings) => {

  const container = document.getElementById('fixtures')

  QUnit.module('<CustomHelpLinkSettings/>', {
    render(overrides={}) {
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
            available_to: ['user','student','teacher','admin'],
            text: 'Search the Canvas Guides',
            subtext: 'Find answers to common questions',
            url: 'http://community.canvaslms.com/community/answers/guides',
            type: 'default'
          },
          {
            available_to: ['user','student','teacher','admin'],
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

  test('render()', function () {
    const subject = this.render()
    ok(ReactDOM.findDOMNode(subject))
  })

  test('accepts properly formatted urls', function () {
    const subject = this.render()

    let link = {
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
})
