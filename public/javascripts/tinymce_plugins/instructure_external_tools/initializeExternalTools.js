/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import I18n from 'i18n!ExternalToolsPlugin'
import $ from 'jquery'
import htmlEscape from '../../str/htmlEscape'
import ExternalToolsHelper from './ExternalToolsHelper'
import iframeAllowances from 'jsx/external_apps/lib/iframeAllowances'
import Links from '../instructure_links/links'
import React from 'react'
import ReactDOM from 'react-dom'

const TRANSLATIONS = {
  get more_external_tools() {
    return htmlEscape(I18n.t('more_external_tools', 'More External Tools'))
  }
}

const ExternalToolsPlugin = {
  init(ed, url, _INST) {
    Links.initEditor(ed)
    if (!_INST || !_INST.editorButtons || !_INST.editorButtons.length) {
      return
    }

    let dialog = {
      // if somehow open gets called early, keep trying until it is ready
      open: (...args) => setTimeout(() => dialog.open(...args), 50)
    }
    import('jsx/editor/ExternalToolDialog').then(({default: ExternalToolDialog}) => {
      const dialogContainer = document.createElement('div')
      document.body.appendChild(dialogContainer)
      ReactDOM.render(
        <ExternalToolDialog
          win={window}
          editor={ed}
          contextAssetString={ENV.context_asset_string}
          iframeAllowances={iframeAllowances()}
          resourceSelectionUrl={$('#context_external_tool_resource_selection_url').attr('href')}
          deepLinkingOrigin={ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN}
        />,
        dialogContainer,
        function() {
          dialog = this
        }
      )
    })

    const clumpedButtons = []
    const ltiButtons = []
    for (let idx = 0; _INST.editorButtons && idx < _INST.editorButtons.length; idx++) {
      const current_button = _INST.editorButtons[idx]
      // eslint-disable-next-line no-loop-func
      const openDialog = () => dialog.open(current_button)
      if (ENV.use_rce_enhancements) {
        ltiButtons.push(ExternalToolsHelper.buttonConfig(current_button, ed))
        ed.addCommand(`instructureExternalButton${current_button.id}`, openDialog)
      } else if (
        _INST.editorButtons.length > _INST.maxVisibleEditorButtons &&
        idx >= _INST.maxVisibleEditorButtons - 1
      ) {
        clumpedButtons.push(current_button)
      } else {
        ed.addCommand(`instructureExternalButton${current_button.id}`, openDialog)
        ed.addButton(
          `instructure_external_button_${current_button.id}`,
          ExternalToolsHelper.buttonConfig(current_button, ed)
        )
      }
    }
    if (ltiButtons.length && ENV.use_rce_enhancements) {
      ed.ui.registry.addButton('lti_tool_dropdown', {
        onAction: () => {
          const ev = new CustomEvent('tinyRCE/onExternalTools', {detail: {ltiButtons}})
          document.dispatchEvent(ev)
        },
        icon: 'lti',
        tooltip: 'Apps'
      })
      ltiButtons.forEach(button => {
        if (!button.favorite) return

        // Sanitize input against XSS
        const svg = document.createElement('svg')
        svg.setAttribute('viewBox', '0 0 16 16')
        svg.setAttribute('version', '1.1')
        svg.setAttribute('xmlns', 'http://www.w3.org/2000/svg')
        const image = document.createElement('image')
        image.setAttribute('xlink:href', button.image)
        svg.appendChild(image)
        const div = document.createElement('div')
        div.appendChild(svg)

        ed.ui.registry.addIcon(`favorite_lti_tool_${button.id}`, div.innerHTML)
        ed.ui.registry.addButton(`instructure_external_button_${button.id}`, {
          onAction: () => button.onAction(),
          tooltip: button.title,
          icon: `favorite_lti_tool_${button.id}`,
          title: button.title
        })
      })
    }
    if (clumpedButtons.length) {
      const handleClick = function() {
        const items = ExternalToolsHelper.clumpedButtonMapping(clumpedButtons, ed, button =>
          dialog.open(button)
        )
        ExternalToolsHelper.attachClumpedDropdown($(`#${this._id}`), items, ed)
      }

      if (ENV.use_rce_enhancements) {
        ed.ui.registry.addButton('instructure_external_button_clump', {
          title: TRANSLATIONS.more_external_tools,
          image: '/images/downtick.png',
          onAction: handleClick
        })
      } else {
        ed.addButton('instructure_external_button_clump', {
          title: TRANSLATIONS.more_external_tools,
          image: '/images/downtick.png',
          onkeyup(event) {
            if (event.keyCode === 32 || event.keyCode === 13) {
              event.stopPropagation()
              handleClick.call(this)
            }
          },
          onclick: handleClick
        })
      }
    }
  }
}

export default ExternalToolsPlugin
