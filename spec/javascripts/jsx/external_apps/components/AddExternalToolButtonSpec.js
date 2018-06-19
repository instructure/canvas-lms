/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import $ from 'jquery'
import React from 'react'
import { mount } from 'enzyme'
import AddExternalToolButton from 'jsx/external_apps/components/AddExternalToolButton'

let spy

QUnit.module('AddExternalToolButton#handleLti2ToolInstalled flash errors', {
  setup () {
    spy = sinon.spy($, 'flashError')
  },

  teardown () {
    $.flashError.restore()
  }
})

test('it displays a flash message from the tool when there is an error', () => {
  const wrapper = mount(<AddExternalToolButton />)
  const toolData = {
    status: 'failure',
    message: 'Something bad happened'
  }
  wrapper.instance().handleLti2ToolInstalled(toolData)
  ok(spy.calledWith('Something bad happened'))
})

test('it displays a default flash message when there is an error without a message', () => {
  const wrapper = mount(<AddExternalToolButton />)
  const toolData = {
    status: 'failure'
  }
  wrapper.instance().handleLti2ToolInstalled(toolData)
  ok(spy.calledWith('There was an unknown error registering the tool'))
})

