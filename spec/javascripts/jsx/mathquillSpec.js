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
import 'jquery.instructure_misc_helpers'
import 'mathquill'

let view, container, toolbar

QUnit.module('MathML and MathJax test', {
  setup () {
    view = document.createElement('div')
    view.id = 'mathquill-view'
    toolbar = document.createElement('div')
    document.body.appendChild(view)
    view.appendChild(toolbar)
    container = document.createElement('div')
    view.appendChild(container)
    toolbar.className = 'mathquill-toolbar'
    $(container).mathquill('editor')
  },

  teardown () {
    document.body.removeChild(view)
  }
})

test('tab links work with url encoded characters in panel id', () => {
  const tab = toolbar.querySelector('.mathquill-tab-bar li:nth-child(2) a')
  const pane = toolbar.querySelector('.mathquill-tab-pane:nth-child(2)')
  tab.setAttribute('href', '#Græsk_tab')
  pane.id = 'Græsk_tab'
  tab.click()
  ok(/selected/.exec(pane.className))
})
