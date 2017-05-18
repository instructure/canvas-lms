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
  'jsx/help_dialog/CreateTicketForm'
], (React, ReactDOM, CreateTicketForm) => {

  const container = document.getElementById('fixtures')

  QUnit.module('<CreateTicketForm/>', {
    render(overrides={}) {
      const props = {
        ...overrides
      }

      return ReactDOM.render(<CreateTicketForm {...props} />, container)
    },
    teardown() {
      ReactDOM.unmountComponentAtNode(container)
    }
  })

  test('render()', function () {
    const subject = this.render()
    ok(ReactDOM.findDOMNode(subject))
  })
})
