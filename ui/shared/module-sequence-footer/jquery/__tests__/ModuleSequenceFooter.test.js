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

import $ from 'jquery'
import 'jquery-migrate'
import {http} from 'msw'
import {setupServer} from 'msw/node'
import '..'

const moduleData = (args = {}) => ({
  items: [
    {
      current: {id: 768, module_id: 123, title: 'A lonely page', type: 'Page'},
      next: {id: 111, module_id: 123, title: 'Project 33', type: 'Assignment'},
      mastery_path: args.mastery_path,
    },
  ],
  modules: [{id: 123, name: 'Module A'}],
  ...args,
})

const basePathData = (args = {}) => ({
  is_student: true,
  choose_url: 'chew-z',
  modules_url: 'mod.module.mod',
  ...args,
})

const nullButtonData = (args = {}) => ({
  items: [
    {
      prev: null,
      current: {
        id: 768,
        module_id: 123,
        title: 'A lonely page',
        type: 'Page',
      },
      next: null,
      mastery_path: args.mastery_path,
    },
  ],
  modules: [
    {
      id: 123,
      name: 'Module A',
    },
  ],
  ...args,
})

describe('ModuleSequenceFooter', () => {
  let $testEl
  let MSFClass
  let $fixtures
  const server = setupServer(
    // Default handler for all API calls
    http.get('/api/v1/courses/*/module_item_sequence', () => {
      return new Response(JSON.stringify(nullButtonData()), {
        headers: {'Content-Type': 'application/json'},
      })
    }),
  )

  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  beforeEach(() => {
    $fixtures = $('<div id="fixtures" />')
    document.body.innerHTML = ''
    document.body.appendChild($fixtures[0])
    $testEl = $('<div>')
    $fixtures.append($testEl)

    MSFClass = $.fn.moduleSequenceFooter.MSFClass
  })

  afterEach(() => {
    $fixtures.remove()
  })

  describe('initialization', () => {
    it('returns jquery object of itself', () => {
      const jobj = $testEl.moduleSequenceFooter({
        courseID: 42,
        assetType: 'Assignment',
        assetID: 42,
      })
      expect(jobj).toBeInstanceOf($)
    })

    it('throws error if options are not set', () => {
      expect(() => {
        $testEl.moduleSequenceFooter()
      }).toThrow()
    })

    it('generates url based on courseID', () => {
      const msf = new MSFClass({
        courseID: 42,
        assetType: 'Assignment',
        assetID: 42,
      })
      expect(msf.url).toBe('/api/v1/courses/42/module_item_sequence')
    })

    it('attaches msfAnimation function', () => {
      $testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 42})
      expect($testEl.msfAnimation).toBeDefined()
    })

    it('accepts animation option', async () => {
      server.use(
        http.get('/api/v1/courses/*/module_item_sequence', () => {
          return new Response(
            JSON.stringify({
              items: [
                {
                  prev: null,
                  current: {
                    id: 42,
                    module_id: 73,
                    title: 'A lonely page',
                    type: 'Page',
                  },
                  next: null,
                },
              ],
              modules: [
                {
                  id: 73,
                  name: 'A lonely module',
                },
              ],
            }),
            {headers: {'Content-Type': 'application/json'}},
          )
        }),
      )

      const msf = $testEl.moduleSequenceFooter({
        courseID: 42,
        assetType: 'Assignment',
        assetID: 42,
        animation: false,
      })

      // Wait for the fetch promise to resolve
      await msf.data('msfInstance').fetch()

      expect($testEl.find('.module-sequence-footer.no-animation')).toHaveLength(1)
      expect($testEl.find('.module-sequence-padding.no-animation')).toHaveLength(1)

      $testEl.msfAnimation(true)

      expect($testEl.find('.module-sequence-footer:not(.no-animation)')).toHaveLength(1)
      expect($testEl.find('.module-sequence-padding:not(.no-animation)')).toHaveLength(1)
    })
  })

  describe('rendering', () => {
    it('shows no buttons when next and prev data are null', async () => {
      server.use(
        http.get('/api/v1/courses/42/module_item_sequence', () => {
          return new Response(JSON.stringify(nullButtonData()), {
            headers: {'Content-Type': 'application/json'},
          })
        }),
      )

      const msf = $testEl.moduleSequenceFooter({
        courseID: 42,
        assetType: 'Assignment',
        assetID: 123,
      })

      // Wait for the fetch promise to resolve
      await msf.data('msfInstance').fetch()


      expect($testEl.find('[aria-label="Previous Module Item"]')).toHaveLength(0)
      expect($testEl.find('[aria-label="Next Module Item"]')).toHaveLength(0)
    })

    it('shows modules tooltip when current module id differs from next/prev module id', async () => {
      const moduleTooltipData = {
        items: [
          {
            prev: {
              id: 769,
              module_id: 111,
              title: 'Project 1',
              type: 'Assignment',
            },
            current: {
              id: 768,
              module_id: 123,
              title: 'A lonely page',
              type: 'Page',
            },
            next: {
              id: 111,
              module_id: 666,
              title: 'Project 33',
              type: 'Assignment',
            },
          },
        ],
        modules: [
          {id: 123, name: 'Module A'},
          {id: 666, name: 'Module B'},
          {id: 111, name: 'Module C'},
        ],
      }

      server.use(
        http.get('/api/v1/courses/42/module_item_sequence', () => {
          return new Response(JSON.stringify(moduleTooltipData), {
            headers: {'Content-Type': 'application/json'},
          })
        }),
      )

      const msf = $testEl.moduleSequenceFooter({
        courseID: 42,
        assetType: 'Assignment',
        assetID: 123,
      })

      // Wait for the fetch promise to resolve
      await msf.data('msfInstance').fetch()

      expect($testEl.find('[aria-label="Previous Module Item"]')).toHaveLength(1)
      expect($testEl.find('[aria-label="Next Module Item"]')).toHaveLength(1)
    })

    it('shows item tooltip when current module id matches next/prev module id', async () => {
      const itemTooltipData = {
        items: [
          {
            prev: {
              id: 769,
              module_id: 123,
              title: 'Project 1',
              type: 'Assignment',
            },
            current: {
              id: 768,
              module_id: 123,
              title: 'A lonely page',
              type: 'Page',
            },
            next: {
              id: 111,
              module_id: 123,
              title: 'Project 33',
              type: 'Assignment',
            },
          },
        ],
        modules: [
          {
            id: 123,
            name: 'Module A',
          },
        ],
      }

      server.use(
        http.get('/api/v1/courses/42/module_item_sequence', () => {
          return new Response(JSON.stringify(itemTooltipData), {
            headers: {'Content-Type': 'application/json'},
          })
        }),
      )

      const msf = $testEl.moduleSequenceFooter({
        courseID: 42,
        assetType: 'Assignment',
        assetID: 123,
      })

      // Wait for the fetch promise to resolve
      await msf.data('msfInstance').fetch()

      expect($testEl.find('[aria-label="Previous Module Item"]')).toHaveLength(1)
      expect($testEl.find('[aria-label="Next Module Item"]')).toHaveLength(1)
    })

    it('uses module_item_id from URL as assetID with ModuleItem type', async () => {
      let requestedUrl = ''
      server.use(
        http.get('/api/v1/courses/42/module_item_sequence', ({request}) => {
          requestedUrl = request.url
          return new Response(JSON.stringify(nullButtonData()), {
            headers: {'Content-Type': 'application/json'},
          })
        }),
      )

      const msf = $testEl.moduleSequenceFooter({
        courseID: 42,
        assetType: 'Assignment',
        assetID: 123,
        location: {search: '?module_item_id=999'},
      })

      // Wait for the fetch promise to resolve
      await msf.data('msfInstance').fetch()

      expect(requestedUrl).toContain('asset_type=ModuleItem')
      expect(requestedUrl).toContain('asset_id=999')
    })

    it('shows element when rendering', async () => {
      const showSpy = vi.spyOn($testEl, 'show')

      server.use(
        http.get('/api/v1/courses/42/module_item_sequence', () => {
          return new Response(JSON.stringify(moduleData()), {
            headers: {'Content-Type': 'application/json'},
          })
        }),
      )

      const msf = $testEl.moduleSequenceFooter({
        courseID: 42,
        assetType: 'Assignment',
        assetID: 123,
      })

      // Wait for the fetch promise to resolve
      await msf.data('msfInstance').fetch()

      expect(showSpy).toHaveBeenCalled()
    })

    it('triggers resize event', async () => {
      const resizeHandler = vi.fn()
      $(window).on('resize', resizeHandler)

      server.use(
        http.get('/api/v1/courses/42/module_item_sequence', () => {
          return new Response(JSON.stringify(moduleData()), {
            headers: {'Content-Type': 'application/json'},
          })
        }),
      )

      const msf = $testEl.moduleSequenceFooter({
        courseID: 42,
        assetType: 'Assignment',
        assetID: 123,
      })

      // Wait for the fetch promise to resolve
      await msf.data('msfInstance').fetch()

      expect(resizeHandler).toHaveBeenCalled()
      $(window).off('resize', resizeHandler)
    })
  })

  describe('mastery paths', () => {
    it('shows correct tooltip when awaiting choice', async () => {
      const pathData = moduleData({mastery_path: basePathData({awaiting_choice: true})})

      server.use(
        http.get('/api/v1/courses/42/module_item_sequence', () => {
          return new Response(JSON.stringify(pathData), {
            headers: {'Content-Type': 'application/json'},
          })
        }),
      )

      const msf = $testEl.moduleSequenceFooter({
        courseID: 42,
        assetType: 'Assignment',
        assetID: 123,
      })

      // Wait for the fetch promise to resolve
      await msf.data('msfInstance').fetch()

      expect($testEl.find('[aria-label="Next Module Item"]')).toHaveLength(1)
      expect($testEl.find('a').attr('href')).toMatch('chew-z')
    })

    it('shows correct tooltip when sequence is locked', async () => {
      const pathData = moduleData({mastery_path: basePathData({locked: true})})

      server.use(
        http.get('/api/v1/courses/42/module_item_sequence', () => {
          return new Response(JSON.stringify(pathData), {
            headers: {'Content-Type': 'application/json'},
          })
        }),
      )

      const msf = $testEl.moduleSequenceFooter({
        courseID: 42,
        assetType: 'Assignment',
        assetID: 123,
      })

      // Wait for the fetch promise to resolve
      await msf.data('msfInstance').fetch()

      expect($testEl.find('[aria-label="Next Module Item"]')).toHaveLength(1)
      expect($testEl.find('a').attr('href')).toMatch('mod.module.mod')
    })

    it('disables next button when path is locked and modules tab is disabled', async () => {
      const pathData = moduleData({
        mastery_path: basePathData({locked: true, modules_tab_disabled: true}),
      })

      server.use(
        http.get('/api/v1/courses/42/module_item_sequence', () => {
          return new Response(JSON.stringify(pathData), {
            headers: {'Content-Type': 'application/json'},
          })
        }),
      )

      const msf = $testEl.moduleSequenceFooter({
        courseID: 42,
        assetType: 'Assignment',
        assetID: 123,
      })

      // Wait for the fetch promise to resolve
      await msf.data('msfInstance').fetch()

      const nextButton = $testEl.find('[aria-label="Next Module Item"][disabled]')

      expect(nextButton).toHaveLength(1)

      // assert proper rendering of mouseover tooltip icon
      nextButton.mouseover()
      expect(document.querySelectorAll('i.icon-module')).toHaveLength(1)
    })

    it('shows next button when no next items exist and paths are processing', async () => {
      const pathData = moduleData({
        mastery_path: basePathData({
          is_student: true,
          still_processing: true,
          modules_url: 'mod.module.mod',
        }),
        next: null,
      })

      server.use(
        http.get('/api/v1/courses/42/module_item_sequence', () => {
          return new Response(JSON.stringify(pathData), {
            headers: {'Content-Type': 'application/json'},
          })
        }),
      )

      const msf = $testEl.moduleSequenceFooter({
        courseID: 42,
        assetType: 'Assignment',
        assetID: 123,
      })

      // Wait for the fetch promise to resolve
      await msf.data('msfInstance').fetch()

      expect($testEl.find('[aria-label="Next Module Item"]')).toHaveLength(1)
      expect($testEl.find('a').attr('href')).toMatch('mod.module.mod')
    })
  })

  describe('external URLs', () => {
    it('announces new window for external URL links', async () => {
      const externalUrlTypeData = {
        items: [
          {
            prev: {
              id: 769,
              module_id: 123,
              title: 'Not an external item',
              type: 'Assignment',
            },
            current: {
              id: 768,
              module_id: 123,
              title: 'A lonely page',
              type: 'Page',
            },
            next: {
              id: 111,
              module_id: 123,
              title: 'Rendering of the project',
              type: 'ExternalUrl',
              new_tab: true,
            },
          },
        ],
        modules: [
          {
            id: 123,
            name: 'Module A',
          },
        ],
      }

      server.use(
        http.get('/api/v1/courses/42/module_item_sequence', () => {
          return new Response(JSON.stringify(externalUrlTypeData), {
            headers: {'Content-Type': 'application/json'},
          })
        }),
      )

      const msf = $testEl.moduleSequenceFooter({
        courseID: 42,
        assetType: 'Assignment',
        assetID: 123,
      })

      // Wait for the fetch promise to resolve
      await msf.data('msfInstance').fetch()

      expect($testEl.find('[aria-label="Previous Module Item"]')).toHaveLength(1)
      expect($testEl.find('[aria-label="Next Module Item - opens in new window"]')).toHaveLength(1)
    })
  })
})
