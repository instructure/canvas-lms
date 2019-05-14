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

import {
  IconAttachMediaLine,
  IconBoldLine,
  IconBulletListLine,
  IconClearTextFormattingLine,
  IconImageLine,
  IconIndentLine,
  IconItalicLine,
  IconLinkLine,
  IconLtiLine,
  IconNumberedListLine,
  IconOutdentLine,
  IconRemoveLinkLine,
  IconStrikethroughLine,
  IconTextCenteredLine,
  IconTextEndLine,
  IconTextStartLine,
  IconTextSubscriptLine,
  IconTextSuperscriptLine,
} from '@instructure/ui-icons/es/svg'

tinymce.PluginManager.add('instructure-ui-icons', function(editor) {
  // the keys here are what tinymce calls it. the values are the svgs from instUI

  // there are few things here that are commented out that are things that we
  // might want to have our own icon for but one doesn't exist in @instructure/ui-icons
  const icons = {
    'align-center': IconTextCenteredLine,
    'align-left': IconTextStartLine,
    'align-right': IconTextEndLine,
    'list-bull-default': IconBulletListLine,
    'list-num-default': IconNumberedListLine,
    bold: IconBoldLine,
    image: IconImageLine,
    indent: IconIndentLine,
    italic: IconItalicLine,
    link: IconLinkLine,
    video: IconAttachMediaLine,

    // if @instructure/ui-icons ever gets icons for these, lets use those. But until
    // then these are the same as the stock tinyMCE ones but with the viewbox
    // adjusted so they look right next to our icons
    'list-bull-circle': {
      src: `<svg viewBox="7 7 32 32"><g fill-rule="evenodd"><path d="M11 16a2 2 0 1 0 0-4 2 2 0 0 0 0 4zm0 1a3 3 0 1 1 0-6 3 3 0 0 1 0 6zM11 26a2 2 0 1 0 0-4 2 2 0 0 0 0 4zm0 1a3 3 0 1 1 0-6 3 3 0 0 1 0 6zM11 36a2 2 0 1 0 0-4 2 2 0 0 0 0 4zm0 1a3 3 0 1 1 0-6 3 3 0 0 1 0 6z" fill-rule="nonzero"></path><path opacity=".2" d="M18 12h22v4H18zM18 22h22v4H18zM18 32h22v4H18z"></path></g></svg>`
    },
    'list-bull-square': {
      src: `<svg viewBox="7 7 32 32"><g fill-rule="evenodd"><path d="M8 11h6v6H8zM8 21h6v6H8zM8 31h6v6H8z"></path><path opacity=".2" d="M18 12h22v4H18zM18 22h22v4H18zM18 32h22v4H18z"></path></g></svg>`
    },
    'list-num-upper-alpha': {
      src: `<svg viewBox="7 7 32 32"><g fill-rule="evenodd"><path opacity=".2" d="M18 12h22v4H18zM18 22h22v4H18zM18 32h22v4H18z"></path><path d="M12.6 17l-.5-1.4h-2L9.5 17H8.3l2-6H12l2 6h-1.3zM11 12.3l-.7 2.3h1.6l-.8-2.3zm4.7 4.8c-.4 0-.7-.3-.7-.7 0-.4.3-.7.7-.7.5 0 .7.3.7.7 0 .4-.2.7-.7.7zM11.4 27H8.7v-6h2.6c1.2 0 1.9.6 1.9 1.5 0 .6-.5 1.2-1 1.3.7.1 1.3.7 1.3 1.5 0 1-.8 1.7-2 1.7zM10 22v1.5h1c.6 0 1-.3 1-.8 0-.4-.4-.7-1-.7h-1zm0 4H11c.7 0 1.1-.3 1.1-.8 0-.6-.4-.9-1.1-.9H10V26zm5.4 1.1c-.5 0-.8-.3-.8-.7 0-.4.3-.7.8-.7.4 0 .7.3.7.7 0 .4-.3.7-.7.7zm-4.1 10c-1.8 0-2.8-1.1-2.8-3.1s1-3.1 2.8-3.1c1.4 0 2.5.9 2.6 2.2h-1.3c0-.7-.6-1.1-1.3-1.1-1 0-1.6.7-1.6 2s.6 2 1.6 2c.7 0 1.2-.4 1.4-1h1.2c-.1 1.3-1.2 2.2-2.6 2.2zm4.5 0c-.5 0-.8-.3-.8-.7 0-.4.3-.7.8-.7.4 0 .7.3.7.7 0 .4-.3.7-.7.7z"></path></g></svg>`
    },
    'list-num-upper-roman': {
      src: `<svg viewBox="7 7 32 32"><g fill-rule="evenodd"><path opacity=".2" d="M18 12h22v4H18zM18 22h22v4H18zM18 32h22v4H18z"></path><path d="M15.1 17v-1.2h1.3V17H15zm0 10v-1.2h1.3V27H15zm0 10v-1.2h1.3V37H15z"></path><path fill-rule="nonzero" d="M12 20h1.5v7H12zM12 30h1.5v7H12zM9 20h1.5v7H9zM9 30h1.5v7H9zM6 30h1.5v7H6zM12 10h1.5v7H12z"></path></g></svg>`
    },

    'ordered-list': IconNumberedListLine,
    lti: IconLtiLine,
    outdent: IconOutdentLine,
    'remove-formatting': IconClearTextFormattingLine,
    'strike-through': IconStrikethroughLine,
    subscript: IconTextSubscriptLine,
    superscript: IconTextSuperscriptLine,

    // not using instUI's table icon for now because there are a lot of other table related icons
    // that tinyMCE uses that we'd want to match our table icon. So unless we get instUI versions of all
    // those too, it probably makes sense to just use TinyMCE's for everything table related.
    // table: IconTableLine,

    //if we use the instUI one here we won't get the functionality where it
    // updates the icon fill with the color they select
    // 'text-color': IconTextColorLine,

    unlink: IconRemoveLinkLine,
    'unordered-list': IconBulletListLine
  }
  Object.keys(icons).forEach(key => {
    editor.ui.registry.addIcon(key, icons[key].src)
  })

  // TODO: find a better place to put this
  editor.$(`<style>
    /* this is because instUI icons don't have a "height" attribute like tinymce ones do, so this will make them consistent */
    .tox .tox-icon svg:not([height]) { height: 16px }

    /* this is for instUI icons that that dropdown from a SplitButton like in our advlist plugin */
    .tox .tox-collection__item-icon svg:not([height]) {
      height: 16px;
    }
    .tox .tox-collection--toolbar-lg .tox-collection__item-icon {
      height: 30px;
      width: 30px;
    }
  </style>`).appendTo(editor.targetElm.ownerDocument.body)
})
