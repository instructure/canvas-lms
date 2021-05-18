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

import React, {useEffect, useState} from 'react'
import ReactDOM from 'react-dom'
import CanvasRce from '../src/rce/CanvasRce'
import DemoOptions from './DemoOptions'
import '@instructure/canvas-theme'

import * as fakeSource from '../src/sidebar/sources/fake'

// import './test-plugin/plugin'

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
    'userId'
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
  const [trayProps, set_trayProps] = useState(() => getTrayPropsFromOpts())
  const [toolbar, set_toolbar] = useState(() => updateToolbar())
  const [plugins, set_plugins] = useState(() => updatePlugins())
  const [tinymce_editor, set_tinymce_editor] = useState(null)

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
      include_test_plugin !== newOpts.include_test_plugin

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
    set_trayProps(getTrayPropsFromOpts())
    set_toolbar(updateToolbar())
    set_plugins(updatePlugins())

    saveSettings(newOpts)

    if (refresh) {
      window.location.reload()
    }
  }

  function getTrayPropsFromOpts() {
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
    return include_test_plugin
      ? [
          {
            name: 'Content',
            items: ['rce_demo_test']
          }
        ]
      : undefined
  }

  function updatePlugins() {
    return include_test_plugin ? ['rce_demo_test'] : undefined
  }

  return (
    <>
      <main className="main" id="content">
        <CanvasRce
          language={lang}
          textareaId="textarea3"
          defaultContent="hello RCE"
          height={350}
          highContrastCSS={[]}
          trayProps={trayProps}
          toolbar={toolbar}
          plugins={plugins}
          onInitted={editor => {
            set_tinymce_editor(editor)
          }}
        />
        ,
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
