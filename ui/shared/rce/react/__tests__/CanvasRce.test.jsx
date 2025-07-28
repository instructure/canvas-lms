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

import React, {createRef} from 'react'
import {render, waitFor} from '@testing-library/react'
import fakeENV from '@canvas/test-utils/fakeENV'
import CanvasRce from '../CanvasRce'

describe('CanvasRce', () => {
  let target

  beforeEach(() => {
    const div = document.createElement('div')
    div.id = 'fixture'
    div.innerHTML = '<div id="flash_screenreader_holder" role="alert"/><div id="target"/>'
    document.body.appendChild(div)

    target = document.getElementById('target')
  })
  afterEach(() => {
    document.body.removeChild(document.getElementById('fixture'))
    fakeENV.teardown()
  })

  it('supports getCode() and setCode() on its ref', async () => {
    const rceRef = createRef(null)
    render(<CanvasRce ref={rceRef} textareaId="textarea3" defaultContent="Hello RCE!" />, target)

    await waitFor(() => expect(rceRef.current).not.toBeNull())

    expect(rceRef.current.getCode()).toEqual('Hello RCE!')
    rceRef.current.setCode('How sweet.')
    expect(rceRef.current.getCode()).toEqual('How sweet.')
  })

  it('passes autosave prop to child components', async () => {
    const rceRef = createRef(null)

    render(<CanvasRce ref={rceRef} textareaId="textarea3" autosave={false} />, target)
    await waitFor(() => expect(rceRef.current).not.toBeNull())

    expect(rceRef.current.props.autosave.enabled).toEqual(false)
  })

  it('populates externalToolsConfig without context_external_tool_resource_selection_url', async () => {
    fakeENV.setup({
      LTI_LAUNCH_FRAME_ALLOWANCES: ['test allow'],
      a2_student_view: true,
      MAX_MRU_LTI_TOOLS: 892,
    })
    const rceRef = createRef(null)

    render(<CanvasRce ref={rceRef} textareaId="textarea3" />, target)

    await waitFor(() => expect(rceRef.current).not.toBeNull())

    expect(rceRef.current.props.externalToolsConfig).toEqual({
      ltiIframeAllowances: ['test allow'],
      isA2StudentView: true,
      maxMruTools: 892,
      resourceSelectionUrlOverride: null,
    })
  })

  it('populates externalToolsConfig with context_external_tool_resource_selection_url', async () => {
    fakeENV.setup({
      LTI_LAUNCH_FRAME_ALLOWANCES: ['test allow'],
      a2_student_view: true,
      MAX_MRU_LTI_TOOLS: 892,
    })
    const rceRef = createRef(null)

    const a = document.createElement('a')
    try {
      a.id = 'context_external_tool_resource_selection_url'
      a.href = 'http://www.example.com'
      document.body.appendChild(a)

      render(<CanvasRce ref={rceRef} textareaId="textarea3" />, target)

      await waitFor(() => expect(rceRef.current).not.toBeNull())

      expect(rceRef.current.props.externalToolsConfig).toEqual({
        ltiIframeAllowances: ['test allow'],
        isA2StudentView: true,
        maxMruTools: 892,
        resourceSelectionUrlOverride: 'http://www.example.com',
      })
    } finally {
      a.remove()
    }
  })

  it('sets maxAge for autosave to 60 minutes by default', async () => {
    fakeENV.setup({
      rce_auto_save_max_age_ms: undefined,
    })
    const rceRef = createRef(null)
    render(<CanvasRce ref={rceRef} textareaId="textarea3" />, target)
    await waitFor(() => expect(rceRef.current).not.toBeNull())
    expect(rceRef.current.props.autosave.maxAge).toEqual(60 * 60 * 1000) // 60 minutes in milliseconds
  })

  it('sets maxAge for autosave to the environment variable value', async () => {
    fakeENV.setup({
      rce_auto_save_max_age_ms: 30 * 60 * 1000, // 30 minutes in milliseconds
    })
    const rceRef = createRef(null)
    render(<CanvasRce ref={rceRef} textareaId="textarea3" autosave={{enabled: false}} />, target)
    await waitFor(() => expect(rceRef.current).not.toBeNull())
    expect(rceRef.current.props.autosave.maxAge).toEqual(30 * 60 * 1000) // 30 minutes in milliseconds
  })

  describe('merging UI elements', () => {
    // the only way I can think of to test these functions
    // is to look at the props passed to the mock Editor component

    it('merges custom plugins into the default config', async () => {
      const rceRef = createRef(null)

      render(
        <CanvasRce
          ref={rceRef}
          textareaId="textarea3"
          editorOptions={{
            plugins: ['foo', 'bar'],
          }}
        />,
        target,
      )

      await waitFor(() => expect(rceRef.current).not.toBeNull())

      expect(rceRef.current.mceInstance().props.init.plugins).toEqual(
        expect.arrayContaining(['foo', 'bar']),
      )
    })

    it('merges items into an existing menu in the default config', async () => {
      const rceRef = createRef(null)

      render(
        <CanvasRce
          ref={rceRef}
          textareaId="textarea3"
          editorOptions={{
            menu: {
              format: {
                title: 'A new menu',
                items: 'item1 item2',
              },
            },
          }}
        />,
        target,
      )

      await waitFor(() => expect(rceRef.current).not.toBeNull())

      expect(rceRef.current.mceInstance().props.init.menu).toEqual(
        expect.objectContaining({
          format: expect.objectContaining({
            title: 'Format',
            items: expect.stringMatching(/\| item1 item2$/),
          }),
        }),
      )
    })

    it('merges a new menu into the default config', async () => {
      const rceRef = createRef(null)

      render(
        <CanvasRce
          ref={rceRef}
          textareaId="textarea3"
          editorOptions={{
            menu: {
              a_new_menu: {
                title: 'A new menu',
                items: 'item1 item2',
              },
            },
          }}
        />,
        target,
      )

      await waitFor(() => expect(rceRef.current).not.toBeNull())

      expect(rceRef.current.mceInstance().props.init.menubar).toMatch(/a_new_menu/)

      expect(rceRef.current.mceInstance().props.init.menu).toEqual(
        expect.objectContaining({
          a_new_menu: expect.objectContaining({
            title: 'A new menu',
            items: 'item1 item2',
          }),
        }),
      )
    })

    it('merges items into an existing toolbar in the default config', async () => {
      const rceRef = createRef(null)

      render(
        <CanvasRce
          ref={rceRef}
          textareaId="textarea3"
          editorOptions={{
            toolbar: [
              {
                name: 'Styles',
                items: ['button1', 'button2'],
              },
            ],
          }}
        />,
        target,
      )

      await waitFor(() => expect(rceRef.current).not.toBeNull())

      expect(rceRef.current.mceInstance().props.init.toolbar).toEqual(
        expect.arrayContaining([
          {
            name: 'Styles',
            items: expect.arrayContaining(['button1', 'button2']),
          },
        ]),
      )
    })

    it('merges a new toolbar into the default config', async () => {
      const rceRef = createRef(null)

      render(
        <CanvasRce
          ref={rceRef}
          textareaId="textarea3"
          editorOptions={{
            toolbar: [
              {
                name: 'New Toolbar',
                items: ['button1', 'button2'],
              },
            ],
          }}
        />,
        target,
      )

      await waitFor(() => expect(rceRef.current).not.toBeNull())

      const lastToolbar = rceRef.current.mceInstance().props.init.toolbar.slice(-1)
      expect(lastToolbar).toEqual(
        expect.arrayContaining([
          {
            name: 'New Toolbar',
            items: expect.arrayContaining(['button1', 'button2']),
          },
        ]),
      )
    })
  })

  describe('body theme', () => {
    const setupRCEWithENV = async env => {
      fakeENV.setup(env)
      const rceRef = createRef(null)
      render(<CanvasRce ref={rceRef} textareaId="textarea3" />, target)
      await waitFor(() => expect(rceRef.current).not.toBeNull())
      return rceRef
    }

    describe('with canvas_k6_theme enabled', () => {
      it('is set to elementary-theme if not in a k5 course', async () => {
        const rceRef = await setupRCEWithENV({
          FEATURES: {
            canvas_k6_theme: true,
          },
        })
        expect(rceRef.current.props.editorOptions.body_class).toEqual('elementary-theme')
      })

      it('is set to elementary-theme in a k5+balsamiq course', async () => {
        const rceRef = await setupRCEWithENV({
          FEATURES: {
            canvas_k6_theme: true,
          },
          K5_SUBJECT_COURSE: true,
          USE_CLASSIC_FONT: false,
        })
        expect(rceRef.current.props.editorOptions.body_class).toEqual('elementary-theme')
      })

      it('is set to default-theme in a k5+lato course', async () => {
        const rceRef = await setupRCEWithENV({
          FEATURES: {
            canvas_k6_theme: true,
          },
          K5_SUBJECT_COURSE: true,
          USE_CLASSIC_FONT: true,
        })
        expect(rceRef.current.props.editorOptions.body_class).toEqual('default-theme')
      })
    })

    describe('with canvas_k6_theme disabled', () => {
      it('is set to elementary-theme if in a k5+balsamiq course', async () => {
        const rceRef = await setupRCEWithENV({
          K5_SUBJECT_COURSE: true,
          USE_CLASSIC_FONT: false,
        })
        expect(rceRef.current.props.editorOptions.body_class).toEqual('elementary-theme')
      })

      it('is set to default-theme if in a k5+lato course', async () => {
        const rceRef = await setupRCEWithENV({
          K5_SUBJECT_COURSE: true,
          USE_CLASSIC_FONT: true,
        })
        expect(rceRef.current.props.editorOptions.body_class).toEqual('default-theme')
      })

      it('is set to default-theme if in a classic course', async () => {
        const rceRef = await setupRCEWithENV({
          K5_SUBJECT_COURSE: false,
        })
        expect(rceRef.current.props.editorOptions.body_class).toEqual('default-theme')
      })

      it('is set to elementary-theme in a k5+balsamiq homeroom course', async () => {
        const rceRef = await setupRCEWithENV({
          K5_HOMEROOM_COURSE: true,
          USE_CLASSIC_FONT: false,
        })
        expect(rceRef.current.props.editorOptions.body_class).toEqual('elementary-theme')
      })
    })
  })

  describe('features prop forwarding', () => {
    it('forwards features prop to underlying RCE component', async () => {
      const rceRef = createRef(null)
      const testFeatures = {
        rce_a11y_resize: true,
        new_math_equation_handling: true,
        rce_find_replace: false,
      }

      render(<CanvasRce ref={rceRef} textareaId="textarea3" features={testFeatures} />, target)

      await waitFor(() => expect(rceRef.current).not.toBeNull())

      expect(rceRef.current.props.features).toEqual(testFeatures)
    })

    it('uses ENV.FEATURES as default when features prop not provided', async () => {
      fakeENV.setup({
        FEATURES: {
          rce_a11y_resize: true,
          explicit_latex_typesetting: false,
        },
      })
      const rceRef = createRef(null)

      render(<CanvasRce ref={rceRef} textareaId="textarea3" />, target)

      await waitFor(() => expect(rceRef.current).not.toBeNull())

      expect(rceRef.current.props.features).toEqual({
        rce_a11y_resize: true,
        explicit_latex_typesetting: false,
      })
    })
  })
})
