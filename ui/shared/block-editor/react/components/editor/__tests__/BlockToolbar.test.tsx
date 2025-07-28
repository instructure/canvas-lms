/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {userEvent} from '@testing-library/user-event'
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import {useEditor, useNode, type Node} from '@craftjs/core'
import {render} from '@testing-library/react'
import {BlockToolbar, isBlockSaveable} from '../BlockToolbar'
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import {mountNode} from '../../../utils'
import {TemplateEditor} from '../../../types'

const user = userEvent.setup()

let upNode: any
let downNode: any
let mountDiv: HTMLDivElement | null = null
jest.mock('../../../utils', () => {
  return {
    ...jest.requireActual('../../../utils'),
    mountNode: jest.fn(() => mountDiv),
    findUpNode: jest.fn(() => upNode),
    findDownNode: jest.fn(() => downNode),
  }
})

const mockSelectNode = jest.fn()
const mockDelete = jest.fn()
const mockFocus = jest.fn()
let isMoveable = true
let isDeletable = true
let isSaveable = true
let customNoToolbar = false
let nodeCustomData: any = {
  noToolbar: customNoToolbar,
}
const dummyBlockToolbar = () => {
  return <div>Dummy Block Toolbar</div>
}
let blockOwnToolbar: React.ReactNode | null = dummyBlockToolbar()

const nodeDomNode = document.createElement('div')
nodeDomNode.id = 'nodeid'
nodeDomNode.setAttribute('tabindex', '-1')
nodeDomNode.style.width = '100px'
nodeDomNode.style.height = '125px'
// @ts-expect-error
nodeDomNode.getBoundingClientRect = jest.fn(() => {
  return {top: 0, left: 0, width: 100, height: 125}
})

jest.mock('@craftjs/core', () => {
  const module = jest.requireActual('@craftjs/core')
  return {
    ...module,
    useEditor: jest.fn(() => {
      return {
        actions: {
          selectNode: mockSelectNode,
          delete: mockDelete,
        },
        query: {
          node: (id: string) => {
            return {
              get: () => {
                return {
                  id,
                  dom: {
                    focus: mockFocus,
                  },
                  data: {
                    parent: undefined,
                  },
                }
              },
            }
          },
        },
      }
    }),

    useNode: jest.fn(() => {
      return {
        connectors: {
          drag: jest.fn(),
        },
        node: {
          id: 'nodeid',
          data: {
            custom: nodeCustomData,
          },
          related: {
            toolbar: blockOwnToolbar,
          },
          dom: nodeDomNode,
        },
        name: 'SomeBlock',
        moveable: isMoveable,
        deletable: isDeletable,
        saveable: isSaveable,
      }
    }),
  }
})

const activeElem = () => {
  return document.activeElement as Element
}

const renderBlockToolbar = (editor = TemplateEditor.NONE) => {
  return render(<BlockToolbar templateEditor={editor} />)
}

describe('BlockToolbar', () => {
  beforeEach(() => {
    mountDiv = document.createElement('div')
    mountDiv.id = 'mountNode'
    document.body.appendChild(nodeDomNode)
    document.body.appendChild(mountDiv)

    isMoveable = true
    isDeletable = true
    isSaveable = true
    customNoToolbar = false
    upNode = {
      id: 'upnode',
    }
    downNode = {
      id: 'upnode',
    }
    // @ts-expect-error
    blockOwnToolbar = dummyBlockToolbar
    nodeCustomData = {
      noToolbar: customNoToolbar,
    }
  })

  afterEach(() => {
    document.body.innerHTML = ''
  })

  it('should render', () => {
    const {getByText} = renderBlockToolbar()
    expect(getByText('SomeBlock')).toBeInTheDocument()
    expect(getByText('Drag to move')).toBeInTheDocument()
    expect(getByText('Go up')).toBeInTheDocument()
    expect(getByText('Go down')).toBeInTheDocument()
    expect(getByText('Delete')).toBeInTheDocument()
    expect(getByText('Save as template')).toBeInTheDocument()
    expect(getByText('Dummy Block Toolbar')).toBeInTheDocument()
  })

  it('should not render if no mount point', () => {
    mountDiv = null
    const {queryByText} = renderBlockToolbar()
    expect(queryByText('SomeBlock')).not.toBeInTheDocument()
  })

  it('should not render if custom.noToolbar is true', () => {
    nodeCustomData.noToolbar = true
    const {queryByText} = renderBlockToolbar()
    expect(queryByText('SomeBlock')).not.toBeInTheDocument()
  })

  it('should not show the drag handle if moveable is false', () => {
    isMoveable = false
    const {getByText, queryByText} = renderBlockToolbar()
    expect(getByText('SomeBlock')).toBeInTheDocument()
    expect(queryByText('Drag to move')).not.toBeInTheDocument()
  })

  it('should not show the left arrow if there is no upnode', () => {
    upNode = undefined
    const {getByText, queryByText} = renderBlockToolbar()
    expect(getByText('SomeBlock')).toBeInTheDocument()
    expect(queryByText('Go up')).not.toBeInTheDocument()
  })

  it('should not show the right arrow if there is no down node', () => {
    downNode = undefined
    const {queryByText, getByText} = renderBlockToolbar()
    expect(getByText('Go up')).toBeInTheDocument()
    expect(queryByText('Go down')).not.toBeInTheDocument()
  })

  it('should not show the delete button if deletable is false', () => {
    isDeletable = false
    const {getByText, queryByText} = renderBlockToolbar()
    expect(getByText('SomeBlock')).toBeInTheDocument()
    expect(queryByText('Delete')).not.toBeInTheDocument()
  })

  it("should not show not the block's own toolbar if not defined", () => {
    blockOwnToolbar = null
    const {queryByText} = renderBlockToolbar()
    expect(queryByText('Block Own Toolbar')).not.toBeInTheDocument()
  })

  it('should not show save as template if saveable is false', () => {
    isSaveable = false
    const {queryByText} = renderBlockToolbar(TemplateEditor.GLOBAL)
    expect(queryByText('Save as template')).not.toBeInTheDocument()
  })

  describe('keyboard navigation', () => {
    beforeEach(() => {
      downNode = undefined
    })

    it('should default to the first focusable element', () => {
      const {getByText} = renderBlockToolbar()
      const firstButton = getByText('Go up').closest('button')
      expect(firstButton?.getAttribute('tabindex')).toEqual('0')
    })

    it('should move to the next button on right arrow key', async () => {
      const {getByText} = renderBlockToolbar()
      const firstButton = getByText('Go up').closest('button') as HTMLButtonElement
      await user.type(firstButton, '{ArrowRight}')
      const secondButton = getByText('Drag to move').closest('button')
      expect(secondButton?.getAttribute('tabindex')).toEqual('0')
      expect(firstButton?.getAttribute('tabindex')).toEqual('-1')
    })

    it('should move to the previous button on left arrow key', async () => {
      const {getByText} = renderBlockToolbar()
      const firstButton = getByText('Go up').closest('button') as HTMLButtonElement
      await user.type(activeElem() as Element, '{ArrowLeft}')
      await user.type(activeElem() as Element, '{ArrowRight}')
      expect(firstButton.getAttribute('tabindex')).toEqual('0')
    })

    it('should wrap around on left arrow from the first button', async () => {
      isSaveable = false
      const {getByText} = renderBlockToolbar()
      const firstButton = getByText('Go up').closest('button') as HTMLButtonElement
      await user.type(firstButton, '{ArrowLeft}')
      const lastButton = getByText('Delete').closest('button')
      expect(lastButton?.getAttribute('tabindex')).toEqual('0')
    })

    it('should wrap around on right arrow from the last button', async () => {
      isSaveable = false
      const {getByText} = renderBlockToolbar()
      const lastButton = getByText('Delete').closest('button') as HTMLButtonElement
      lastButton.focus()
      expect(lastButton?.getAttribute('tabindex')).toEqual('0')

      await user.type(lastButton, '{ArrowRight}')
      const firstButton = getByText('Go up').closest('button')
      expect(firstButton?.getAttribute('tabindex')).toEqual('0')
    })

    it('should return focus to last focused button after leaving the toolbar', async () => {
      const {getByText} = renderBlockToolbar()
      const firstButton = getByText('Go up').closest('button')
      firstButton?.focus()
      await user.type(activeElem(), '{ArrowRight}')
      const button2 = getByText('Drag to move').closest('button')
      expect(button2).toBe(activeElem())

      const domNode = document.getElementById('nodeid') as HTMLElement
      domNode?.focus()
      expect(domNode).toBe(activeElem())

      await user.type(activeElem(), '{Tab}')
      expect(button2).toBe(activeElem())
    })

    it("should return focus to it's node's dom node on escape", async () => {
      const {getByText} = renderBlockToolbar()
      const firstButton = getByText('Go up').closest('button') as HTMLElement
      firstButton.focus()
      expect(firstButton).toBe(activeElem())
      await user.type(firstButton, '{Escape}')
      expect(activeElem()).toBe(nodeDomNode)
    })
  })

  describe('isBlockSaveable', () => {
    it('returns false if the user is not a template editor', () => {
      const node = {} as Node
      expect(isBlockSaveable(TemplateEditor.NONE, node)).toBe(false)
    })

    describe('when the user is a template editor', () => {
      it('returns true if the node is a GroupBlock', () => {
        const node = {data: {name: 'GroupBlock'}} as Node
        expect(isBlockSaveable(TemplateEditor.LOCAL, node)).toBe(true)
      })

      it('returns false if the node is not a GroupBlock', () => {
        const node = {data: {name: 'SomeBlock'}} as Node
        expect(isBlockSaveable(TemplateEditor.LOCAL, node)).toBe(false)
      })

      it('returns true if the node is a section', () => {
        const node = {data: {custom: {isSection: true}}} as Node
        expect(isBlockSaveable(TemplateEditor.LOCAL, node)).toBe(true)
      })

      it('returns false of the node is the page', () => {
        const node = {data: {name: 'PageBlock'}} as Node
        expect(isBlockSaveable(TemplateEditor.LOCAL, node)).toBe(false)
      })
    })

    describe('when the user is a global editor', () => {
      it('returns true if the node is a GroupBlock', () => {
        const node = {data: {name: 'GroupBlock'}} as Node
        expect(isBlockSaveable(TemplateEditor.LOCAL, node)).toBe(true)
      })

      it('returns false if the node is not a GroupBlock', () => {
        const node = {data: {name: 'SomeBlock'}} as Node
        expect(isBlockSaveable(TemplateEditor.LOCAL, node)).toBe(false)
      })

      it('returns true if the node is a section', () => {
        const node = {data: {custom: {isSection: true}}} as Node
        expect(isBlockSaveable(TemplateEditor.LOCAL, node)).toBe(true)
      })

      it('returns true of the node is the page', () => {
        const node = {data: {name: 'PageBlock'}} as Node
        expect(isBlockSaveable(TemplateEditor.LOCAL, node)).toBe(false)
      })
    })
  })
})
