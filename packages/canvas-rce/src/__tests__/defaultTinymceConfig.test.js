/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import defaultTinymceConfig from '../defaultTinymceConfig'

describe('defaultTinymceConfig', () => {
  describe('when allowed html tags and attributes have been established with valid_elements and extended_valid_elements', () => {
    it('matches the expected list', () => {
      // if valid_elements or extended_valid_elements are updated, the inline snapshot below needs to be udpated also
      const validElements = defaultTinymceConfig.valid_elements
      const extendedElements = defaultTinymceConfig.extended_elements
      const allAllowed = `${validElements},${extendedElements}`
      expect(allAllowed).toMatchInlineSnapshot(
        `"@[id|class|style|title|dir<ltr?rtl|lang|xml::lang|role],a[rel|rev|charset|hreflang|tabindex|accesskey|type|name|href|target|title|class],strong/b,em/i,strike/s,u,#p,-ol[type|compact],-ul[type|compact],-li,br,img[longdesc|usemap|src|border|alt|title|hspace|vspace|width|height|align|role],-sub,-sup,-blockquote[cite],-table[border=0|cellspacing|cellpadding|width|frame|rules|height|align|summary|bgcolor|background|bordercolor],-tr[rowspan|width|height|align|valign|bgcolor|background|bordercolor],tbody,thead,tfoot,#td[colspan|rowspan|width|height|align|valign|bgcolor|background|bordercolor|scope],#th[colspan|rowspan|width|height|align|valign|scope],caption,-div,-span,-code,-pre,address,-h1,-h2,-h3,-h4,-h5,-h6,hr[size|noshade],-font[face|size|color],dd,dl,dt,cite,abbr,acronym,del[datetime|cite],ins[datetime|cite],object[classid|width|height|codebase|*],param[name|value|_value],embed[type|width|height|src|*],map[name],area[shape|coords|href|alt|target],bdo,col[align|char|charoff|span|valign|width],colgroup[align|char|charoff|span|valign|width],dfn,kbd,q[cite],samp,small,tt,var,big,figure,figcaption,source[media|sizes|src|srcset|type],track,mark,article,aside,details,footer,header,nav,section,summary,time,undefined"`
      )
    })
  })

  describe('when tags and attributes that are not allowed in tinymce have been established', () => {
    it('does not match on any in not allowed array', () => {
      // after creating the inline snapshot above, it was copied here to make sure not-allowed tags/attributes are not present
      // whenever that snapshot gets updated, validElements here needs to be udpated also
      const validElements = `"@[id|class|style|title|dir<ltr?rtl|lang|xml::lang|role],a[rel|rev|charset|hreflang|tabindex|accesskey|type|name|href|target|title|class],strong/b,em/i,strike/s,u,#p,-ol[type|compact],-ul[type|compact],-li,br,img[longdesc|usemap|src|border|alt|title|hspace|vspace|width|height|align|role],-sub,-sup,-blockquote[cite],-table[border=0|cellspacing|cellpadding|width|frame|rules|height|align|summary|bgcolor|background|bordercolor],-tr[rowspan|width|height|align|valign|bgcolor|background|bordercolor],tbody,thead,tfoot,#td[colspan|rowspan|width|height|align|valign|bgcolor|background|bordercolor|scope],#th[colspan|rowspan|width|height|align|valign|scope],caption,-div,-span,-code,-pre,address,-h1,-h2,-h3,-h4,-h5,-h6,hr[size|noshade],-font[face|size|color],dd,dl,dt,cite,abbr,acronym,del[datetime|cite],ins[datetime|cite],object[classid|width|height|codebase|*],param[name|value|_value],embed[type|width|height|src|*],map[name],area[shape|coords|href|alt|target],bdo,col[align|char|charoff|span|valign|width],colgroup[align|char|charoff|span|valign|width],dfn,kbd,q[cite],samp,small,tt,var,big,figure,figcaption,source[media|sizes|src|srcset|type],track,mark,article,aside,details,footer,header,nav,section,summary,time,wbr,undefined"`
      const notAllowedList = getNotAllowedList()
      notAllowedList.forEach(element => {
        const regex = new RegExp(`[^a-z\|]${element}[^a-z\|]`)
        expect(validElements).not.toMatch(regex)
      })
    })
  })
})

function getNotAllowedList() {
  const notAllowedList =
    'html,base,head,link,meta,style,title,body,main,data,rb,rtc,portal,svg,canvas,noscript,script,button,datalist,fieldset,form,input,label,legend,meter,optgroup' +
    ',option,output,progress,select,textarea,dialog,menu,slot,template,applet,basefont,bgsound,blink,center,content,dir,frame,frameset,hgroup,image,keygen,marquee,menuitem,nobr,noembed' +
    ',noframes,plaintext,rb,rtc,shadow,spacer,xmp'
  return notAllowedList.split(',')
}
