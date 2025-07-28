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

import FakeEditor from './FakeEditor'

import RCEWrapper, {
  mergeMenu,
  mergeMenuItems,
  mergePlugins,
  mergeToolbar,
  parsePluginsToExclude,
} from '../RCEWrapper'

const textareaId = 'myUniqId'

let fakeTinyMCE, editor, rce

function createBasicElement(opts) {
  editor = new FakeEditor({id: textareaId})
  fakeTinyMCE.get = () => editor

  const props = {textareaId, tinymce: fakeTinyMCE, ...trayProps(), ...defaultProps(), ...opts}
  rce = new RCEWrapper(props)
  rce.editor = editor // usually set in onInit which isn't called when not rendered
  return rce
}

function trayProps() {
  return {
    trayProps: {
      canUploadFiles: true,
      host: 'rcs.host',
      jwt: 'donotlookatme',
      contextType: 'course',
      contextId: '17',
      containingContext: {
        userId: '1',
        contextType: 'course',
        contextId: '17',
      },
    },
  }
}

// many of the tests call `new RCEWrapper`, so there's no React
// to provide the default props
function defaultProps() {
  return {
    textareaId,
    highContrastCSS: [],
    languages: [{id: 'en', label: 'English'}],
    autosave: {enabled: false},
    ltiTools: [],
    editorOptions: {},
    liveRegion: () => document.getElementById('flash_screenreader_holder'),
    features: {},
    canvasOrigin: 'http://canvas.docker',
  }
}

describe('RCEWrapper', () => {
  // ====================
  //   SETUP & TEARDOWN
  // ====================
  beforeEach(() => {
    document.body.innerHTML = `
     <div id="flash_screenreader_holder" role="alert"/>
      <div id="app">
        <textarea id="${textareaId}"></textarea>
        <div id="container" style="width:500px;height:500px;" />
      </div>
    `
    document.documentElement.dir = 'ltr'

    fakeTinyMCE = {
      triggerSave: () => 'called',
      execCommand: () => 'command executed',
      // plugins
      create: () => {},
      PluginManager: {
        add: () => {},
      },
      get: () => editor,
      plugins: {
        AccessibilityChecker: {},
      },
    }
    global.tinymce = fakeTinyMCE
  })

  afterEach(function () {
    document.body.innerHTML = ''
    jest.restoreAllMocks()
  })

  describe('Extending the toolbar and menus', () => {
    const sleazyDeepCopy = a => JSON.parse(JSON.stringify(a))

    describe('mergeMenuItems', () => {
      it('returns input if no custom commands are provided', () => {
        const a = 'foo bar | baz'
        const c = mergeMenuItems(a)
        expect(c).toStrictEqual(a)
      })

      it('merges 2 lists of commands', () => {
        const a = 'foo bar | baz'
        const b = 'fizz buzz'
        const c = mergeMenuItems(a, b)
        expect(c).toStrictEqual('foo bar | baz | fizz buzz')
      })

      it('respects the | grouping separator', () => {
        const a = 'foo bar | baz'
        const b = 'fizz | buzz'
        const c = mergeMenuItems(a, b)
        expect(c).toStrictEqual('foo bar | baz | fizz | buzz')
      })

      it('removes duplicates and strips trailing |', () => {
        const a = 'foo bar | baz'
        const b = 'fizz buzz | baz'
        const c = mergeMenuItems(a, b)
        expect(c).toStrictEqual('foo bar | baz | fizz buzz')
      })

      it('removes duplicates and strips leading |', () => {
        const a = 'foo bar | baz'
        const b = 'baz | fizz buzz '
        const c = mergeMenuItems(a, b)
        expect(c).toStrictEqual('foo bar | baz | fizz buzz')
      })
    })

    describe('mergeMenus', () => {
      let standardMenu
      beforeEach(() => {
        standardMenu = {
          format: {
            items: 'bold italic underline | removeformat',
            title: 'Format',
          },
          insert: {
            items: 'instructure_links | inserttable instructure_media_embed | hr',
            title: 'Insert',
          },
          tools: {
            items: 'instructure_wordcount',
            title: 'Tools',
          },
        }
      })
      it('returns input if no custom menus are provided', () => {
        const a = sleazyDeepCopy(standardMenu)
        expect(mergeMenu(a)).toStrictEqual(standardMenu)
      })

      it('merges items into an existing menu', () => {
        const a = sleazyDeepCopy(standardMenu)
        const b = {
          tools: {
            items: 'foo bar',
          },
        }
        const result = sleazyDeepCopy(standardMenu)
        result.tools.items = 'instructure_wordcount | foo bar'
        expect(mergeMenu(a, b)).toStrictEqual(result)
      })

      it('adds a new menu', () => {
        const a = sleazyDeepCopy(standardMenu)
        const b = {
          new_menu: {
            title: 'New Menu',
            items: 'foo bar',
          },
        }
        const result = sleazyDeepCopy(standardMenu)
        result.new_menu = {
          items: 'foo bar',
          title: 'New Menu',
        }
        expect(mergeMenu(a, b)).toStrictEqual(result)
      })

      it('merges items _and_ adds a new menu', () => {
        const a = sleazyDeepCopy(standardMenu)
        const b = {
          tools: {
            items: 'foo bar',
          },
          new_menu: {
            title: 'New Menu',
            items: 'foo bar',
          },
        }
        const result = sleazyDeepCopy(standardMenu)
        result.tools.items = 'instructure_wordcount | foo bar'
        result.new_menu = {
          items: 'foo bar',
          title: 'New Menu',
        }
        expect(mergeMenu(a, b)).toStrictEqual(result)
      })
    })

    describe('mergeToolbar', () => {
      let standardToolbar
      beforeEach(() => {
        standardToolbar = [
          {
            items: ['fontsizeselect', 'formatselect'],
            name: 'Styles',
          },
          {
            items: ['bold', 'italic', 'underline'],
            name: 'Formatting',
          },
        ]
      })

      it('returns input if no custom toolbars are provided', () => {
        const a = sleazyDeepCopy(standardToolbar)
        expect(mergeToolbar(a)).toStrictEqual(standardToolbar)
      })

      it('merges items into the toolbar', () => {
        const a = sleazyDeepCopy(standardToolbar)
        const b = [
          {
            name: 'Formatting',
            items: ['foo', 'bar'],
          },
        ]
        const result = sleazyDeepCopy(standardToolbar)
        result[1].items = ['bold', 'italic', 'underline', 'foo', 'bar']
        expect(mergeToolbar(a, b)).toStrictEqual(result)
      })

      it('adds a new toolbar if necessary', () => {
        const a = sleazyDeepCopy(standardToolbar)
        const b = [
          {
            name: 'I Am New',
            items: ['foo', 'bar'],
          },
        ]
        const result = sleazyDeepCopy(standardToolbar)
        result[2] = {
          items: ['foo', 'bar'],
          name: 'I Am New',
        }
        expect(mergeToolbar(a, b)).toStrictEqual(result)
      })

      it('merges toolbars and adds a new one', () => {
        const a = sleazyDeepCopy(standardToolbar)
        const b = [
          {
            name: 'Formatting',
            items: ['foo', 'bar'],
          },
          {
            name: 'I Am New',
            items: ['foo', 'bar'],
          },
        ]
        const result = sleazyDeepCopy(standardToolbar)
        result[1].items = ['bold', 'italic', 'underline', 'foo', 'bar']
        result[2] = {
          items: ['foo', 'bar'],
          name: 'I Am New',
        }
        expect(mergeToolbar(a, b)).toStrictEqual(result)
      })
    })

    describe('mergePlugins', () => {
      let standardPlugins
      beforeEach(() => {
        standardPlugins = ['foo', 'bar', 'baz']
      })

      it('returns input if no custom or excluded plugins are provided', () => {
        const standard = sleazyDeepCopy(standardPlugins)
        expect(mergePlugins(standard)).toStrictEqual(standard)
      })

      it('merges items into the plugins', () => {
        const standard = sleazyDeepCopy(standardPlugins)
        const custom = ['fizz', 'buzz']
        const result = standardPlugins.concat(custom)
        expect(mergePlugins(standard, custom)).toStrictEqual(result)
      })

      it('removes duplicates', () => {
        const standard = sleazyDeepCopy(standardPlugins)
        const custom = ['foo', 'fizz']
        const result = standardPlugins.concat(['fizz'])
        expect(mergePlugins(standard, custom)).toStrictEqual(result)
      })

      it('removes plugins marked to exlude', () => {
        const standard = sleazyDeepCopy(standardPlugins)
        const custom = ['foo', 'fizz']
        const exclusions = ['fizz', 'baz']
        const result = ['foo', 'bar']
        expect(mergePlugins(standard, custom, exclusions)).toStrictEqual(result)
      })
    })

    describe('configures menus', () => {
      it('includes instructure_media in plugins if not instRecordDisabled', () => {
        const instance = createBasicElement({instRecordDisabled: false})
        expect(instance.tinymceInitOptions.plugins.includes('instructure_record')).toBeTruthy()
      })

      it('removes instructure_media from plugins if instRecordDisabled is set', () => {
        const instance = createBasicElement({instRecordDisabled: true})
        expect(instance.tinymceInitOptions.plugins.includes('instructure_record')).toBeFalsy()
      })
    })

    describe('parsePluginsToExclude', () => {
      it('returns cleaned versions of plugins prefixed with a hyphen', () => {
        const plugins = ['-abc', 'def', '-ghi', 'jkl']
        const result = ['abc', 'ghi']
        expect(parsePluginsToExclude(plugins)).toStrictEqual(result)
      })
    })
  })

  describe('lti tools for toolbar', () => {
    it('extracts favorites', () => {
      const element = createBasicElement({
        ltiTools: [
          {
            canvas_icon_class: null,
            description: 'the thing',
            favorite: true,
            height: 160,
            id: 1,
            name: 'A Tool',
            width: 340,
          },
          {
            canvas_icon_class: null,
            description: 'another thing',
            favorite: false,
            height: 600,
            id: 2,
            name: 'Not a favorite tool',
            width: 560,
          },
          {
            canvas_icon_class: null,
            description: 'another thing',
            favorite: true,
            height: 600,
            id: 3,
            name: 'Another Tool',
            width: 560,
          },
          {
            canvas_icon_class: null,
            description: 'yet another thing',
            favorite: true,
            height: 600,
            id: 4,
            name: 'Yet Another Tool',
            width: 560,
          },
        ],
      })

      expect(element.ltiToolFavorites).toStrictEqual([
        'instructure_external_button_1',
        'instructure_external_button_3',
      ])
    })

    it('extracts on_by_default tools', () => {
      const element = createBasicElement({
        ltiTools: [
          {
            canvas_icon_class: null,
            description: 'first',
            favorite: false,
            height: 160,
            width: 340,
            id: 1,
            name: 'An Always On Tool',
            on_by_default: true,
          },
          {
            canvas_icon_class: null,
            description: 'the thing',
            favorite: true,
            height: 160,
            id: 2,
            name: 'A Tool',
            width: 340,
            on_by_default: false,
          },
          {
            canvas_icon_class: null,
            description: 'other thing',
            favorite: true,
            height: 160,
            id: 3,
            name: 'A Tool',
            on_by_default: true,
          },
        ],
      })

      // The order here is important, as the on by default tools should be at the beginning!
      expect(element.ltiToolFavorites).toStrictEqual([
        'instructure_external_button_3',
        'instructure_external_button_2',
      ])
    })
  })
})
