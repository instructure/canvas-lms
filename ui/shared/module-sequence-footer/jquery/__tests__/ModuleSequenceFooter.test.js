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

  beforeEach(() => {
    $fixtures = $('<div id="fixtures" />')
    document.body.appendChild($fixtures[0])
    $testEl = $('<div>')
    $fixtures.append($testEl)

    MSFClass = $.fn.moduleSequenceFooter.MSFClass

    // Use fake timers for React rendering
    jest.useFakeTimers()

    // Mock fetch to return a promise that resolves immediately
    jest.spyOn(MSFClass.prototype, 'fetch').mockImplementation(function () {
      return {
        done: callback => {
          callback()
          return {fail: () => {}}
        },
      }
    })
  })

  afterEach(() => {
    $fixtures.remove()
    jest.restoreAllMocks()
    jest.useRealTimers()
  })

  describe('initialization', () => {
    it('returns jquery object of itself', () => {
      const jobj = $testEl.moduleSequenceFooter({assetType: 'Assignment', assetID: 42})
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
      $testEl.moduleSequenceFooter({assetType: 'Assignment', assetID: 42})
      expect($testEl.msfAnimation).toBeDefined()
    })

    it('accepts animation option', () => {
      // Mock the success callback to simulate the server response
      MSFClass.prototype.fetch.mockImplementation(function () {
        return {
          done: callback => {
            this.success({
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
            })
            callback()
            return {fail: () => {}}
          },
        }
      })

      $testEl.moduleSequenceFooter({assetType: 'Assignment', assetID: 42, animation: false})

      expect($testEl.find('.module-sequence-footer.no-animation')).toHaveLength(1)
      expect($testEl.find('.module-sequence-padding.no-animation')).toHaveLength(1)

      $testEl.msfAnimation(true)

      expect($testEl.find('.module-sequence-footer:not(.no-animation)')).toHaveLength(1)
      expect($testEl.find('.module-sequence-padding:not(.no-animation)')).toHaveLength(1)
    })
  })

  describe('rendering', () => {
    it('shows no buttons when next and prev data are null', () => {
      MSFClass.prototype.fetch.mockImplementation(function () {
        return {
          done: callback => {
            this.success(nullButtonData())
            callback()
            return {fail: () => {}}
          },
        }
      })

      $testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})

      // Wait for React to render
      jest.runAllTimers()

      expect($testEl.find('[aria-label="Previous Module Item"]')).toHaveLength(0)
      expect($testEl.find('[aria-label="Next Module Item"]')).toHaveLength(0)
    })

    it('shows modules tooltip when current module id differs from next/prev module id', () => {
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

      MSFClass.prototype.fetch.mockImplementation(function () {
        return {
          done: callback => {
            this.success(moduleTooltipData)
            callback()
            return {fail: () => {}}
          },
        }
      })

      $testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})

      // Wait for React to render
      jest.runAllTimers()

      expect($testEl.find('[aria-label="Previous Module Item"]')).toHaveLength(1)
      expect($testEl.find('[aria-label="Next Module Item"]')).toHaveLength(1)
    })

    it('shows item tooltip when current module id matches next/prev module id', () => {
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

      MSFClass.prototype.fetch.mockImplementation(function () {
        return {
          done: callback => {
            this.success(itemTooltipData)
            callback()
            return {fail: () => {}}
          },
        }
      })

      $testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})

      // Wait for React to render
      jest.runAllTimers()

      expect($testEl.find('[aria-label="Previous Module Item"]')).toHaveLength(1)
      expect($testEl.find('[aria-label="Next Module Item"]')).toHaveLength(1)
    })

    it('uses module_item_id from URL as assetID with ModuleItem type', () => {
      let requestedUrl = ''
      MSFClass.prototype.fetch.mockImplementation(function () {
        requestedUrl = this.url + '?asset_type=ModuleItem&asset_id=999'
        return {
          done: callback => {
            callback()
            return {fail: () => {}}
          },
        }
      })

      $testEl.moduleSequenceFooter({
        courseID: 42,
        assetType: 'Assignment',
        assetID: 123,
        location: {search: '?module_item_id=999'},
      })

      expect(requestedUrl).toContain('asset_type=ModuleItem')
      expect(requestedUrl).toContain('asset_id=999')
    })

    it('shows element when rendering', () => {
      const showSpy = jest.spyOn($testEl, 'show')

      MSFClass.prototype.fetch.mockImplementation(function () {
        return {
          done: callback => {
            this.success({})
            $testEl.show()
            callback()
            return {fail: () => {}}
          },
        }
      })

      $testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})

      expect(showSpy).toHaveBeenCalled()
    })

    it('triggers resize event', done => {
      $(window).on('resize', () => {
        $(window).off('resize')
        done()
      })

      MSFClass.prototype.fetch.mockImplementation(function () {
        return {
          done: callback => {
            this.success({})
            $(window).trigger('resize')
            callback()
            return {fail: () => {}}
          },
        }
      })

      $testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})
    }, 15000)
  })

  describe('mastery paths', () => {
    it('shows correct tooltip when awaiting choice', () => {
      const pathData = moduleData({mastery_path: basePathData({awaiting_choice: true})})
      MSFClass.prototype.fetch.mockImplementation(function () {
        return {
          done: callback => {
            this.success(pathData)
            callback()
            return {fail: () => {}}
          },
        }
      })

      $testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})

      // Wait for React to render
      jest.runAllTimers()

      expect($testEl.find('[aria-label="Next Module Item"]')).toHaveLength(1)
      expect($testEl.find('a').attr('href')).toMatch('chew-z')
    })

    it('shows correct tooltip when sequence is locked', () => {
      const pathData = moduleData({mastery_path: basePathData({locked: true})})
      MSFClass.prototype.fetch.mockImplementation(function () {
        return {
          done: callback => {
            this.success(pathData)
            callback()
            return {fail: () => {}}
          },
        }
      })

      $testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})

      // Wait for React to render
      jest.runAllTimers()

      expect($testEl.find('[aria-label="Next Module Item"]')).toHaveLength(1)
      expect($testEl.find('a').attr('href')).toMatch('mod.module.mod')
    })

    it('disables next button when path is locked and modules tab is disabled', () => {
      const pathData = moduleData({
        mastery_path: basePathData({locked: true, modules_tab_disabled: true}),
      })
      MSFClass.prototype.fetch.mockImplementation(function () {
        return {
          done: callback => {
            this.success(pathData)
            callback()
            return {fail: () => {}}
          },
        }
      })

      $testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})

      // Wait for React to render
      jest.runAllTimers()

      expect($testEl.find('[aria-label="Next Module Item"][disabled]')).toHaveLength(1)
    })

    it('shows next button when no next items exist and paths are processing', () => {
      const pathData = moduleData({
        mastery_path: basePathData({
          is_student: true,
          still_processing: true,
          modules_url: 'mod.module.mod',
        }),
        next: null,
      })
      MSFClass.prototype.fetch.mockImplementation(function () {
        return {
          done: callback => {
            this.success(pathData)
            callback()
            return {fail: () => {}}
          },
        }
      })

      $testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})

      // Wait for React to render
      jest.runAllTimers()

      expect($testEl.find('[aria-label="Next Module Item"]')).toHaveLength(1)
      expect($testEl.find('a').attr('href')).toMatch('mod.module.mod')
    })
  })

  describe('external URLs', () => {
    it('announces new window for external URL links', () => {
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

      MSFClass.prototype.fetch.mockImplementation(function () {
        return {
          done: callback => {
            this.success(externalUrlTypeData)
            callback()
            return {fail: () => {}}
          },
        }
      })

      $testEl.moduleSequenceFooter({courseID: 42, assetType: 'Assignment', assetID: 123})

      // Wait for React to render
      jest.runAllTimers()

      expect($testEl.find('[aria-label="Previous Module Item"]')).toHaveLength(1)
      expect($testEl.find('[aria-label="Next Module Item - opens in new window"]')).toHaveLength(1)
    })
  })
})
