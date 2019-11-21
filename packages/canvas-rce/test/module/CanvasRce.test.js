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

import React from 'react'
import assert from 'assert'
import proxyquire from 'proxyquire'
import Bridge from '../../src/bridge'
import sinon from 'sinon'
import ReactDOM from 'react-dom'

class fakeRCEWrapper extends React.Component {
  static displayName() {
    return 'FakeRCEWrapper'
  }

  render() {
    return null
  }
}

fakeRCEWrapper['@noCallThru'] = true

const CanvasRce = proxyquire('../../src/rce/CanvasRce', {
  './RCEWrapper': fakeRCEWrapper,
  './tinyRCE': {
    '@noCallThru': true,
    DOM: {loadCSS: () => {}}
  },
  '../../locales/index': {'@noCallThru': true}
}).default

describe('CanvasRce', () => {
  let target

  beforeEach(() => {
    target = document.createElement('div')
    document.body.appendChild(target)
  })

  const renderCanvasRce = props => {
    const mergedProps = {
      rceProps: {
        editorOptions: () => {
          return {}
        },
        textareaId: 'someUniqueId',
        language: 'en'
      },
      ...props
    }
    ReactDOM.render(<CanvasRce {...mergedProps} />, target)
  }

  afterEach(() => {
    Bridge.focusEditor(null)
  })

  it('bridges newly rendered editors', done => {
    const renderCallback = rendered => {
      assert.equal(Bridge.activeEditor(), rendered)
      done()
    }
    renderCanvasRce({renderCallback})
  })
})
