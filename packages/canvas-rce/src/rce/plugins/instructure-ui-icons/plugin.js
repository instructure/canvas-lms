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
  IconBulletListAlphaLine,
  IconBulletListCircleOutlineLine,
  IconBulletListLine,
  IconBulletListRomanLine,
  IconBulletListSquareLine,
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
    'list-bull-circle': IconBulletListCircleOutlineLine,
    'list-bull-square': IconBulletListSquareLine,
    'list-num-upper-alpha': IconBulletListAlphaLine,
    'list-num-upper-roman': IconBulletListRomanLine,

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

    // The `tox-icon-text-color__color` path id here is important. It is what tinyMCE looks for to
    // update the color when you select a new one
    'text-color': {
      src: `<svg viewBox="7 7 1773 1920">
      <g fill="none" fill-rule="evenodd">
        <g fill="#2B3B46" fill-rule="nonzero">
          <path id="tox-icon-text-color__color" d="M0 1920v-443.07692h1772.30769V1920z"/>
          <path d="M736.526769.05907692h299.224611L1545.14215 1227.08677l-136.46769 56.56615-164.97231-397.587689H528.576L363.603692 1283.65292 227.136 1227.08677 736.526769.05907692zM835.332923 147.751385L589.868308 738.372923h592.541542L937.09292 147.751385H835.332923z" id="A"/>
        </g>
      </g>
    </svg>`
    },

    unlink: IconRemoveLinkLine,
    'unordered-list': IconBulletListLine
  }
  Object.keys(icons).forEach(key => {
    editor.ui.registry.addIcon(key, icons[key].src)
  })
})
