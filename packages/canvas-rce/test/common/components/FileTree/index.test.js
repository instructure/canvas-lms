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

import assert from 'assert'
import React from 'react'
import FileTree from '../../../../src/common/components/FileTree/index'
import sd from 'skin-deep'
import ReactDOM from 'react-dom'
import sinon from 'sinon'

describe('FileTree/index', () => {
  let files, folders, folder, onToggle, onSelect, props

  beforeEach(() => {
    folders = {
      1: {
        id: 1,
        name: 'foo',
        loading: false,
        expanded: true,
        fileIds: [3],
        folderIds: [2]
      },
      2: {
        id: 2,
        name: 'bar',
        loading: false,
        fileIds: [],
        folderIds: []
      }
    }
    folder = folders[1]
    files = {
      3: {
        id: 3,
        name: 'baz',
        type: 'text/plain'
      }
    }
    onToggle = sinon.spy()
    onSelect = sinon.spy()
    props = {folders, folder, files, onToggle, onSelect}
  })

  it('passes props to Folder component', () => {
    const tree = sd.shallowRender(<FileTree {...props} />)
    const folderProps = tree.subTree('Folder').props
    Object.keys(props).forEach(key => {
      assert(folderProps[key] === props[key])
    })
  })

  it('optionally sets max-height via prop', () => {
    props.maxHeight = '10em'
    const tree = sd.shallowRender(<FileTree {...props} />)
    assert.equal(tree.props.style.maxHeight, props.maxHeight)
  })

  describe('keyboard navigation', () => {
    let div, component, buttons, stopPropagation, DOWN_EVENT, UP_EVENT, OTHER_EVENT

    beforeEach(() => {
      stopPropagation = sinon.spy()
      DOWN_EVENT = {keyCode: 40, stopPropagation}
      UP_EVENT = {keyCode: 38, stopPropagation}
      OTHER_EVENT = {keyCode: 0, stopPropagation}

      div = document.createElement('div')
      document.body.appendChild(div)
      component = ReactDOM.render(<FileTree {...props} />, div)
      buttons = div.querySelectorAll('button')
    })

    afterEach(() => {
      document.body.removeChild(div)
    })

    it('focus the next button when down is pushed', () => {
      buttons[0].focus()
      component.handleKeyDown(DOWN_EVENT)
      assert(document.activeElement === buttons[1])
    })

    it('focus the previous button when up is pushed', () => {
      buttons[1].focus()
      component.handleKeyDown(UP_EVENT)
      assert(document.activeElement === buttons[0])
    })

    it('does not move focus up when on the first button', () => {
      buttons[0].focus()
      component.handleKeyDown(UP_EVENT)
      assert(document.activeElement === buttons[0])
    })

    it('does not move focus down when on the last button', () => {
      const lastIndex = buttons.length - 1
      buttons[lastIndex].focus()
      component.handleKeyDown(DOWN_EVENT)
      assert(document.activeElement === buttons[lastIndex])
    })

    it('stops event propagation when down is pushed', () => {
      component.handleKeyDown(DOWN_EVENT)
      sinon.assert.called(stopPropagation)
    })

    it('stops event propagation when up is pushed', () => {
      component.handleKeyDown(UP_EVENT)
      sinon.assert.called(stopPropagation)
    })

    it('does not stop event propagation when other keys are pushed', () => {
      component.handleKeyDown(OTHER_EVENT)
      sinon.assert.notCalled(stopPropagation)
    })
  })
})
