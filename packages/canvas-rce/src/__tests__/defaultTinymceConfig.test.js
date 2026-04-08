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
import elementDenylist from '../elementDenylist'

describe('defaultTinymceConfig', () => {
  describe('allowed elements', () => {
    it('is the combination of valid and extended valid elements', () => {
      const {valid_elements, extended_valid_elements} = defaultTinymceConfig
      const allAllowedElements = [valid_elements, extended_valid_elements].join(',')

      expect(allAllowedElements).toMatchInlineSnapshot(
        `"@[id|class|style|title|dir<ltr?rtl|lang|xml::lang|role],a[rel|rev|charset|hreflang|tabindex|accesskey|type|name|href|target|title|class|data-old-link],strong/b,em/i,strike/s,u,#p,-ol[type|compact],-ul[type|compact],-li,br,img[longdesc|usemap|src|border|alt|title|hspace|vspace|width|height|align|role|data-old-link],-sub,-sup,-blockquote[cite],-table[border=0|cellspacing|cellpadding|width|frame|rules|height|align|summary|bgcolor|background|bordercolor],-tr[rowspan|width|height|align|valign|bgcolor|background|bordercolor],tbody,thead,tfoot,#td[colspan|rowspan|width|height|align|valign|bgcolor|background|bordercolor|scope],#th[colspan|rowspan|width|height|align|valign|scope],caption,-div,-span,-code,-pre,address,-h1,-h2,-h3,-h4,-h5,-h6,hr[size|noshade],-font[face|size|color],dd,dl,dt,cite,abbr,acronym,del[datetime|cite],ins[datetime|cite],object[classid|width|height|codebase|*],param[name|value|_value],embed[type|width|height|src|*],map[name],area[shape|coords|href|alt|target],bdo,col[align|char|charoff|span|valign|width],colgroup[align|char|charoff|span|valign|width],dfn,kbd,q[cite],samp,small,tt,var,big,figure,figcaption,source[media|width|height|sizes|src|srcset|type|data-old-link],track,mark,article,aside,details,footer,header,nav,section,summary,time,@[id|accesskey|class|dir|lang|style|tabindex|title|contenteditable|contextmenu|draggable|dropzone|hidden|longdesc|spellcheck|translate|align|role|aria-labelledby|aria-atomic|aria-busy|aria-controls|aria-describedby|aria-description|aria-disabled|aria-dropeffect|aria-flowto|aria-grabbed|aria-haspopup|aria-hidden|aria-invalid|aria-label|aria-labelledby|aria-live|aria-owns|aria-relevant|aria-autocomplete|aria-checked|aria-disabled|aria-expanded|aria-haspopup|aria-hidden|aria-invalid|aria-label|aria-level|aria-multiline|aria-multiselectable|aria-orientation|aria-pressed|aria-readonly|aria-required|aria-selected|aria-sort|aria-valuemax|aria-valuemin|aria-valuenow|aria-valuetext],iframe[id|data-media-type|title|src|width|height|name|align|style|class|sandbox|loading|allowfullscreen|webkitallowfullscreen|mozallowfullscreen|allow|data-old-link],i[iclass],a[hidden|href|target|rel|media|hreflang|type|charset|name|rev|shape|coords|download|alt],#p,li[value],-ol[reversed|start|type|compact],pre[width],table[border|summary|width|frame|rules|cellspacing|cellpadding|bgcolor],tbody[char|charoff|valign],td[colspan|rowspan|headers|abbr|axis|scope|align|char|charoff|valign|nowrap|bgcolor|width|height],tfoot[char|charoff|valign],th[colspan|rowspan|headers|scope|abbr|axis|align|char|charoff|valign|nowrap|bgcolor|width|height],thead[char|charoff|valign],tr[char|charoff|valign|bgcolor],-ul[compact],video[name|src|allowfullscreen|muted|poster|width|height|controls|playsinline],audio[name|src|muted|controls],annotation[href|xref|intent|arg|definitionURL|encoding|cd|name|src],annotation-xml[href|xref|intent|arg|definitionURL|encoding|cd|name|src],maction[href|xref|mathcolor|mathbackground|intent|arg|actiontype|selection],maligngroup[href|xref|mathcolor|mathbackground|intent|arg|groupalign],malignmark[href|xref|mathcolor|mathbackground|intent|arg|edge],math[xmlns|href|xref|display|maxwidth|overflow|altimg|altimg-width|altimg-height|altimg-valign|alttext|cdgroup|intent|arg|mathcolor|mathbackground|scriptlevel|displaystyle|scriptsizemultiplier|scriptminsize|infixlinebreakstyle|decimalpoint|mathvariant|mathsize|width|height|valign|form|fence|separator|lspace|rspace|stretchy|symmetric|maxsize|minsize|largeop|movablelimits|accent|linebreak|lineleading|linebreakstyle|linebreakmultchar|indentalign|indentshift|indenttarget|indentalignfirst|indentshiftfirst|indentalignlast|indentshiftlast|depth|lquote|rquote|linethickness|numalign|denomalign|bevelled|voffset|open|close|separators|notation|subscriptshift|superscriptshift|accentunder|align|rowalign|columnalign|groupalign|alignmentscope|columnwidth|rowspacing|columnspacing|rowlines|columnlines|frame|framespacing|equalrows|equalcolumns|side|minlabelspacing|rowspan|columnspan|edge|stackalign|charalign|charspacing|longdivstyle|position|shift|location|crossout|length|leftoverhang|rightoverhang|mslinethickness|selection],menclose[href|xref|mathcolor|mathbackground|intent|arg|notation],merror[href|xref|mathcolor|mathbackground|intent|arg],mfenced[href|xref|mathcolor|mathbackground|intent|arg|open|close|separators],mfrac[href|xref|mathcolor|mathbackground|intent|arg|linethickness|numalign|denomalign|bevelled],mglyph[href|xref|mathcolor|mathbackground|intent|arg|src|alt|width|height|valign],mi[href|xref|mathcolor|mathbackground|intent|arg|mathvariant|mathsize],mlabeledtr[href|xref|mathcolor|mathbackground|intent|arg],mlongdiv[href|xref|mathcolor|mathbackground|intent|arg|longdivstyle|align|stackalign|charalign|charspacing],mmultiscripts[href|xref|mathcolor|mathbackground|intent|arg|subscriptshift|superscriptshift],mn[href|xref|mathcolor|mathbackground|intent|arg|mathvariant|mathsize],mo[href|xref|mathcolor|mathbackground|intent|arg|mathvariant|mathsize|form|fence|separator|lspace|rspace|stretchy|symmetric|maxsize|minsize|largeop|movablelimits|accent|linebreak|lineleading|linebreakstyle|linebreakmultchar|indentalign|indentshift|indenttarget|indentalignfirst|indentshiftfirst|indentalignlast|indentshiftlast],mover[href|xref|mathcolor|mathbackground|intent|arg|accent|align],mpadded[href|xref|mathcolor|mathbackground|intent|arg|height|depth|width|lspace|voffset],mphantom[href|xref|mathcolor|mathbackground|intent|arg],mprescripts[href|xref|mathcolor|mathbackground|intent|arg],mroot[href|xref|mathcolor|mathbackground|intent|arg],mrow[href|xref|mathcolor|mathbackground|intent|arg],ms[href|xref|mathcolor|mathbackground|intent|arg|mathvariant|mathsize|lquote|rquote],mscarries[href|xref|mathcolor|mathbackground|intent|arg|position|location|crossout|scriptsizemultiplier],mscarry[href|xref|mathcolor|mathbackground|intent|arg|location|crossout],msgroup[href|xref|mathcolor|mathbackground|intent|arg|position|shift],msline[href|xref|mathcolor|mathbackground|intent|arg|position|length|leftoverhang|rightoverhang|mslinethickness],mspace[href|xref|mathcolor|mathbackground|intent|arg|mathvariant|mathsize],msqrt[href|xref|mathcolor|mathbackground|intent|arg],msrow[href|xref|mathcolor|mathbackground|intent|arg|position],mstack[href|xref|mathcolor|mathbackground|intent|arg|align|stackalign|charalign|charspacing],mstyle[href|xref|mathcolor|mathbackground|intent|arg|scriptlevel|displaystyle|scriptsizemultiplier|scriptminsize|infixlinebreakstyle|decimalpoint|mathvariant|mathsize|width|height|valign|form|fence|separator|lspace|rspace|stretchy|symmetric|maxsize|minsize|largeop|movablelimits|accent|linebreak|lineleading|linebreakstyle|linebreakmultchar|indentalign|indentshift|indenttarget|indentalignfirst|indentshiftfirst|indentalignlast|indentshiftlast|depth|lquote|rquote|linethickness|numalign|denomalign|bevelled|voffset|open|close|separators|notation|subscriptshift|superscriptshift|accentunder|align|rowalign|columnalign|groupalign|alignmentscope|columnwidth|rowspacing|columnspacing|rowlines|columnlines|frame|framespacing|equalrows|equalcolumns|side|minlabelspacing|rowspan|columnspan|edge|stackalign|charalign|charspacing|longdivstyle|position|shift|location|crossout|length|leftoverhang|rightoverhang|mslinethickness|selection],msub[href|xref|mathcolor|mathbackground|intent|arg|subscriptshift],msubsup[href|xref|mathcolor|mathbackground|intent|arg|subscriptshift|superscriptshift],msup[href|xref|mathcolor|mathbackground|intent|arg|superscriptshift],mtable[href|xref|mathcolor|mathbackground|intent|arg|align|rowalign|columnalign|groupalign|alignmentscope|columnwidth|width|rowspacing|columnspacing|rowlines|columnlines|frame|framespacing|equalrows|equalcolumns|displaystyle|side|minlabelspacing],mtd[href|xref|mathcolor|mathbackground|intent|arg|rowspan|columnspan|rowalign|columnalign|groupalign],mtext[href|xref|mathcolor|mathbackground|intent|arg|mathvariant|mathsize|width|height|depth|linebreak],mtr[href|xref|mathcolor|mathbackground|intent|arg|rowalign|columnalign|groupalign],munder[href|xref|mathcolor|mathbackground|intent|arg|accentunder|align],munderover[href|xref|mathcolor|mathbackground|intent|arg|accent|accentunder|align],none[href|xref|mathcolor|mathbackground|intent|arg],semantics[href|xref|intent|arg|definitionURL|encoding],picture,ruby,rp,rt,g[*],circle[*]"`,
      )
    })

    describe('MathML Intent attributes for screen reader accessibility', () => {
      let allAllowedElements

      beforeAll(() => {
        const {valid_elements, extended_valid_elements} = defaultTinymceConfig
        allAllowedElements = [valid_elements, extended_valid_elements].join(',')
      })

      const mathmlElements = [
        'annotation',
        'annotation-xml',
        'maction',
        'maligngroup',
        'malignmark',
        'math',
        'menclose',
        'merror',
        'mfenced',
        'mfrac',
        'mglyph',
        'mi',
        'mlabeledtr',
        'mlongdiv',
        'mmultiscripts',
        'mn',
        'mo',
        'mover',
        'mpadded',
        'mphantom',
        'mprescripts',
        'mroot',
        'mrow',
        'ms',
        'mscarries',
        'mscarry',
        'msgroup',
        'msline',
        'mspace',
        'msqrt',
        'msrow',
        'mstack',
        'mstyle',
        'msub',
        'msubsup',
        'msup',
        'mtable',
        'mtd',
        'mtext',
        'mtr',
        'munder',
        'munderover',
        'none',
        'semantics',
      ]

      it.each(mathmlElements)('allows intent attribute on %s', element => {
        const regex = new RegExp(`${element}\\[([^\\]]*\\|)?intent(\\|[^\\]]*)?\\]`)
        expect(allAllowedElements).toMatch(regex)
      })

      it.each(mathmlElements)('allows arg attribute on %s', element => {
        const regex = new RegExp(`${element}\\[([^\\]]*\\|)?arg(\\|[^\\]]*)?\\]`)
        expect(allAllowedElements).toMatch(regex)
      })

      it('allows numalign on mfrac for numerator alignment', () => {
        expect(allAllowedElements).toMatch(/mfrac\[([^\]]*\|)?numalign(\|[^\]]*)?]/)
      })
    })

    it('does not include any elements from the denylist', () => {
      const {valid_elements, extended_valid_elements} = defaultTinymceConfig
      const allAllowedElements = [valid_elements, extended_valid_elements].join(',')

      elementDenylist.forEach(element => {
        const regex = new RegExp(`[^a-z\|\-]${element}[^a-z\|\-]`)
        expect(allAllowedElements).not.toMatch(regex)
      })
    })
  })

  describe('font_formats', () => {
    it('includes Lato Extended and does not include lato', () => {
      const {font_formats} = defaultTinymceConfig

      expect(font_formats).toMatchInlineSnapshot(
        `"Lato Extended=Lato Extended,Helvetica Neue,Helvetica,Arial,sans-serif; Balsamiq Sans=Balsamiq Sans,Lato Extended,Helvetica Neue,Helvetica,Arial,sans-serif; Architect's Daughter=Architects Daughter,Lato Extended,Helvetica Neue,Helvetica,Arial,sans-serif; Arial=arial,helvetica,sans-serif; Arial Black=arial black,avant garde; Courier New=courier new,courier; Georgia=georgia,palatino; Tahoma=tahoma,arial,helvetica,sans-serif; Times New Roman=times new roman,times; Trebuchet MS=trebuchet ms,geneva; Verdana=verdana,geneva; Open Dyslexic=OpenDyslexic; Open Dyslexic Mono=OpenDyslexicMono, Monaco, Menlo, Consolas, Courier New, monospace;"`,
      )
      expect(font_formats).not.toMatch(/lato/)
    })
  })

  describe('color_map', () => {
    it('includes the expected hex colors and descriptions', () => {
      const {color_map} = defaultTinymceConfig

      expect(color_map).toContain('#BFEDD2') // tinymce default
      expect(color_map).toContain('#FBEEB8') // tinymce default
      expect(color_map).toContain('#F8CAC6') // tinymce default
      expect(color_map).toContain('#ECCAFA') // tinymce default
      expect(color_map).toContain('#C2E0F4') // tinymce default
      expect(color_map).toContain('#03893D') // InstUI Green45
      expect(color_map).toContain('#CF4A00') // InstUI Orange45
      expect(color_map).toContain('#E62429') // InstUI Red45
      expect(color_map).toContain('#9E58BD') // InstUI Violet45
      expect(color_map).toContain('#2B7ABC') // InstUI Blue45
      expect(color_map).toContain('#027634') // InstUI Green57
      expect(color_map).toContain('#B34000') // InstUI Orange57
      expect(color_map).toContain('#C71F23') // InstUI Red57
      expect(color_map).toContain('#9242B4') // InstUI Violet57
      expect(color_map).toContain('#0E68B3') // InstUI Blue57
      expect(color_map).toContain('#FFFFFF') // White
      expect(color_map).toContain('#6A7883') // InstUI Grey45
      expect(color_map).toContain('#3F515E') // InstUI Grey82
      expect(color_map).toContain('#273540') // InstUI Grey125
      expect(color_map).toContain('#000000') // Black

      // Verify all descriptions are present
      expect(color_map).toContain('Light Green')
      expect(color_map).toContain('Light Orange')
      expect(color_map).toContain('Light Red')
      expect(color_map).toContain('Light Purple')
      expect(color_map).toContain('Light Blue')
      expect(color_map).toContain('Green')
      expect(color_map).toContain('Orange')
      expect(color_map).toContain('Red')
      expect(color_map).toContain('Purple')
      expect(color_map).toContain('Blue')
      expect(color_map).toContain('Dark Green')
      expect(color_map).toContain('Dark Orange')
      expect(color_map).toContain('Dark Red')
      expect(color_map).toContain('Dark Purple')
      expect(color_map).toContain('Dark Blue')
      expect(color_map).toContain('White')
      expect(color_map).toContain('Light Gray')
      expect(color_map).toContain('Gray')
      expect(color_map).toContain('Dark Gray')
      expect(color_map).toContain('Black')
    })
  })
})
