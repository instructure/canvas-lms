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
  IconArrowOpenDownLine,
  IconAttachMediaLine,
  IconBoldLine,
  IconBulletListAlphaLine,
  IconBulletListCircleOutlineLine,
  IconBulletListLine,
  IconBulletListRomanLine,
  IconBulletListSquareLine,
  IconClearTextFormattingLine,
  IconDocumentLine,
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
  IconTextDirectionLtrLine,
  IconTextDirectionRtlLine,
  IconUnderlineLine
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
    underline: IconUnderlineLine,
    link: IconLinkLine,
    video: IconAttachMediaLine,
    document: IconDocumentLine,

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

    // The `tox-icon-*` path ids on these 2 are important. It is what tinyMCE
    // looks for to update the color when you select a new one
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
    'highlight-bg-color': {
      src: `<svg viewBox="0 0 1920 1920" version="1.1">
        <g stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
          <path id="tox-icon-highlight-bg-color__color" fill="#2B3B46" d="M74 1918.14125 1841 1918.14125 1841 1469.14125 74 1469.14125z"/>
          <path d="M1543.03014,312.225305 L1056.25966,861 L795,619.351719 L1335.45236,123.521776 C1343.65702,115.67377 1355.72958,114.736695 1363.23098,121.647625 L1541.15479,286.221467 C1548.53898,293.015262 1548.65619,305.19724 1543.03014,312.225305 L1543.03014,312.225305 Z M898.711011,994.448142 C836.706813,972.459128 767.201162,989.769628 721.489183,1038.89402 L701.094608,1061 L616,982.517932 L636.628996,960.294992 C681.989345,911.287561 694.179206,840.758966 667.220859,780.757027 C659.250565,762.627787 664.056183,740.638772 678.355828,726.95412 L708.830481,699 L979,948.481745 L952.393284,978.190307 C939.148531,994.565105 917.699064,1000.76414 898.711011,994.448142 L898.711011,994.448142 Z M598.157143,1171.267 L416,1171.618 L532.908571,1065.382 L621,1146.931 L598.157143,1171.267 Z M1620.96383,200.201811 L1443.1176,35.7209178 C1390.27923,-13.0965429 1307.56551,-11.4575874 1255.6644,38.0622828 L598.40662,641.080844 C547.442781,689.781237 532.212208,764.939054 560.330188,828.15591 C567.945475,845.013738 564.079252,866.203091 550.606054,880.602486 L492.261245,943.819342 L304.690887,1114.38778 C276.104274,1140.494 265.208557,1179.82894 276.221432,1216.8225 C287.234308,1253.93314 317.929769,1280.85884 365.37886,1287.6488 L649.136142,1288 L707.246634,1226.18796 L707.480951,1226.4221 L743.448533,1187.55544 L747.080439,1183.69219 L807.534096,1118.25104 C821.35877,1103.50044 842.09578,1098.23236 859.200884,1104.43698 C924.45803,1127.73356 998.267727,1106.77835 1041.49912,1053.98057 L1632.44533,387.979285 C1678.60569,331.43532 1673.56788,248.902203 1620.96383,200.201811 L1620.96383,200.201811 Z" id="Fill-1" fill="#2B3B46"/>
        </g>
      </svg>`
    },

    unlink: IconRemoveLinkLine,
    'unordered-list': IconBulletListLine,
    ltr: IconTextDirectionLtrLine,
    rtl: IconTextDirectionRtlLine,
    'chevron-down': IconArrowOpenDownLine
  }
  Object.keys(icons).forEach(key => {
    editor.ui.registry.addIcon(key, icons[key].src)
  })
})
