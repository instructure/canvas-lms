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

import React, {useEffect, useRef, useState} from 'react'
import ReactDOM from 'react-dom'
import RCE from '../src/rce/RCE'
import DemoOptions from './DemoOptions'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import '@instructure/canvas-theme'

import * as fakeSource from '../src/rcs/fake'

import './test-plugin/plugin'

function getSetting(settingKey, defaultValue) {
  let val = localStorage.getItem(settingKey) || defaultValue
  if (typeof defaultValue === 'boolean') {
    val = val === 'true'
  }
  return val
}

function saveSetting(settingKey, settingValue) {
  localStorage.setItem(settingKey, settingValue)
}

function saveSettings(state) {
  ;[
    'canvas_exists',
    'dir',
    'sourceType',
    'lang',
    'host',
    'jwt',
    'contextType',
    'contextId',
    'userId',
    'include_test_plugin',
    'test_plugin_toolbar',
    'test_plugin_menu',
    'readonly'
  ].forEach(settingKey => {
    saveSetting(settingKey, state[settingKey])
  })
}

function Demo() {
  const [canvas_exists, set_canvas_exists] = useState(() => getSetting('canvas_exists', false))
  const [canvas_origin, set_canvas_origin] = useState(() =>
    getSetting('canvas_origin', 'http://localhost:3000')
  )
  const [dir, set_dir] = useState(() => getSetting('dir', 'ltr'))
  const [host, set_host] = useState(() => getSetting('host', 'http:/who.cares')) // 'https://rich-content-iad.inscloudgate.net'
  const [jwt, set_jwt] = useState(() => getSetting('jwt', 'doesnotmatteriffake'))
  const [contextType, set_contextType] = useState(() => getSetting('contextType', 'course'))
  const [contextId, set_contextId] = useState(() => getSetting('contextId', '1'))
  const [userId, set_userId] = useState(() => getSetting('userId', '1'))
  const [sourceType, set_sourceType] = useState(() => getSetting('sourceType', 'fake'))
  const [lang, set_lang] = useState(() => getSetting('lang', 'en'))
  const [include_test_plugin, set_include_test_plugin] = useState(
    getSetting('include_test_plugin', false)
  )
  const [test_plugin_toolbar, set_test_plugin_toolbar] = useState(
    getSetting('test_plugin_toolbar', '__none__')
  )
  const [test_plugin_menu, set_test_plugin_menu] = useState(
    getSetting('test_plugin_menu', '__none__')
  )
  const [rcsProps, set_rcsProps] = useState(() => getRcsPropsFromOpts())
  const [toolbar, set_toolbar] = useState(() => updateToolbar())
  const [menu, set_menu] = useState(() => updateMenu())
  const [plugins, set_plugins] = useState(() => updatePlugins())
  const [currentContent, setCurrentContent] = useState('')
  const [readonly, set_readonly] = useState(() => getSetting('readonly', false))

  const rceRef = useRef(null)

  useEffect(() => {
    document.documentElement.setAttribute('dir', dir)
  }, [dir])
  useEffect(() => {
    document.documentElement.setAttribute('lang', lang)
  }, [lang])

  function handleOptionsChange(newOpts) {
    const refresh =
      canvas_exists !== newOpts.canvas_exists ||
      lang !== newOpts.lang ||
      include_test_plugin !== newOpts.include_test_plugin ||
      test_plugin_toolbar !== newOpts.test_plugin_toolbar ||
      test_plugin_menu !== newOpts.test_plugin_menu

    set_canvas_exists(newOpts.canvas_exists)
    set_canvas_origin(newOpts.canvas_origin)
    set_dir(newOpts.dir)
    set_host(newOpts.host)
    set_jwt(newOpts.jwt)
    set_contextType(newOpts.contextType)
    set_contextId(newOpts.contextId)
    set_userId(newOpts.userId)
    set_sourceType(newOpts.sourceType)
    set_lang(newOpts.lang)
    set_include_test_plugin(newOpts.include_test_plugin)
    set_test_plugin_toolbar(newOpts.test_plugin_toolbar)
    set_test_plugin_menu(newOpts.test_plugin_menu)
    set_rcsProps(getRcsPropsFromOpts())
    set_toolbar(updateToolbar())
    set_menu(updateMenu())
    set_plugins(updatePlugins())
    set_readonly(newOpts.readonly)

    saveSettings(newOpts)

    if (refresh) {
      window.location.reload()
    }
  }

  function getRcsPropsFromOpts() {
    return canvas_exists
      ? {
          canUploadFiles: true,
          contextId,
          contextType,
          containingContext: {
            contextType,
            contextId,
            userId
          },
          filesTabDisabled: false,
          host,
          jwt,
          refreshToken:
            sourceType === 'real'
              ? refreshCanvasToken.bind(null, canvas_origin)
              : () => {
                  Promise.resolve({jwt})
                },
          source: jwt && sourceType === 'real' ? undefined : fakeSource,
          themeUrl: ''
        }
      : undefined
  }

  function updateToolbar() {
    return include_test_plugin && test_plugin_toolbar !== '__none__'
      ? [
          {
            name: test_plugin_toolbar,
            items: ['rce_demo_test']
          }
        ]
      : undefined
  }
  function updateMenu() {
    return include_test_plugin && test_plugin_menu !== '__none__'
      ? {
          [test_plugin_menu]: {title: 'Test Plugin', items: 'rce_demo_test'}
        }
      : undefined
  }

  function updatePlugins() {
    return include_test_plugin ? ['rce_demo_test'] : undefined
  }

  return (
    <>
      <main className="main" id="content">
        <RCE
          ref={rceRef}
          language={lang}
          textareaId="textarea3"
          defaultContent="hello RCE"
          readOnly={readonly}
          editorOptions={{
            height: 350,
            toolbar,
            menu,
            plugins
          }}
          highContrastCSS={[]}
          rcsProps={rcsProps}
          onInitted={editor => {
            setCurrentContent(editor.getContent())
          }}
          onContentChange={value => {
            setCurrentContent(value)
          }}
        />
        <View as="div" margin="small 0 0 0">
          <pre>{currentContent}</pre>
        </View>
        <View as="div" margin="small 0 0 0">
          <Button
            interaction={rceRef.current ? 'enabled' : 'disabled'}
            onClick={() => {
              alert(rceRef.current.getCode())
            }}
          >
            Get Code
          </Button>
          &nbsp;&nbsp;
          <Button
            interaction={rceRef.current ? 'enabled' : 'disabled'}
            onClick={() => {
              rceRef.current.setCode('<p>Hello world</p>')
            }}
          >
            Set Code
          </Button>
        </View>
      </main>
      <div className="sidebar">
        <div id="options">
          <DemoOptions
            canvas_exists={canvas_exists}
            canvas_origin={canvas_origin}
            host={host}
            jwt={jwt}
            contextType={contextType}
            contextId={contextId}
            userId={userId}
            sourceType={sourceType}
            lang={lang}
            dir={dir}
            include_test_plugin={include_test_plugin}
            test_plugin_toolbar={test_plugin_toolbar}
            test_plugin_menu={test_plugin_menu}
            readonly={readonly}
            onChange={handleOptionsChange}
          />
        </div>
      </div>
    </>
  )
}

// adapted from canvas-lms/ui/shared/rce/jwt.js
function refreshCanvasToken(canvas_origin, initialToken) {
  let token = initialToken
  let promise = null

  return done => {
    if (promise === null) {
      promise = fetch(`${canvas_origin}/api/v1/jwts/refresh`, {
        method: 'POST',
        mode: 'cors',
        body: JSON.stringify({jwt: token})
      }).then(resp => {
        promise = null
        token = resp.data.token
        return token
      })
    }

    if (typeof done === 'function') {
      promise.then(done)
    }

    return promise
  }
}

ReactDOM.render(<Demo />, document.getElementById('demo'))
