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

import formatMessage from '../../../../format-message'

export default function(editor) {
  // pretty much copied from the directionality plugin
  function generateSelector(dir) {
    const selector = 'h1 h2 h3 h4 h5 h6 div p'.split(' ').map(name => {
      return name + `[dir=${dir}]`
    })
    return selector.join(',')
  }

  function defaultDirectionality() {
    return document.dir
  }

  function currentDirectionality() {
    return ['ltr', 'rtl'].find(dir => {
      const selector = generateSelector(dir)
      const selectionNode = editor.selection.getNode()
      if (editor.dom.is(selectionNode, selector)) return true
      return !!editor.dom.getParent(selectionNode, selector, editor.dom.getRoot())
    })
  }

  function actionButtonDirectionality() {
    const current = currentDirectionality()
    if (current) return current

    // otherwise we want the opposite of the default because clicking on the
    // button should change something
    if (defaultDirectionality() === 'ltr') return 'rtl'
    else return 'ltr'
  }

  const directionalityToolbarButtons = [
    {
      name: 'ltr',
      text: formatMessage('left to right'),
      cmd: 'mceDirectionLTR',
      icon: 'ltr'
    },
    {
      name: 'rtl',
      text: formatMessage('right to left'),
      cmd: 'mceDirectionRTL',
      icon: 'rtl'
    }
  ]
  if (defaultDirectionality() === 'rtl') directionalityToolbarButtons.reverse()

  const directionalityButtonLabel = formatMessage('directionality')

  editor.ui.registry.addSplitButton('directionality', {
    tooltip: directionalityButtonLabel,
    icon: 'ltr',
    presets: 'listpreview',
    columns: 2,

    fetch: callback => {
      const items = directionalityToolbarButtons.map(button => {
        return {
          type: 'choiceitem',
          value: button.cmd,
          icon: button.icon,
          text: button.text
        }
      })
      callback(items)
    },

    onAction: () => {
      const desiredChange = actionButtonDirectionality()
      if (desiredChange === 'ltr') editor.execCommand('mceDirectionLTR')
      else editor.execCommand('mceDirectionRTL')
    },

    onItemAction: (splitButtonApi, value) => {
      editor.execCommand(value)
      editor.nodeChanged()
    },

    select: value => {
      const current = currentDirectionality()
      const valueDir = value === 'mceDirectionLTR' ? 'ltr' : 'rtl'
      return current === valueDir
    },

    onSetup: api => {
      const $svgContainer = editor.$(
        editor.editorContainer.querySelector(
          `[aria-label="${directionalityButtonLabel}"] .tox-icon`
        )
      )
      const allIcons = editor.ui.registry.getAll().icons

      function nodeChangeHandler() {
        const current = currentDirectionality()
        api.setActive(!!current)

        const desiredDirection = actionButtonDirectionality()
        const svg = allIcons[desiredDirection]
        $svgContainer.html(svg)
      }
      editor.on('NodeChange', nodeChangeHandler)
      return () => editor.off('NodeChange', nodeChangeHandler)
    }
  })
}
