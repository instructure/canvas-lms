// @ts-nocheck
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

import React from 'react'
import ExternalToolDialog, {ExternalToolDialogProps} from '../ExternalToolDialog/ExternalToolDialog'
import {waitFor} from '@testing-library/react'
import ReactDOM, {Container} from 'react-dom'
import {InstUISettingsProvider} from '@instructure/emotion'
import {createDeepMockProxy} from '../../../../../util/__tests__/deepMockProxy'
import {RceToolWrapper} from '../../RceToolWrapper'
import RCEWrapper from '../../../../RCEWrapper'
import {ExternalToolsEditor, externalToolsEnvFor, RceLtiToolInfo} from '../../ExternalToolsEnv'
import {filterItemsByTitleSubstring} from '../ExternalToolSelectionDialog/ExternalToolSelectionDialog'

const nop = () => undefined

const content_items = [
  {
    type: 'link',
    title: 'title',
    url: 'http://www.tool.com',
  },
  {
    type: 'ltiResourceLink',
    title: 'LTI Link',
    url: 'http://www.tool.com/lti',
  },
]

let container: HTMLDivElement | null = null
let submit: jest.Mock
let originalSubmit: () => void
let originalScroll: typeof window.scroll

async function waitForAssertion(cb: () => void) {
  try {
    cb()
  } catch (_) {
    await new Promise(resolve => setTimeout(resolve, 25))
    await waitForAssertion(cb)
  }
}

function fakeContentItem(text) {
  return {
    placementAdvice: {presentationDocumentTarget: 'embed'},
    text,
  }
}

function fakeRCEReplaceContentItem(text) {
  return {
    placementAdvice: {
      presentationDocumentTarget: 'embed',
    },
    '@type': 'lti_replace',
    text,
  }
}

const editorMock = createDeepMockProxy<ExternalToolsEditor>()
const rceMock = createDeepMockProxy<RCEWrapper>(
  {},
  {
    props: {
      trayProps: {
        contextId: '1',
        contextType: 'course',
      },
    }, // satisfies Partial<RCEWrapperProps> as any,
    getResourceIdentifiers: () => ({resourceType: 'assignment.body', resourceId: '132'}),
  }
)

function getInstance(
  _container: Container | null | undefined,
  overrides?: Partial<ExternalToolDialogProps>
): Promise<ExternalToolDialog> {
  return new Promise(resolve => {
    const props: ExternalToolDialogProps = {
      env: externalToolsEnvFor(editorMock),
      iframeAllowances: 'geolocation',
      resourceSelectionUrlOverride: 'http://url/with/{{id}}',
      ...overrides,
    }
    ReactDOM.render(
      <InstUISettingsProvider theme={{componentOverrides: {Transition: {duration: '0ms'}}}}>
        <ExternalToolDialog ref={it => resolve(it!)} {...props} />
      </InstUISettingsProvider>,
      _container ?? null
    )
  })
}

function data<T extends Record<string, any>>(overrides?: T) {
  return {
    content_items,
    ltiEndpoint: 'https://www.instructure.com/lti',
    subject: 'LtiDeepLinkingResponse',
    ...overrides,
  }
}

function toolHelper(id: string | number, extras: Partial<RceLtiToolInfo> = {}) {
  return new RceToolWrapper(
    externalToolsEnvFor(editorMock),
    {id: String(id), name: 'foo', ...extras},
    []
  )
}

describe('getFilterResults', () => {
  const foobar = {title: 'foobar'}
  const barfoo = {title: 'baRFoo'}
  const invisibleSuperman = {title: 'invisible SUPERman'}
  const stars = {title: '*****'}

  const items = [foobar, barfoo, invisibleSuperman, stars]

  it('handles basic searches', () => {
    expect(filterItemsByTitleSubstring('foobar', items)).toEqual([foobar])
    expect(filterItemsByTitleSubstring('bar', items)).toEqual([foobar, barfoo])
    expect(filterItemsByTitleSubstring('le su', items)).toEqual([invisibleSuperman])
    expect(filterItemsByTitleSubstring('**', items)).toEqual([stars])
  })

  it('handles empty input', () => {
    expect(filterItemsByTitleSubstring('', items)).toEqual(items)
    expect(filterItemsByTitleSubstring(null, items)).toEqual(items)
    expect(filterItemsByTitleSubstring(undefined, items)).toEqual(items)
  })
})

describe('ExternalToolDialog', () => {
  beforeAll(() => {
    jest.spyOn(RCEWrapper, 'getByEditor').mockImplementation(e => {
      if (e === (editorMock as any)) return rceMock
      else {
        throw new Error('Wrong editor requested')
      }
    })
  })

  beforeEach(() => {
    editorMock.mockClear()
    rceMock.mockClear()
    originalSubmit = HTMLFormElement.prototype.submit
    submit = jest.fn()
    HTMLFormElement.prototype.submit = submit
    originalScroll = window.scroll
    window.scroll = nop
    container = document.createElement('div')
  })

  afterEach(() => {
    if (container != null) {
      ReactDOM.unmountComponentAtNode(container)
      container = null
    }
    HTMLFormElement.prototype.submit = originalSubmit
    window.scroll = originalScroll
  })

  describe('open', () => {
    test('launches external tool when opened', async () => {
      const instance = await getInstance(container)
      instance.open(toolHelper(1))
      expect(container?.querySelector('form')?.action).toBe('http://url/with/1')
      await waitFor(() => expect(submit).toHaveBeenCalled())
    })

    it('submits current selection to tool', async () => {
      const selection = 'selected text'

      editorMock.selection?.getContent.mockReturnValue(selection)
      const instance = await getInstance(container)
      instance.open(toolHelper(1))
      expect((container?.querySelector('input[name="selection"]') as HTMLInputElement)?.value).toBe(
        selection
      )
      await waitFor(() => expect(submit).toHaveBeenCalled())
    })

    it('submits current editor contents to tool', async () => {
      const contents = 'editor contents'
      editorMock.getContent.mockReturnValue(contents)
      const instance = await getInstance(container)
      instance.open(toolHelper(1))
      expect(
        (container?.querySelector('input[name="editor_contents"]') as HTMLInputElement)?.value
      ).toBe(contents)
      await waitFor(() => expect(submit).toHaveBeenCalled())
    })

    it('includes resource type and id in form', async () => {
      const instance = await getInstance(container)
      instance.open(toolHelper(1))
      expect(
        (
          container?.querySelector(
            'input[name="com_instructure_course_canvas_resource_type"]'
          ) as HTMLInputElement
        )?.value
      ).toBe('assignment.body')
      expect(
        (
          container?.querySelector(
            'input[name="com_instructure_course_canvas_resource_id"]'
          ) as HTMLInputElement
        )?.value
      ).toBe('132')
      await waitFor(() => expect(submit).toHaveBeenCalled())
    })

    it('uses default resource selection url', async () => {
      const instance = await getInstance(container, {resourceSelectionUrlOverride: null})
      instance.open(toolHelper(2))
      expect(container?.querySelector('form')?.action).toBe(
        'http://localhost/courses/1/external_tools/2/resource_selection'
      )
    })

    it('uses button name as modal heading', async () => {
      const instance = await getInstance(container, {resourceSelectionUrlOverride: null})
      instance.open(toolHelper(2))
      expect(document.querySelector('h2')?.textContent).toContain('foo')
    })

    it('sets up beforeunload handler', async () => {
      jest.spyOn(window, 'addEventListener')
      const instance = await getInstance(container)
      instance.open(toolHelper(2))
      expect(window.addEventListener).toHaveBeenCalledWith(
        'beforeunload',
        instance.handleBeforeUnload
      )
    })

    it('sets up postMessage handler', async () => {
      jest.spyOn(window, 'addEventListener')
      const instance = await getInstance(container)
      instance.open(toolHelper(2))
      expect(window.addEventListener).toHaveBeenCalledWith('message', instance.handlePostedMessage)
    })

    it('sets "data-lti-launch" attribute on iframe', async () => {
      const instance = await getInstance(container)
      instance.open(toolHelper(2))
      expect(document.querySelector('iframe')?.getAttribute('data-lti-launch')).toBe('true')
    })

    describe('tray', () => {
      it('sets height and width for iframe to 100%', async () => {
        const instance = await getInstance(container)
        instance.open(toolHelper(2, {use_tray: true}))
        const style = document.querySelector('iframe')?.style
        expect(style?.height).toBe('100%')
        expect(style?.width).toBe('100%')
      })
    })
  })

  describe('close', () => {
    it('closes the dialog', async () => {
      const instance = await getInstance(container)
      instance.open(toolHelper(1))
      expect(document.querySelector('iframe')).not.toBeNull()
      instance.close()
      await waitForAssertion(() => {
        expect(document.querySelector('iframe')).toBeNull()
      })
    })

    it('removes event handlers', async () => {
      jest.spyOn(window, 'removeEventListener')
      const instance = await getInstance(container)
      instance.open(toolHelper(2))
      instance.close()

      expect(window.removeEventListener).toHaveBeenCalledWith(
        'beforeunload',
        instance.handleBeforeUnload
      )

      expect(window.removeEventListener).toHaveBeenCalledWith(
        'message',
        instance.handlePostedMessage
      )
    })
  })

  describe('handleClose', () => {
    let confirmSpy: jest.SpyInstance<boolean, [string?]>

    beforeEach(() => {
      confirmSpy = jest.spyOn(window, 'confirm')
    })

    afterEach(() => {
      confirmSpy.mockClear()
    })

    it('does not close if not confirmed', async () => {
      const instance = await getInstance(container)
      const closeSpy = jest.spyOn(instance, 'close')

      instance.open(toolHelper(1))

      confirmSpy.mockReturnValue(false)
      instance.handleClose()

      expect(closeSpy).not.toHaveBeenCalled()
    })

    it('closes if confirmed', async () => {
      const instance = await getInstance(container)
      const closeSpy = jest.spyOn(instance, 'close')

      instance.open(toolHelper(1))

      confirmSpy.mockReturnValue(true)
      instance.handleClose()

      expect(closeSpy).toHaveBeenCalled()
    })
  })

  describe('handleBeforeUnload', () => {
    it('sets event return value', async () => {
      const instance = await getInstance(container)
      const ev = {returnValue: undefined}
      instance.handleBeforeUnload(ev as unknown as Event)
      expect(ev.returnValue).toContain('may not be saved')
    })
  })

  describe('handleRemove', () => {
    it('dispatches a resize event', async () => {
      jest.spyOn(window, 'dispatchEvent')
      const instance = await getInstance(container)
      instance.open(toolHelper(2))
      instance.handleClose()
      await waitFor(() => expect(window.dispatchEvent).toHaveBeenCalledWith(new Event('resize')))
    })
  })

  describe('handleExternalContentReady', () => {
    it('inserts content items in to the editor', async () => {
      const instance = await getInstance(container)

      instance.handlePostedMessage({
        origin: instance.resourceSelectionOrigin,

        data: {
          subject: 'externalContentReady',
          contentItems: [fakeContentItem('foo'), fakeContentItem('bar')],
        },
      })

      expect(rceMock.insertCode).toHaveBeenCalledWith('foo')
      expect(rceMock.insertCode).toHaveBeenCalledWith('bar')
    })

    it('replaces content items in the editor', async () => {
      const instance = await getInstance(container)

      instance.handlePostedMessage({
        origin: instance.resourceSelectionOrigin,

        data: {
          subject: 'externalContentReady',
          contentItems: [fakeRCEReplaceContentItem('foo')],
        },
      })

      expect(rceMock.setCode).toHaveBeenCalledWith('foo')
    })

    it('closes the dialog', async () => {
      const instance = await getInstance(container)
      const closeSpy = jest.spyOn(instance, 'close')

      instance.open(toolHelper(1))
      instance.handlePostedMessage({
        origin: instance.resourceSelectionOrigin,
        data: {
          subject: 'externalContentReady',
          contentItems: [],
        },
      })

      expect(closeSpy).toHaveBeenCalled()
    })

    describe('and truthy externalToolsConfig.isA2StudentView', () => {
      beforeAll(() => {
        rceMock.props.externalToolsConfig = {
          isA2StudentView: true,
        } // satisfies RCEWrapperProps['externalToolsConfig'] as any
      })

      it('does not insert content items into the editor', async () => {
        const instance = await getInstance(container)
        const closeSpy = jest.spyOn(instance, 'close')

        instance.handlePostedMessage({
          origin: instance.resourceSelectionOrigin,
          data: {
            subject: 'externalContentReady',
            contentItems: [fakeContentItem('foo')],
          },
        })

        expect(rceMock.insertCode).not.toHaveBeenCalled()
        expect(rceMock.setCode).not.toHaveBeenCalled()
        expect(closeSpy).toHaveBeenCalled()
      })

      it('does not replace content items in the editor', async () => {
        const instance = await getInstance(container)
        const closeSpy = jest.spyOn(instance, 'close')

        instance.handlePostedMessage({
          origin: instance.resourceSelectionOrigin,
          data: {
            subject: 'externalContentReady',
            contentItems: [fakeRCEReplaceContentItem('foo')],
          },
        })

        expect(rceMock.insertCode).not.toHaveBeenCalled()
        expect(rceMock.setCode).not.toHaveBeenCalled()
        expect(closeSpy).toHaveBeenCalled()
      })

      it('closes the dialog', async () => {
        const instance = await getInstance(container)
        instance.open(toolHelper(1))

        instance.handlePostedMessage({
          origin: instance.resourceSelectionOrigin,
          data: {
            subject: 'externalContentReady',
            contentItems: [fakeContentItem('foo'), fakeRCEReplaceContentItem('bar')],
          },
        })

        await waitForAssertion(() => {
          expect(document.querySelector('iframe')).toBeNull()
        })
      })
    })
  })

  describe('handlePostedMessage', () => {
    it('ignores other origins', async () => {
      const instance = await getInstance(container)

      instance.handlePostedMessage({
        origin: instance.resourceSelectionOrigin + '-other',
        data: null,
      })

      expect(rceMock.setCode).not.toHaveBeenCalled()
      expect(rceMock.insertCode).not.toHaveBeenCalled()
    })

    it('ignores non-deep linking responses', async () => {
      const instance = await getInstance(container)

      instance.handlePostedMessage({
        origin: instance.resourceSelectionOrigin,
        data: data({subject: 'notdeeplinking'}),
      })

      expect(rceMock.setCode).not.toHaveBeenCalled()
      expect(rceMock.insertCode).not.toHaveBeenCalled()
    })

    it('processes LTI 1.3 content items for correct origin', async () => {
      const instance = await getInstance(container)
      const ev = {origin: instance.resourceSelectionOrigin, data: data()}
      instance.handlePostedMessage(ev)

      expect(rceMock.insertCode).toHaveBeenNthCalledWith(
        1,
        '<a href="http://www.tool.com" title="title" target="_blank">title</a>'
      )
    })
  })

  describe('alerts', () => {
    it('has screenreader-only for both by default', async () => {
      const instance = await getInstance(container)
      instance.open(toolHelper(1))
      expect(instance.beforeInfoAlertRef.current?.className).toContain('screenreader-only')
      expect(instance.afterInfoAlertRef.current?.className).toContain('screenreader-only')
    })

    it('removes screenreader-only from before alert on focus', async () => {
      const instance = await getInstance(container)
      instance.open(toolHelper(1))
      const ev = {target: instance.beforeInfoAlertRef.current!}
      instance.handleInfoAlertFocus(ev)
      expect(instance.beforeInfoAlertRef.current?.className).not.toContain('screenreader-only')
      expect(instance.afterInfoAlertRef.current?.className).toContain('screenreader-only')
      instance.handleInfoAlertBlur()
      expect(instance.beforeInfoAlertRef.current?.className).toContain('screenreader-only')
    })

    it('removes screenreader-only from after alert on focus', async () => {
      const instance = await getInstance(container)
      instance.open(toolHelper(1))
      const ev = {target: instance.afterInfoAlertRef.current!}
      instance.handleInfoAlertFocus(ev)
      expect(instance.beforeInfoAlertRef.current?.className).toContain('screenreader-only')
      expect(instance.afterInfoAlertRef.current?.className).not.toContain('screenreader-only')
      instance.handleInfoAlertBlur()
      expect(instance.afterInfoAlertRef.current?.className).toContain('screenreader-only')
    })
  })
})
