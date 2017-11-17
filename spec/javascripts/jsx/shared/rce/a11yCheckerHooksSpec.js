/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import {beforeCheck, afterCheck} from 'jsx/shared/rce/a11yCheckerHooks'

let fakeEditor

QUnit.module('beforeCheck', {
  setup() {
    window.ENV = {} || window.ENV
    window.ENV.url_for_high_contrast_tinymce_editor_css = [
      '/base/spec/javascripts/fixtures/a11yCheckerTest1.css',
      '/base/spec/javascripts/fixtures/a11yCheckerTest2.css'
    ]

    fakeEditor = {
      dom: {
        styleSheetLoader: {
          load(url, callback) {
            const link = document.createElement('link')
            link.href = url
            link.type = 'text/css'
            link.rel = 'stylesheet'
            link.onload = callback
            document.querySelector('#fixtures').appendChild(link)
          }
        },
        doc: {
          styleSheets: {
            0: {disabled: false},
            1: {disabled: false},
            2: {disabled: false},
            length: 3
          }
        }
      }
    }
  },
  teardown() {
    window.ENV.url_for_high_contrast_tinymce_editor_css = undefined
    document.querySelector('#fixtures').innerHTML = ''
  }
})

test('disables the last two stylesheets in the editor', () => {
  beforeCheck(fakeEditor)
  const ssArray = [].slice.call(fakeEditor.dom.doc.styleSheets)
  ok(!ssArray[0].disabled, 'first style sheet is not disabled')
  ok(ssArray[1].disabled, 'second style sheet is disabled')
  ok(ssArray[2].disabled, 'third style sheet is disabled')
})

test('calls load for each high contrast url', () => {
  fakeEditor.dom.styleSheetLoader.load = sinon.spy()
  beforeCheck(fakeEditor)
  ok(fakeEditor.dom.styleSheetLoader.load.calledTwice)
  window.ENV.url_for_high_contrast_tinymce_editor_css.forEach(url => {
    ok(fakeEditor.dom.styleSheetLoader.load.calledWith(url))
  })
})

test('calls done callback when complete', assert => {
  const done = assert.async()
  beforeCheck(fakeEditor, () => {
    ok(true, 'Callback was called')
    done()
  })
})

QUnit.module('afterCheck', {
  setup() {
    window.ENV = {} || window.ENV
    window.ENV.url_for_high_contrast_tinymce_editor_css = ['HC.css', 'HC2.css']

    fakeEditor = {
      dom: {
        doc: {
          styleSheets: {
            0: {
              disabled: false,
              ownerNode: {
                parentElement: {
                  removeChild: sinon.spy()
                }
              }
            },
            1: {
              disabled: true,
              href: 'nonHC.css',
              ownerNode: {
                parentElement: {
                  removeChild: sinon.spy()
                }
              }
            },
            2: {
              disabled: true,
              href: 'nonHC2.css',
              ownerNode: {
                parentElement: {
                  removeChild: sinon.spy()
                }
              }
            },
            3: {
              disabled: false,
              href: 'HC.css',
              ownerNode: {
                parentElement: {
                  removeChild: sinon.spy()
                }
              }
            },
            4: {
              disabled: false,
              href: 'HC2.css',
              ownerNode: {
                parentElement: {
                  removeChild: sinon.spy()
                }
              }
            },
            length: 5
          }
        }
      }
    }
  },
  teardown() {
    document.querySelector('#fixtures').innerHTML = ''
  }
})

test('removes anything added by the a11yChecker', () => {
  afterCheck(fakeEditor)
  ok(
    !fakeEditor.dom.doc.styleSheets[0].ownerNode.parentElement.removeChild.called,
    'Did not call for the skin stylesheet'
  )
  ok(
    !fakeEditor.dom.doc.styleSheets[1].ownerNode.parentElement.removeChild.called,
    'Did not call for the first non-HC stylesheet'
  )
  ok(
    !fakeEditor.dom.doc.styleSheets[2].ownerNode.parentElement.removeChild.called,
    'Did not call for the second non-HC stylesheet'
  )
  ok(
    fakeEditor.dom.doc.styleSheets[3].ownerNode.parentElement.removeChild.called,
    'Called for the first HC stylesheet'
  )
  ok(
    fakeEditor.dom.doc.styleSheets[4].ownerNode.parentElement.removeChild.called,
    'Called for the second HC stylesheet'
  )
})

test('enables styleSheets disabled by the a11yChecker', () => {
  afterCheck(fakeEditor)
  const ssArray = [].slice.call(fakeEditor.dom.doc.styleSheets)
  ok(!ssArray[0].disabled, 'first style sheet is not disabled')
  ok(!ssArray[1].disabled, 'second style sheet is not disabled')
  ok(!ssArray[2].disabled, 'third style sheet is not disabled')
})
