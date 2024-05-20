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

import React from 'react'
import ReactDOM from 'react-dom'
import Checker from './components/checker'
import formatMessage from '../../../format-message'
import checkNode from './node-checker'

let isCheckerOpen = false
let instance
const pendingInstanceCallbacks = []
const container = document.createElement('div')
container.className = 'tinymce-a11y-checker-container'
document.body.appendChild(container)

tinymce.create('tinymce.plugins.AccessibilityChecker', {
  init(ed) {
    ed.addCommand(
      'openAccessibilityChecker',
      function (ui, {done, config, additionalRules, mountNode, triggerElementId, onFixError}) {
        if (!isCheckerOpen) {
          ReactDOM.render(
            <Checker
              getBody={ed.getBody.bind(ed)}
              editor={ed}
              additionalRules={additionalRules}
              mountNode={mountNode}
              onClose={() => {
                isCheckerOpen = false;
                if(triggerElementId){
                    const button = document.querySelectorAll(`[data-btn-id=${triggerElementId}]`);
                    button[0]?.focus();
                }
              }}
              onFixError={onFixError}
            />,
            container,
            function () {
              // this is a workaround for react 16 since ReactDOM.render is not
              // guaranteed to return the instance synchronously (especially if called
              // within another component's lifecycle method eg: componentDidMount). see:
              // https://github.com/facebook/react/issues/10309#issuecomment-318434635
              instance = this
              if (config) getInstance(instance => instance.setConfig(config))
              pendingInstanceCallbacks.forEach(cb => cb(instance))
              instance.check(done)
            }
          )
          isCheckerOpen = true
        }
      }
    )

    ed.addCommand('checkAccessibility', function (ui, {done, config, additionalRules}) {
      checkNode(ed.getBody(), done, config, additionalRules)
    })

    ed.ui.registry.addButton('check_a11y', {
      title: formatMessage('Check Accessibility'),
      onAction: _ => ed.execCommand('openAccessibilityChecker'),
      icon: 'a11y',
    })
  },
})

// Register plugin
tinymce.PluginManager.add('a11y_checker', tinymce.plugins.AccessibilityChecker)

export function getInstance(cb) {
  if (instance != null) {
    return cb(instance)
  }
  pendingInstanceCallbacks.push(cb)
}

export function setLocale(locale) {
  const options = formatMessage.setup()
  options.locale = locale
  formatMessage.setup(options)
}
