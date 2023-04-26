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

import PropTypes, {InferType} from 'prop-types'
import {trayPropTypes} from './plugins/shared/CanvasContentTray'
import {PRETTY_HTML_EDITOR_VIEW, RAW_HTML_EDITOR_VIEW, WYSIWYG_VIEW} from './StatusBar'

// This file contains the prop types for the RCEWrapper component, so that types can be shared without having
// to refactor RCEWrapper.js into typescript.

export const toolbarPropType = PropTypes.arrayOf(
  PropTypes.shape({
    // name of the toolbar the items are added to
    // if this toolbar doesn't exist, it is created
    // tinymce toolbar config does not
    // include a key to identify the individual toolbars, just a name
    // which is translated. This toolbar's name must be translated
    // in order to be merged correctly.
    name: PropTypes.string.isRequired,
    // items added to the toolbar
    // each is the name of the button some plugin has
    // registered with tinymce
    items: PropTypes.arrayOf(PropTypes.string).isRequired,
  })
)

export type ToolbarPropType = InferType<typeof toolbarPropType>

export const menuPropType = PropTypes.objectOf(
  // the key is the name of the menu item a plugin has
  // registered with tinymce. If it does not exist in the
  // default menubar, it will be added.
  PropTypes.shape({
    // if this is a new menu in the menubar, title is it's label.
    // if these are items being merged into an existing menu, title is ignored
    title: PropTypes.string,
    // items is a space separated list it menu_items
    // some plugin has registered with tinymce
    items: PropTypes.string.isRequired,
  })
)

export type MenuPropType = InferType<typeof menuPropType>

export const ltiToolsPropType = PropTypes.arrayOf(
  PropTypes.shape({
    // id of the tool
    id: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),

    // is this a favorite tool?
    favorite: PropTypes.bool,

    name: PropTypes.string,
    description: PropTypes.string,
    icon_url: PropTypes.string,
    height: PropTypes.number,
    width: PropTypes.number,
    use_tray: PropTypes.bool,
    canvas_icon_class: PropTypes.string,
  })
)

export type LtiToolsPropType = InferType<typeof ltiToolsPropType>

export const editorOptionsPropType = PropTypes.shape({
  // height of the RCE.
  // if a number interpreted as pixels.
  // if a string as a CSS value.
  height: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
  // entries you want merged into the toolbar. See toolBarPropType above.
  toolbar: toolbarPropType,
  // entries you want merged into to the menus. See menuPropType above.
  // If an entry defines a new menu, tinymce's menubar config option will
  // be updated for you. In fact, if you provide an editorOptions.menubar value
  // it will be overwritten.
  menu: menuPropType,
  // additional plugins that get merged into the default list of plugins
  // it is up to you to import the plugin's definition which will
  // register it and any related toolbar or menu entries with tinymce.
  plugins: PropTypes.arrayOf(PropTypes.string),
  // is this RCE readonly?
  readonly: PropTypes.bool,

  selector: PropTypes.string,
  init_instance_callback: PropTypes.func,
})

export type EditorOptionsPropType = InferType<typeof editorOptionsPropType>

export const externalToolsConfigPropType = PropTypes.shape({
  // List of iframe allow statements to used with LTI iframes.
  ltiIframeAllowances: PropTypes.arrayOf(PropTypes.string),

  // Tool id of the LTI tool using the RCE. Used to allow the RCE to launch additional LTI tools from Canvas.
  containingCanvasLtiToolId: PropTypes.string,

  // Override URL for LTI resource selection
  resourceSelectionUrlOverride: PropTypes.string,

  isA2StudentView: PropTypes.bool,
  maxMruTools: PropTypes.number,
})

export type ExternalToolsConfigPropType = InferType<typeof externalToolsConfigPropType>

export const rceWrapperPropTypes = {
  autosave: PropTypes.shape({
    enabled: PropTypes.bool,
    maxAge: PropTypes.number,
  }),
  canvasOrigin: PropTypes.string,
  defaultContent: PropTypes.string,
  editorOptions: editorOptionsPropType,
  handleUnmount: PropTypes.func,
  editorView: PropTypes.oneOf([WYSIWYG_VIEW, PRETTY_HTML_EDITOR_VIEW, RAW_HTML_EDITOR_VIEW]),
  renderKBShortcutModal: PropTypes.bool,
  id: PropTypes.string,
  language: PropTypes.string,
  liveRegion: PropTypes.func.isRequired,
  ltiTools: ltiToolsPropType,
  onContentChange: PropTypes.func,
  onFocus: PropTypes.func,
  onBlur: PropTypes.func,
  onInitted: PropTypes.func,
  onRemove: PropTypes.func,
  textareaClassName: PropTypes.string,
  textareaId: PropTypes.string.isRequired,
  readOnly: PropTypes.bool,
  tinymce: PropTypes.object,
  trayProps: trayPropTypes,
  toolbar: toolbarPropType,
  menu: menuPropType,
  instRecordDisabled: PropTypes.bool,
  highContrastCSS: PropTypes.arrayOf(PropTypes.string),
  maxInitRenderedRCEs: PropTypes.number,
  use_rce_icon_maker: PropTypes.bool,
  features: PropTypes.objectOf(PropTypes.bool),
  flashAlertTimeout: PropTypes.number,
  timezone: PropTypes.string,
  externalToolsConfig: externalToolsConfigPropType,
}

export type RCEWrapperProps = PropTypes.InferProps<typeof rceWrapperPropTypes>
