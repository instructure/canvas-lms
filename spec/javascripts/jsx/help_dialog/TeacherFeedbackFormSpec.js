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
  'jquery',
  'jsx/help_dialog/TeacherFeedbackForm',
  'jquery.ajaxJSON'
], (React, ReactDOM, jQuery, TeacherFeedbackForm) => {

  const container = document.getElementById('fixtures')
  let server

  QUnit.module('<TeacherFeedbackForm/>', {
    setup () {
      server = sinon.fakeServer.create()

      // This is a POST rather than a PUT because of the way our $.getJSON converts
      // non-GET requests to posts anyways.
      server.respondWith('GET', /api\/v1\/courses.json/,
        [200, { "Content-Type": "application/json" }, JSON.stringify([])]
      );

      sandbox.stub(jQuery, 'ajaxJSON')
    },
    render (overrides={}) {
      const props = {
        ...overrides
      }

      return ReactDOM.render(<TeacherFeedbackForm {...props} />, container)
    },
    teardown() {
      ReactDOM.unmountComponentAtNode(container)
      server.restore()
    }
  })

  test('render()', function () {
    const subject = this.render()
    ok(ReactDOM.findDOMNode(subject))

    server.respond()
  })
})
