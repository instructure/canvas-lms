// @ts-nocheck
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
  IconExitFullScreenLine,
  IconFullScreenLine,
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
  IconTextDirectionLtrLine,
  IconTextDirectionRtlLine,
  IconTextEndLine,
  IconTextStartLine,
  IconTextSubscriptLine,
  IconTextSuperscriptLine,
  IconUnderlineLine,
} from '@instructure/ui-icons/es/svg'
import tinymce from 'tinymce'

tinymce.PluginManager.add('instructure-ui-icons', function (editor) {
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
    </svg>`,
    },
    'highlight-bg-color': {
      src: `<svg viewBox="0 0 1920 1920" version="1.1">
        <g stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
          <path id="tox-icon-highlight-bg-color__color" fill="#2B3B46" d="M74 1918.14125 1841 1918.14125 1841 1469.14125 74 1469.14125z"/>
          <path d="M1543.03014,312.225305 L1056.25966,861 L795,619.351719 L1335.45236,123.521776 C1343.65702,115.67377 1355.72958,114.736695 1363.23098,121.647625 L1541.15479,286.221467 C1548.53898,293.015262 1548.65619,305.19724 1543.03014,312.225305 L1543.03014,312.225305 Z M898.711011,994.448142 C836.706813,972.459128 767.201162,989.769628 721.489183,1038.89402 L701.094608,1061 L616,982.517932 L636.628996,960.294992 C681.989345,911.287561 694.179206,840.758966 667.220859,780.757027 C659.250565,762.627787 664.056183,740.638772 678.355828,726.95412 L708.830481,699 L979,948.481745 L952.393284,978.190307 C939.148531,994.565105 917.699064,1000.76414 898.711011,994.448142 L898.711011,994.448142 Z M598.157143,1171.267 L416,1171.618 L532.908571,1065.382 L621,1146.931 L598.157143,1171.267 Z M1620.96383,200.201811 L1443.1176,35.7209178 C1390.27923,-13.0965429 1307.56551,-11.4575874 1255.6644,38.0622828 L598.40662,641.080844 C547.442781,689.781237 532.212208,764.939054 560.330188,828.15591 C567.945475,845.013738 564.079252,866.203091 550.606054,880.602486 L492.261245,943.819342 L304.690887,1114.38778 C276.104274,1140.494 265.208557,1179.82894 276.221432,1216.8225 C287.234308,1253.93314 317.929769,1280.85884 365.37886,1287.6488 L649.136142,1288 L707.246634,1226.18796 L707.480951,1226.4221 L743.448533,1187.55544 L747.080439,1183.69219 L807.534096,1118.25104 C821.35877,1103.50044 842.09578,1098.23236 859.200884,1104.43698 C924.45803,1127.73356 998.267727,1106.77835 1041.49912,1053.98057 L1632.44533,387.979285 C1678.60569,331.43532 1673.56788,248.902203 1620.96383,200.201811 L1620.96383,200.201811 Z" id="Fill-1" fill="#2B3B46"/>
        </g>
      </svg>`,
    },

    unlink: IconRemoveLinkLine,
    'unordered-list': IconBulletListLine,
    ltr: IconTextDirectionLtrLine,
    rtl: IconTextDirectionRtlLine,
    'chevron-down': IconArrowOpenDownLine,
    fullscreen: IconFullScreenLine,
    fullscreen_exit: IconExitFullScreenLine,
    // svg copied from StatusBar.js
    htmlview: {
      src: `<svg viewBox="0 0 24 24" font-size="16px" width="24" height="24" ">
        <g role="presentation">
          <text textAnchor="start" x="0" y="18px">
            &lt;/&gt;
          </text>
        </g>
      </svg>`,
    },

    embed: {
      src: `<svg width="18" height="18" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path fill-rule="evenodd" clip-rule="evenodd" d="M13.7647 5.21417C13.6694 5.21417 13.5773 5.23988 13.482 5.24631C12.8329 3.36281 11.0795 2 9 2C6.53506 2 4.52435 3.91029 4.28294 6.34234C4.09341 6.31127 3.90176 6.28556 3.70588 6.28556C1.66235 6.28556 0 7.96764 0 10.0354C0 12.1032 1.66235 13.7853 3.70588 13.7853L5 13.7853V12.7139L3.70588 12.7139C2.24682 12.7139 1.05882 11.5129 1.05882 10.0354C1.05882 8.55798 2.24682 7.35695 3.70588 7.35695C4.40259 7.35695 5.06012 7.62908 5.55882 8.12192L6.29894 7.35588C6.00565 7.0666 5.66788 6.84483 5.30894 6.66912C5.38941 4.67419 7.00835 3.07139 9 3.07139C11.0435 3.07139 12.7059 4.75347 12.7059 6.82126C12.7059 7.1491 12.6635 7.47266 12.582 7.78658L13.6059 8.06085C13.7107 7.65801 13.7647 7.24124 13.7647 6.82126C13.7647 6.64019 13.7308 6.4677 13.7118 6.29199C13.7298 6.29199 13.7467 6.28556 13.7647 6.28556C15.516 6.28556 16.9412 7.72765 16.9412 9.49973C16.9412 11.2718 15.516 12.7139 13.7647 12.7139L13 12.7139V13.7853L13.7647 13.7853C16.1005 13.7853 18 11.8632 18 9.49973C18 7.13624 16.1005 5.21417 13.7647 5.21417Z" fill="#2B3B46"/>
        <path fill-rule="evenodd" clip-rule="evenodd" d="M7.72039 10.6479L8.3603 11.1813L6.75882 13.1025L8.36029 15.0239L7.72038 15.5573L5.6748 13.1024L7.72039 10.6479ZM10.2802 10.6479L12.3258 13.1024L10.2802 15.5573L9.64031 15.0239L11.2418 13.1025L9.6403 11.1813L10.2802 10.6479Z" fill="#2D3B45"/>
      </svg>`,
    },

    buttons: {
      src: `
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 18 18">
          <g fill="#2D3B45" clip-path="url(#clip0)">
            <path fill-rule="evenodd" d="M.999993 11l.000001 6H6.99999v-6H.999993zm-.99999933 7H7.99999v-8H-.00000668l3.5e-7 8zM4 7c1.65685 0 3-1.34315 3-3S5.65685 1 4 1 1 2.34315 1 4s1.34315 3 3 3zm0 1c2.20914 0 4-1.79086 4-4S6.20914 0 4 0-3e-7 1.79086-3e-7 4 1.79086 8 4 8z" clip-rule="evenodd"/>
            <path d="M12.5 10h1v8h-1v-8z"/>
            <path d="M17 13.5v1H9v-1h8z"/>
            <path fill-rule="evenodd" d="M13 0L8.66987 7.5h8.66023L13 0zm0 2l-2.5981 4.5h5.1962L13 2z" clip-rule="evenodd"/>
          </g>
          <defs>
            <clipPath id="clip0">
              <path fill="white" d="M0 0h18v18H0z"/>
            </clipPath>
          </defs>
        </svg>
      `,
    },
  }
  Object.keys(icons).forEach(key => {
    editor.ui.registry.addIcon(key, icons[key].src)
  })
})
