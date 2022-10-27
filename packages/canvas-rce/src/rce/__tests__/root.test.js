/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import ReactDOM from 'react-dom'
import {renderIntoDiv} from '../root'
import Bridge from '../../bridge'

describe('RceModule', () => {
  let target
  let props

  beforeEach(() => {
    const div = document.createElement('div')
    div.id = 'fixture'
    div.innerHTML = '<div id="flash_screenreader_holder" role="alert"/><div id="target"/>'
    document.body.appendChild(div)

    target = document.getElementById('target')

    props = {
      liveRegion: () => document.getElementById('flash_screenreader_holder'),
      editorOptions: () => {
        return {}
      },
      textareaId: 'textarea_id',
    }
  })

  afterEach(() => {
    document.body.removeChild(document.getElementById('fixture'))
    Bridge.focusEditor(null)
  })

  it('bridges newly rendered editors', done => {
    renderIntoDiv(target, props, rendered => {
      expect(Bridge.activeEditor()).toBe(rendered)
      done()
    })
  })

  it('handleUnmount unmounts root component', done => {
    const unmountSpy = jest.spyOn(ReactDOM, 'unmountComponentAtNode')

    renderIntoDiv(target, props, wrapper => {
      wrapper.props.handleUnmount()
      expect(unmountSpy).toHaveBeenCalledWith(target)
      done()
    })
  })
})
