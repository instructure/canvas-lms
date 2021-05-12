/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React, {createRef, useState} from 'react'
import {arrayOf, number, string} from 'prop-types'
import formatMessage from '../format-message'
import RCEWrapper from './RCEWrapper'
import {trayPropTypes} from './plugins/shared/CanvasContentTray'
import editorLanguage from './editorLanguage'
import normalizeLocale from './normalizeLocale'
import tinyRCE from './tinyRCE'
import getTranslations from '../getTranslations'
import '@instructure/canvas-theme'

if (!process?.env?.BUILD_LOCALE) {
  formatMessage.setup({
    locale: 'en',
    generateId: require('format-message-generate-id/underscored_crc32'),
    missingTranslation: 'ignore'
  })
}

const baseProps = {
  autosave: {enabled: false},
  defaultContent: '',
  // handleUnmount: () => {},
  instRecordDisabled: true,
  language: 'en',
  // languages: [],
  liveRegion: () => document.getElementById('flash_screenreader_holder'),
  mirroredAttrs: {name: 'message'}, // ???
  // onBlur: () => {},
  // onFous: () => {},
  textareaClassName: 'input-block-level',
  // textareaId: 'textarea2',
  // trayProps: {
  //   canUploadFiles: false,
  //   containingContext: {contextType: 'course', contextId: '1', userId: '1'},
  //   contextId: '1',
  //   contextType: 'course',
  //   filesTabDisabled: true,
  //   host: 'localhost:3001', // RCS
  //   jwt: 'this is not for real', // RCE
  //   refreshToken: () => {},
  //   themeUrl: undefined // "/dist/brandable_css/default/variables-8391c84da435c9cfceea2b2b3317ff66.json"
  // },
  highContrastCSS: [],
  use_rce_pretty_html_editor: true,
  editorOptions: {
    // block_formats: 'Paragraph=p;Header 2=h2;Header 3=h3;Header 4=h4;Preformatted=pre',
    // body_class: 'default-theme',
    branding: false,
    browser_spellcheck: true,
    content_css: [],
    convert_urls: false,
    directionality: 'ltr',
    extended_valid_elements:
      '@[id|accesskey|class|dir|lang|style|tabindex|title|contenteditable|contextmenu|draggable|dropzone|hidden|longdesc|spellcheck|translate|align|role|aria-labelledby|aria-atomic|aria-busy|aria-controls|aria-describedby|aria-disabled|aria-dropeffect|aria-flowto|aria-grabbed|aria-haspopup|aria-hidden|aria-invalid|aria-label|aria-labelledby|aria-live|aria-owns|aria-relevant|aria-autocomplete|aria-checked|aria-disabled|aria-expanded|aria-haspopup|aria-hidden|aria-invalid|aria-label|aria-level|aria-multiline|aria-multiselectable|aria-orientation|aria-pressed|aria-readonly|aria-required|aria-selected|aria-sort|aria-valuemax|aria-valuemin|aria-valuenow|aria-valuetext],iframe[id|data-media-type|title|src|width|height|name|align|style|class|sandbox|allowfullscreen|webkitallowfullscreen|mozallowfullscreen|allow],i[iclass],a[hidden|href|target|rel|media|hreflang|type|charset|name|rev|shape|coords|download|alt],#p,li[value],-ol[reversed|start|type|compact],pre[width],table[border|summary|width|frame|rules|cellspacing|cellpadding|bgcolor],tbody[char|charoff|valign],td[colspan|rowspan|headers|abbr|axis|scope|align|char|charoff|valign|nowrap|bgcolor|width|height],tfoot[char|charoff|valign],th[colspan|rowspan|headers|scope|abbr|axis|align|char|charoff|valign|nowrap|bgcolor|width|height],thead[char|charoff|valign],tr[char|charoff|valign|bgcolor],-ul[compact],video[name|src|allowfullscreen|muted|poster|width|height|controls|playsinline],audio[name|src|muted|controls],annotation[href|xref|definitionURL|encoding|cd|name|src],annotation-xml[href|xref|definitionURL|encoding|cd|name|src],maction[href|xref|mathcolor|mathbackground|actiontype|selection],maligngroup[href|xref|mathcolor|mathbackground|groupalign],malignmark[href|xref|mathcolor|mathbackground|edge],math[xmlns|href|xref|display|maxwidth|overflow|altimg|altimg-width|altimg-height|altimg-valign|alttext|cdgroup|mathcolor|mathbackground|scriptlevel|displaystyle|scriptsizemultiplier|scriptminsize|infixlinebreakstyle|decimalpoint|mathvariant|mathsize|width|height|valign|form|fence|separator|lspace|rspace|stretchy|symmetric|maxsize|minsize|largeop|movablelimits|accent|linebreak|lineleading|linebreakstyle|linebreakmultchar|indentalign|indentshift|indenttarget|indentalignfirst|indentshiftfirst|indentalignlast|indentshiftlast|depth|lquote|rquote|linethickness|munalign|denomalign|bevelled|voffset|open|close|separators|notation|subscriptshift|superscriptshift|accentunder|align|rowalign|columnalign|groupalign|alignmentscope|columnwidth|rowspacing|columnspacing|rowlines|columnlines|frame|framespacing|equalrows|equalcolumns|side|minlabelspacing|rowspan|columnspan|edge|stackalign|charalign|charspacing|longdivstyle|position|shift|location|crossout|length|leftoverhang|rightoverhang|mslinethickness|selection],menclose[href|xref|mathcolor|mathbackground|notation],merror[href|xref|mathcolor|mathbackground],mfenced[href|xref|mathcolor|mathbackground|open|close|separators],mfrac[href|xref|mathcolor|mathbackground|linethickness|munalign|denomalign|bevelled],mglyph[href|xref|mathcolor|mathbackground|src|alt|width|height|valign],mi[href|xref|mathcolor|mathbackground|mathvariant|mathsize],mlabeledtr[href|xref|mathcolor|mathbackground],mlongdiv[href|xref|mathcolor|mathbackground|longdivstyle|align|stackalign|charalign|charspacing],mmultiscripts[href|xref|mathcolor|mathbackground|subscriptshift|superscriptshift],mn[href|xref|mathcolor|mathbackground|mathvariant|mathsize],mo[href|xref|mathcolor|mathbackground|mathvariant|mathsize|form|fence|separator|lspace|rspace|stretchy|symmetric|maxsize|minsize|largeop|movablelimits|accent|linebreak|lineleading|linebreakstyle|linebreakmultchar|indentalign|indentshift|indenttarget|indentalignfirst|indentshiftfirst|indentalignlast|indentshiftlast],mover[href|xref|mathcolor|mathbackground|accent|align],mpadded[href|xref|mathcolor|mathbackground|height|depth|width|lspace|voffset],mphantom[href|xref|mathcolor|mathbackground],mprescripts[href|xref|mathcolor|mathbackground],mroot[href|xref|mathcolor|mathbackground],mrow[href|xref|mathcolor|mathbackground],ms[href|xref|mathcolor|mathbackground|mathvariant|mathsize|lquote|rquote],mscarries[href|xref|mathcolor|mathbackground|position|location|crossout|scriptsizemultiplier],mscarry[href|xref|mathcolor|mathbackground|location|crossout],msgroup[href|xref|mathcolor|mathbackground|position|shift],msline[href|xref|mathcolor|mathbackground|position|length|leftoverhang|rightoverhang|mslinethickness],mspace[href|xref|mathcolor|mathbackground|mathvariant|mathsize],msqrt[href|xref|mathcolor|mathbackground],msrow[href|xref|mathcolor|mathbackground|position],mstack[href|xref|mathcolor|mathbackground|align|stackalign|charalign|charspacing],mstyle[href|xref|mathcolor|mathbackground|scriptlevel|displaystyle|scriptsizemultiplier|scriptminsize|infixlinebreakstyle|decimalpoint|mathvariant|mathsize|width|height|valign|form|fence|separator|lspace|rspace|stretchy|symmetric|maxsize|minsize|largeop|movablelimits|accent|linebreak|lineleading|linebreakstyle|linebreakmultchar|indentalign|indentshift|indenttarget|indentalignfirst|indentshiftfirst|indentalignlast|indentshiftlast|depth|lquote|rquote|linethickness|munalign|denomalign|bevelled|voffset|open|close|separators|notation|subscriptshift|superscriptshift|accentunder|align|rowalign|columnalign|groupalign|alignmentscope|columnwidth|rowspacing|columnspacing|rowlines|columnlines|frame|framespacing|equalrows|equalcolumns|side|minlabelspacing|rowspan|columnspan|edge|stackalign|charalign|charspacing|longdivstyle|position|shift|location|crossout|length|leftoverhang|rightoverhang|mslinethickness|selection],msub[href|xref|mathcolor|mathbackground|subscriptshift],msubsup[href|xref|mathcolor|mathbackground|subscriptshift|superscriptshift],msup[href|xref|mathcolor|mathbackground|superscriptshift],mtable[href|xref|mathcolor|mathbackground|align|rowalign|columnalign|groupalign|alignmentscope|columnwidth|width|rowspacing|columnspacing|rowlines|columnlines|frame|framespacing|equalrows|equalcolumns|displaystyle|side|minlabelspacing],mtd[href|xref|mathcolor|mathbackground|rowspan|columnspan|rowalign|columnalign|groupalign],mtext[href|xref|mathcolor|mathbackground|mathvariant|mathsize|width|height|depth|linebreak],mtr[href|xref|mathcolor|mathbackground|rowalign|columnalign|groupalign],munder[href|xref|mathcolor|mathbackground|accentunder|align],munderover[href|xref|mathcolor|mathbackground|accent|accentunder|align],none[href|xref|mathcolor|mathbackground],semantics[href|xref|definitionURL|encoding],svg[*],g[*],circle[*]',
    external_plugins: undefined,
    font_formats:
      "Lato=lato,Helvetica Neue,Helvetica,Arial,sans-serif; Balsamiq Sans=Balsamiq Sans,lato,Helvetica Neue,Helvetica,Arial,sans-serif; Architect's Daughter=Architects Daughter,lato,Helvetica Neue,Helvetica,Arial,sans-serif; Andale Mono=andale mono,times; Arial=arial,helvetica,sans-serif; Arial Black=arial black,avant garde; Book Antiqua=book antiqua,palatino; Comic Sans MS=comic sans ms,sans-serif; Courier New=courier new,courier; Georgia=georgia,palatino; Helvetica=helvetica; Impact=impact,chicago; Symbol=symbol; Tahoma=tahoma,arial,helvetica,sans-serif; Terminal=terminal,monaco; Times New Roman=times new roman,times; Trebuchet MS=trebuchet ms,geneva; Verdana=verdana,geneva; Webdings=webdings; Wingdings=wingdings,zapf dingbats",
    // height: 400,
    language: 'en_US',
    language_load: false,
    language_url: 'none',
    menu: {
      format: {
        title: 'Format',
        items:
          'bold italic underline strikethrough superscript subscript codeformat | formats blockformats fontformats fontsizes align directionality | forecolor backcolor | removeformat'
      },
      insert: {
        title: 'Insert',
        items: 'instructure_links | inserttable instructure_media_embed | hr'
      },
      tools: {title: 'Tools', items: 'wordcount'},
      view: {title: 'View', items: 'fullscreen instructure_html_view'}
    },
    menubar: 'edit view insert format tools table',
    mobile: {theme: 'silver'},
    non_empty_elements:
      'td th iframe video audio object script a i area base basefont br col frame hr img input isindex link meta param embed source wbr track',
    plugins: [
      'autolink',
      'media',
      'paste',
      'table',
      'link',
      'directionality',
      'lists',
      'hr',
      'fullscreen',
      'instructure-ui-icons',
      'instructure_condensed_buttons',
      'instructure_links',
      'instructure_html_view',
      'instructure_media_embed',
      'a11y_checker',
      'wordcount'
    ],
    preview_styles:
      'font-family font-size font-weight font-style text-decoration text-transform border border-radius outline text-shadow',
    remove_script_host: true,
    resize: true,
    // selector: '#textarea2',
    // setup: ed => {},
    show_media_upload: false,
    skin: false,
    statusbar: false,
    valid_elements:
      '@[id|class|style|title|dir<ltr?rtl|lang|xml::lang|onclick|ondblclick|onmousedown|onmouseup|onmouseover|onmousemove|onmouseout|onkeypress|onkeydown|onkeyup|role],a[rel|rev|charset|hreflang|tabindex|accesskey|type|name|href|target|title|class|onfocus|onblur],strong/b,em/i,strike,u,#p,-ol[type|compact],-ul[type|compact],-li,br,img[longdesc|usemap|src|border|alt|title|hspace|vspace|width|height|align|role],-sub,-sup,-blockquote,-table[border=0|cellspacing|cellpadding|width|frame|rules|height|align|summary|bgcolor|background|bordercolor],-tr[rowspan|width|height|align|valign|bgcolor|background|bordercolor],tbody,thead,tfoot,#td[colspan|rowspan|width|height|align|valign|bgcolor|background|bordercolor|scope],#th[colspan|rowspan|width|height|align|valign|scope],caption,-div,-span,-code,-pre,address,-h1,-h2,-h3,-h4,-h5,-h6,hr[size|noshade],-font[face|size|color],dd,dl,dt,cite,abbr,acronym,del[datetime|cite],ins[datetime|cite],object[classid|width|height|codebase|*],param[name|value|_value],embed[type|width|height|src|*],script[src|type],map[name],area[shape|coords|href|alt|target],bdo,col[align|char|charoff|span|valign|width],colgroup[align|char|charoff|span|valign|width],dfn,kbd,label[for],legend,q[cite],samp,small,tt,var,big,figure,figcaption,source,track,mark,article,aside,details,footer,header,nav,section,summary,time'
  }
}

function addCanvasConnection(propsOut, propsIn) {
  if (propsIn.trayProps) {
    propsOut.trayProps = propsIn.trayProps
    propsOut.editorOptions.plugins.splice(
      0,
      0,
      'instructure_documents',
      'instructure_image',
      'instructure_record',
      'instructure_external_tools'
    )
    propsOut.editorOptions.menu.insert.items =
      'instructure_links instructure_image instructure_media instructure_document | inserttable instructure_media_embed | hr'
  }
}
export default function CanvasRce(props) {
  const {defaultContent, textareaId, height, language, highContrastCSS, trayProps, ...rest} = props
  const rceRef = createRef(null)
  useState(() => formatMessage.setup({locale: normalizeLocale(props.language)}))
  const [translations, setTranslations] = useState(() => {
    const locale = normalizeLocale(props.language)
    const p = getTranslations(locale)
      .then(() => {
        setTranslations(true)
      })
      .catch(err => {
        // eslint-disable-next-line no-console
        console.error('Failed loading the language file for', locale, '\n Cause:', err)
        setTranslations(false)
      })
    return p
  })

  // useEffect(() => {
  //   rceRef.current?.setCode(props.content)
  // }, [props.content, rceRef])

  // merge CanvasRce props into the base properties
  // Note: languages is a bit of a mess. Tinymce and Canvas
  // have 2 different sets of language names. normalizeLocale
  // takes the lanbuage prop and returns the locale Canvas knows.
  // editorLanguage takes the language prop and returns the
  // corresponding name for tinymce.
  const rceProps = {...baseProps}
  rceProps.language = normalizeLocale(props.language || 'en')
  rceProps.highContrastCSS = highContrastCSS || []
  rceProps.defaultContent = defaultContent
  rceProps.textareaId = textareaId
  rceProps.editorOptions.selector = `#${textareaId}`
  rceProps.editorOptions.height = height
  rceProps.editorOptions.language = editorLanguage(props.language || 'en')
  rceProps.trayProps = trayProps

  addCanvasConnection(rceProps, props)

  if (typeof translations !== 'boolean') {
    return formatMessage('Loading...')
  } else {
    return <RCEWrapper ref={rceRef} tinymce={tinyRCE} {...rceProps} {...rest} />
  }
}

CanvasRce.propTypes = {
  language: string,
  defaultContent: string,
  textareaId: string.isRequired,
  height: number,
  highContrastCSS: arrayOf(string),
  trayProps: trayPropTypes
}
