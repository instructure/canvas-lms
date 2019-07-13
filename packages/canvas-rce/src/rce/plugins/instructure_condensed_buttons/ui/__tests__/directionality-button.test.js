/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import directionalityButton from '../directionality-button'

function fakeEditor() {
  return new (class {
    $svgContainer = {
      html: jest.fn()
    }
    $ = jest.fn(() => this.$svgContainer)
    editorContainer = {
      querySelector: jest.fn()
    }
    execCommand = jest.fn()
    nodeChanged = jest.fn()
    on = jest.fn()
    off = jest.fn()
    selection = {
      getNode: jest.fn()
    }
    dom = {
      getParent: jest.fn(),
      getRoot: jest.fn(() => 'getRoot'),
      is: jest.fn()
    }
    ui = {
      registry: {
        addSplitButton: jest.fn(),
        getAll: jest.fn(() => ({
          icons: {
            ltr: 'ltr-icon',
            rtl: 'rtl-icon'
          }
        }))
      }
    }
  })()
}

function commandFromDirection(direction) {
  return `mceDirection${direction.toUpperCase()}`
}

describe('directionality-button', () => {
  let editor
  let addSplitButton
  let splitButton

  function setCurrentDirection(currentDirection) {
    const originalLength = addSplitButton.mock.calls.length
    editor.dom.getParent.mockImplementation((node, selector) => {
      return selector.match(`\\[dir=${currentDirection}\\]`)
    })
    directionalityButton(editor)
    splitButton = addSplitButton.mock.calls[originalLength][1]
  }

  ;['ltr', 'rtl'].forEach(direction => {
    const oppositeDirection = direction === 'ltr' ? 'rtl' : 'ltr'

    describe(direction, () => {
      const originalDirection = document.dir
      beforeAll(() => (document.dir = direction))
      afterAll(() => (document.dir = originalDirection))

      beforeEach(() => {
        editor = fakeEditor()
        addSplitButton = editor.ui.registry.addSplitButton
        directionalityButton(editor)
        splitButton = addSplitButton.mock.calls[0][1]
      })

      it('calls split button with proper label', () => {
        expect(addSplitButton).toHaveBeenCalledWith('directionality', expect.anything())
      })

      it('fetch callback invoked with the proper direction first', () => {
        const fetchCallback = jest.fn()
        splitButton.fetch(fetchCallback)
        expect(fetchCallback.mock.calls[0][0]).toEqual([
          expect.objectContaining({
            type: 'choiceitem',
            value: commandFromDirection(direction),
            icon: direction
          }),
          expect.objectContaining({
            type: 'choiceitem',
            value: commandFromDirection(oppositeDirection),
            icon: oppositeDirection
          })
        ])
      })

      it('onAction execs opposite directionality command by default', () => {
        splitButton.onAction()
        expect(editor.execCommand).toHaveBeenCalledWith(commandFromDirection(oppositeDirection))
      })

      it('onAction execs current directionality command when current directionality is set', () => {
        setCurrentDirection(direction)
        splitButton.onAction()
        expect(editor.execCommand).toHaveBeenCalledWith(commandFromDirection(direction))
      })

      it("onItemAction execs the associated button's action", () => {
        splitButton.onItemAction('mock api', commandFromDirection(direction))
      })

      it('select returns false if no current directionality is set', () => {
        const matchingResult = splitButton.select(commandFromDirection(direction))
        expect(matchingResult).toBeFalsy()
        const oppositeResult = splitButton.select(commandFromDirection(oppositeDirection))
        expect(oppositeResult).toBeFalsy()
      })

      it('select returns true for current direction and false for opposite direction', () => {
        setCurrentDirection(direction)
        const matchingResult = splitButton.select(commandFromDirection(direction))
        expect(matchingResult).toBeTruthy()
        const oppositeResult = splitButton.select(commandFromDirection(oppositeDirection))
        expect(oppositeResult).toBeFalsy()
      })

      it('onSetup nodeChangeHandler calls api.setActive(false) when there is no current direction', () => {
        const api = {setActive: jest.fn()}
        let nodeChangeHandler
        editor.on.mockImplementation((e, f) => (nodeChangeHandler = f))
        splitButton.onSetup(api)
        nodeChangeHandler()
        expect(api.setActive).toHaveBeenCalledWith(false)
      })

      it('onSetup nodeChangeHandler calls api.setActive with current directionality', () => {
        setCurrentDirection(direction)
        const api = {setActive: jest.fn()}
        let nodeChangeHandler
        editor.on.mockImplementation((e, f) => (nodeChangeHandler = f))
        splitButton.onSetup(api)
        nodeChangeHandler()
        expect(api.setActive).toHaveBeenCalledWith(true)
      })

      it('onSetup sets the icon to the opposite directionality when there is no current direction', () => {
        const api = {setActive: jest.fn()}
        let nodeChangeHandler
        editor.on.mockImplementation((e, f) => (nodeChangeHandler = f))
        splitButton.onSetup(api)
        nodeChangeHandler()
        expect(editor.$svgContainer.html).toHaveBeenCalledWith(`${oppositeDirection}-icon`)
      })

      it('onSetup nodeChangeHandler sets the icon based on current directionality', () => {
        setCurrentDirection(direction)
        const api = {setActive: jest.fn()}
        let nodeChangeHandler
        editor.on.mockImplementation((e, f) => (nodeChangeHandler = f))
        splitButton.onSetup(api)
        nodeChangeHandler()
        expect(editor.$svgContainer.html).toHaveBeenCalledWith(`${direction}-icon`)
      })

      it('onSetup returns a function that calls editor.off', () => {
        const api = {setActive: jest.fn()}
        let nodeChangeHandler
        editor.on.mockImplementation((e, f) => (nodeChangeHandler = f))
        const result = splitButton.onSetup(api)
        result()
        expect(editor.off).toHaveBeenCalledWith('NodeChange', nodeChangeHandler)
      })
    })
  })
})
