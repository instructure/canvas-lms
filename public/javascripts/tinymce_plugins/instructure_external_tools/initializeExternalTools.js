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
      buildToolsButton(ed, ltiButtons)
      buildFavoriteToolsButtons(ed, ltiButtons)
      buildMRUMenuButton(ed, ltiButtons)
      buildMenubarItem(ed, ltiButtons)
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

function registerToolIcon(ed, button) {
  if (!button.iconSVG && button.image) {
    // Sanitize input against XSS
    const svg = document.createElement('svg')
    svg.setAttribute('viewBox', '0 0 16 16')
    svg.setAttribute('version', '1.1')
    svg.setAttribute('xmlns', 'http://www.w3.org/2000/svg')
    const image = document.createElement('image')
    image.setAttribute('xlink:href', button.image)
    image.style.width = '100%'
    image.style.height = '100%'
    svg.appendChild(image)
    button.iconSVG = svg.outerHTML
    button.icon = `lti_tool_${button.id}`
  }
  if (button.iconSVG) {
    ed.ui.registry.addIcon(button.icon, button.iconSVG)
  }
}

// What I'd really like to do is start with a plain Apps button in the toolbar
// and menubar's Tools menu, then replace it with a menu button/nested menu item
// when there are MRU tools but I don't see a way to do that in tinymce.
// What this does is:
// for the toolbar: create both buttons and use CSS to show the one we want and hide the other
// for the item in the menubar's Tools menu: always show a nexted menu. With no MRU tools,
//    the submenu just shows "View All"

// register the Apps menu item in the menubar's Tools menu
function buildMenubarItem(ed, ltiButtons) {
  if (ltiButtons.length) {
    ed.ui.registry.addNestedMenuItem('lti_tools_menuitem', {
      text: I18n.t('Apps'),
      icon: 'lti',
      getSubmenuItems: () => getLtiMRUItems(ed, ltiButtons)
    })
  }
}

// register the Apps toolbar button for when there are no MRU apps
function buildToolsButton(ed, ltiButtons) {
  const tooltip = I18n.t('Apps')
  ed.ui.registry.addButton('lti_tool_dropdown', {
    onAction: () => {
      const ev = new CustomEvent('tinyRCE/onExternalTools', {detail: {ltiButtons}})
      document.dispatchEvent(ev)
    },
    icon: 'lti',
    tooltip,
    onSetup(_api) {
      // start off with the right button visible
      ExternalToolsHelper.showHideButtons(ed)
    }
  })
}

// register the favorite lti tools toolbar buttons
function buildFavoriteToolsButtons(ed, ltiButtons) {
  ltiButtons.forEach(button => {
    if (!button.favorite) return

    registerToolIcon(ed, button)
    ed.ui.registry.addButton(`instructure_external_button_${button.id}`, {
      onAction: button.onAction,
      tooltip: button.title,
      icon: button.icon,
      title: button.title
    })
  })
}

// register the Apps toolbar button for when there are MRU apps
function buildMRUMenuButton(ed, ltiButtons) {
  const tooltip = I18n.t('Apps')
  ed.ui.registry.addMenuButton('lti_mru_button', {
    tooltip,
    icon: 'lti',
    fetch(callback) {
      callback(getLtiMRUItems(ed, ltiButtons))
    },
    onSetup(_api) {
      ExternalToolsHelper.showHideButtons(ed)
    }
  })
}

// build the array of MRU app menu items
function getLtiMRUItems(ed, ltiButtons) {
  const mruMenuItems = []
  try {
    const mruIds = JSON.parse(window.localStorage.getItem('ltimru'))
    if (mruIds && Array.isArray(mruIds) && mruIds.length) {
      const mruButtons = ltiButtons.filter(b => mruIds.includes(b.id))
      mruButtons.forEach(b => {
        registerToolIcon(ed, b)
        if (!b.menuItem) {
          b.menuItem = {
            type: 'menuitem',
            text: b.title,
            icon: b.icon,
            onAction: b.onAction
          }
        }
        mruMenuItems.push(b.menuItem)
      })
      mruMenuItems.sort((a, b) => a.text.localeCompare(b.text))
    }
  } catch (ex) {
    // eslint-disable-next-line no-console
    console.log('Failed building mru menu', ex.message)
  } finally {
    mruMenuItems.push({
      type: 'menuitem',
      text: I18n.t('View All'),
      onAction: () => {
        const ev = new CustomEvent('tinyRCE/onExternalTools', {detail: {ltiButtons}})
        document.dispatchEvent(ev)
      }
    })
  }
  return mruMenuItems
}

export default ExternalToolsPlugin
