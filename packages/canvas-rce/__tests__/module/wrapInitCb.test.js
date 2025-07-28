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

import wrapInitCb from '../../src/rce/wrapInitCb'

let mirroredAttrs, edOpts, setAttrStub, fakeEditor, elStub, origInitCB

describe('wrapInitCb', () => {
  beforeAll(() => {
    mirroredAttrs = {
      foo: 'bar',
    }
    origInitCB = jest.fn()
    edOpts = {
      init_instance_callback: origInitCB,
    }
    setAttrStub = jest.fn()
    elStub = {
      setAttribute: setAttrStub,
      dataset: {rich_text: false},
    }
    fakeEditor = {
      getElement: () => elStub,
      addVisual: () => {},
      on: () => {},
      contentWindow: {},
    }
  })

  it('tries to add attributes to el in cb', () => {
    const newEdOpts = wrapInitCb(mirroredAttrs, edOpts)
    newEdOpts.init_instance_callback(fakeEditor)
    expect(setAttrStub).toHaveBeenCalledWith('foo', 'bar')
  })

  it('still calls old cb', () => {
    const newEdOpts = wrapInitCb(mirroredAttrs, edOpts)
    newEdOpts.init_instance_callback(fakeEditor)
    expect(origInitCB).toHaveBeenCalledWith(fakeEditor)
  })
})
