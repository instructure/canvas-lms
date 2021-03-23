/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {renderHook, act} from '@testing-library/react-hooks/dom'
import useRCE from 'jsx/outcomes/shared/hooks/useRCE'
import OutcomesContext from 'jsx/outcomes/contexts/OutcomesContext'
import RichContentEditor from 'jsx/shared/rce/RichContentEditor'

jest.mock('jsx/shared/rce/RichContentEditor')

describe('useRCE', () => {
  const enhancedPlugins =
    'hr,fullscreen,instructure-ui-icons,instructure_condensed_buttons,instructure_html_view'
  const tinyOptions = plugins => ({
    focus: false,
    manageParent: false,
    tinyOptions: {
      height: 256,
      resize: false,
      plugins: `autolink,paste,table,lists,${
        plugins || 'textcolor'
      },link,directionality,a11y_checker,wordcount`,
      external_plugins: {
        instructure_embed: '/javascripts/tinymce_plugins/instructure_embed/plugin.js',
        instructure_equation: '/javascripts/tinymce_plugins/instructure_equation/plugin.js'
      }
    }
  })

  beforeEach(() => {
    RichContentEditor.loadNewEditor = jest.fn()
    RichContentEditor.callOnRCE = jest.fn()
    RichContentEditor.closeRCE = jest.fn()
    RichContentEditor.destroyRCE = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  test('should call RCE.loadNewEditor when setElemRef fn is called', () => {
    RichContentEditor.loadNewEditor.mockImplementation((_elem, _options, cb) => cb())
    const {result} = renderHook(() => useRCE())
    act(() => result.current[0]('elemRef'))
    expect(RichContentEditor.loadNewEditor).toHaveBeenCalledTimes(1)
  })

  test('should start RCE with standard plugins if ENV.use_rce_ehnacements is false', () => {
    RichContentEditor.callOnRCE.mockReturnValue(true)
    const wrapper = ({children}) => (
      <OutcomesContext.Provider value={{env: {useRceEnhancements: false}}}>
        {children}
      </OutcomesContext.Provider>
    )
    const {result} = renderHook(() => useRCE(), {wrapper})
    act(() => result.current[0]('elemRef'))
    expect(RichContentEditor.loadNewEditor).toHaveBeenCalledTimes(1)
    expect(RichContentEditor.loadNewEditor.mock.calls[0][1]).toEqual(tinyOptions())
  })

  test('should start RCE with enhanced plugins if ENV.use_rce_ehnacements is true', () => {
    RichContentEditor.callOnRCE.mockReturnValue(true)
    const wrapper = ({children}) => (
      <OutcomesContext.Provider value={{env: {useRceEnhancements: true}}}>
        {children}
      </OutcomesContext.Provider>
    )
    const {result} = renderHook(() => useRCE(), {wrapper})
    act(() => result.current[0]('elemRef'))
    expect(RichContentEditor.loadNewEditor).toHaveBeenCalledTimes(1)
    expect(RichContentEditor.loadNewEditor.mock.calls[0][1]).toEqual(tinyOptions(enhancedPlugins))
  })

  test('should call RCE.closeRCE and RCE.destroyRCE when elemRef is updated', () => {
    RichContentEditor.callOnRCE.mockReturnValue(true)
    const {result} = renderHook(() => useRCE())
    act(() => result.current[0]('elemRef'))
    act(() => result.current[0]())
    expect(RichContentEditor.closeRCE).toHaveBeenCalledTimes(1)
    expect(RichContentEditor.destroyRCE).toHaveBeenCalledTimes(1)
  })

  test('should call RCE.callOnRCE when getCode is called', () => {
    const {result} = renderHook(() => useRCE())
    act(() => result.current[0]('elemRef'))
    act(() => result.current[1]())
    expect(RichContentEditor.callOnRCE).toHaveBeenCalledTimes(1)
    expect(RichContentEditor.callOnRCE.mock.calls[0][1]).toEqual('get_code')
  })
})
