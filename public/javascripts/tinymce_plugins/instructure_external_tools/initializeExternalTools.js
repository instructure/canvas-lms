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

import I18n from 'i18n!editor'
import $ from 'jquery'
import htmlEscape from '../../str/htmlEscape'
import ExternalToolsHelper from 'tinymce_plugins/instructure_external_tools/ExternalToolsHelper'
import iframeAllowances from 'jsx/external_apps/lib/iframeAllowances'
import '../../jquery.instructure_misc_helpers'
import 'jqueryui/dialog'
import '../../jquery.instructure_misc_plugins'
import Links from 'tinymce_plugins/instructure_links/links'
import ExternalToolDialog from 'jsx/editor/ExternalToolDialog'
import React from 'react'
import ReactDOM from 'react-dom'

const TRANSLATIONS = {
  more_external_tools: htmlEscape(I18n.t('more_external_tools', 'More External Tools'))
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

    const clumpedButtons = []
    for (let idx = 0; _INST.editorButtons && idx < _INST.editorButtons.length; idx++) {
      const current_button = _INST.editorButtons[idx]
      if (
        _INST.editorButtons.length > _INST.maxVisibleEditorButtons &&
        idx >= _INST.maxVisibleEditorButtons - 1
      ) {
        clumpedButtons.push(current_button)
      } else {
        // eslint-disable-next-line no-loop-func
        ed.addCommand(`instructureExternalButton${current_button.id}`, () => {
          dialog.open(current_button)
        })
        ed.addButton(
          `instructure_external_button_${current_button.id}`,
          ExternalToolsHelper.buttonConfig(current_button)
        )
      }
    }
    if (clumpedButtons.length) {
      const handleClick = function() {
        const items = ExternalToolsHelper.clumpedButtonMapping(clumpedButtons, ed, button =>
          dialog.open(button)
        )
        ExternalToolsHelper.attachClumpedDropdown($(`#${this._id}`), items, ed)
      }

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

export default ExternalToolsPlugin
