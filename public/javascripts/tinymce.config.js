define([], function(){

  /**
   * Create an editor config instance, with some internal state passed in
  *   so the object knows how to generate a dynamic hash of default
  *   configuration parameters.  May get overridden by merging
  *   with another hash of overwriting config parameters.
  *
  *  @param {tinymce} tinymce the tinymce global which we use to pull
  *    some config info off of like the BaseURL for refrencing the skin css
  *  @param {INST} inst a config hash defined in public/javascripts/INST.js,
  *    provides feature information like whether notorious is enabled for
  *    their account.  Generally you can just pass it in after requiring it.
  *  @param {int} width The width of the viewport the editor is in, this is
  *    useful for deciding how many buttons to show per toolbar line
  *  @param {string} domId the "id" attribute of the element that's going
  *    to be transformed with a tinymce editor
  *
  *  @exports
  *  @constructor
  *  @return {EditorConfig}
  */
  var EditorConfig = function(tinymce, inst, width, domId){
    this.baseURL = tinymce.baseURL;
    this.maxButtons = inst.maxVisibleEditorButtons;
    this.extraButtons = inst.editorButtons;
    this.instConfig = inst;
    this.viewportWidth = width;
    this.idAttribute = domId;
  };

  /**
  * export an appropriate config hash for this config instance.
  * This returns a simple javascript object with our default
  * configuration parameters enabled.  You can override
  * any configuration parameters you want by combining this hash
  * with an override hash at runtime using "$.extend" or similar:
  *
  *   var overrides = { resize: false };
  *   var tinyOptions = $.extend(editorConfig.defaultConfig(), overrides);
  *   tinymce.init(tinyOptions);
  *
  * @return {Hash}
  */
  EditorConfig.prototype.defaultConfig = function(){
    return {
      selector: "#" + this.idAttribute,
      toolbar: this.toolbar(),
      theme: "modern",
      skin: "light",
      skin_url: "/vendor/tinymce_themes/light",
      plugins: "autolink,media,paste,table,textcolor,link,directionality",
      external_plugins: {
        "instructure_image": "/javascripts/tinymce_plugins/instructure_image/plugin.js",
        "instructure_links": "/javascripts/tinymce_plugins/instructure_links/plugin.js",
        "instructure_embed": "/javascripts/tinymce_plugins/instructure_embed/plugin.js",
        "instructure_equation": "/javascripts/tinymce_plugins/instructure_equation/plugin.js",
        "instructure_equella": "/javascripts/tinymce_plugins/instructure_equella/plugin.js",
        "instructure_external_tools": "/javascripts/tinymce_plugins/instructure_external_tools/plugin.js",
        "instructure_record": "/javascripts/tinymce_plugins/instructure_record/plugin.js"
      },
      language_load: false,
      convert_urls: false,
      // we add the menubar for a11y purposes but then
      // hide it with js for non screenreader users
      menubar: true,
      remove_script_host: true,
      resize: true,
      block_formats: "Paragraph=p;Header 2=h2;Header 3=h3;Header 4=h4;Preformatted=pre",


      extended_valid_elements: "@[id|accesskey|class|dir|lang|style|tabindex|title|contenteditable|contextmenu|draggable|dropzone|hidden|spellcheck|translate|align|role|aria-labelledby|aria-atomic|aria-busy|aria-controls|aria-describedby|aria-disabled|aria-dropeffect|aria-flowto|aria-grabbed|aria-haspopup|aria-hidden|aria-invalid|aria-label|aria-labelledby|aria-live|aria-owns|aria-relevant|aria-autocomplete|aria-checked|aria-disabled|aria-expanded|aria-haspopup|aria-hidden|aria-invalid|aria-label|aria-level|aria-multiline|aria-multiselectable|aria-orientation|aria-pressed|aria-readonly|aria-required|aria-selected|aria-sort|aria-valuemax|aria-valuemin|aria-valuenow|aria-valuetext],iframe[src|width|height|name|align|style|class|sandbox|allowfullscreen|webkitallowfullscreen|mozallowfullscreen],i[iclass],a[hidden|href|target|rel|media|hreflang|type|charset|name|rev|shape|coords|download],div,span,#p,h2,h3,h4,h5,h6,header,ul,ol,li[value],ol[reversed|start|type|compact],pre[width],table[border|summary|width|frame|rules|cellspacing|cellpadding|bgcolor],tbody[char|charoff|valign],td[colspan|rowspan|headers|abbr|axis|scope|align|char|charoff|valign|nowrap|bgcolor|width|height],tfoot[char|charoff|valign],th[colspan|rowspan|headers|scope|abbr|axis|align|char|charoff|valign|nowrap|bgcolor|width|height],thead[char|charoff|valign],title,tr[char|charoff|valign|bgcolor],ul[compact],annotation[href|xref|definitionURL|encoding|cd|name|src],annotation-xml[href|xref|definitionURL|encoding|cd|name|src],maction[href|xref|mathcolor|mathbackground|actiontype|selection],maligngroup[href|xref|mathcolor|mathbackground|groupalign],malignmark[href|xref|mathcolor|mathbackground|edge],math[xmlns|href|xref|display|maxwidth|overflow|altimg|altimg-width|altimg-height|altimg-valign|alttext|cdgroup|mathcolor|mathbackground|scriptlevel|displaystyle|scriptsizemultiplier|scriptminsize|infixlinebreakstyle|decimalpoint|mathvariant|mathsize|width|height|valign|form|fence|separator|lspace|rspace|stretchy|symmetric|maxsize|minsize|largeop|movablelimits|accent|linebreak|lineleading|linebreakstyle|linebreakmultchar|indentalign|indentshift|indenttarget|indentalignfirst|indentshiftfirst|indentalignlast|indentshiftlast|depth|lquote|rquote|linethickness|munalign|denomalign|bevelled|voffset|open|close|separators|notation|subscriptshift|superscriptshift|accentunder|align|rowalign|columnalign|groupalign|alignmentscope|columnwidth|rowspacing|columnspacing|rowlines|columnlines|frame|framespacing|equalrows|equalcolumns|side|minlabelspacing|rowspan|columnspan|edge|stackalign|charalign|charspacing|longdivstyle|position|shift|location|crossout|length|leftoverhang|rightoverhang|mslinethickness|selection],menclose[href|xref|mathcolor|mathbackground|notation],merror[href|xref|mathcolor|mathbackground],mfenced[href|xref|mathcolor|mathbackground|open|close|separators],mfrac[href|xref|mathcolor|mathbackground|linethickness|munalign|denomalign|bevelled],mglyph[href|xref|mathcolor|mathbackground|src|alt|width|height|valign],mi[href|xref|mathcolor|mathbackground|mathvariant|mathsize],mlabeledtr[href|xref|mathcolor|mathbackground],mlongdiv[href|xref|mathcolor|mathbackground|longdivstyle|align|stackalign|charalign|charspacing],mmultiscripts[href|xref|mathcolor|mathbackground|subscriptshift|superscriptshift],mn[href|xref|mathcolor|mathbackground|mathvariant|mathsize],mo[href|xref|mathcolor|mathbackground|mathvariant|mathsize|form|fence|separator|lspace|rspace|stretchy|symmetric|maxsize|minsize|largeop|movablelimits|accent|linebreak|lineleading|linebreakstyle|linebreakmultchar|indentalign|indentshift|indenttarget|indentalignfirst|indentshiftfirst|indentalignlast|indentshiftlast],mover[href|xref|mathcolor|mathbackground|accent|align],mpadded[href|xref|mathcolor|mathbackground|height|depth|width|lspace|voffset],mphantom[href|xref|mathcolor|mathbackground],mprescripts[href|xref|mathcolor|mathbackground],mroot[href|xref|mathcolor|mathbackground],mrow[href|xref|mathcolor|mathbackground],ms[href|xref|mathcolor|mathbackground|mathvariant|mathsize|lquote|rquote],mscarries[href|xref|mathcolor|mathbackground|position|location|crossout|scriptsizemultiplier],mscarry[href|xref|mathcolor|mathbackground|location|crossout],msgroup[href|xref|mathcolor|mathbackground|position|shift],msline[href|xref|mathcolor|mathbackground|position|length|leftoverhang|rightoverhang|mslinethickness],mspace[href|xref|mathcolor|mathbackground|mathvariant|mathsize],msqrt[href|xref|mathcolor|mathbackground],msrow[href|xref|mathcolor|mathbackground|position],mstack[href|xref|mathcolor|mathbackground|align|stackalign|charalign|charspacing],mstyle[href|xref|mathcolor|mathbackground|scriptlevel|displaystyle|scriptsizemultiplier|scriptminsize|infixlinebreakstyle|decimalpoint|mathvariant|mathsize|width|height|valign|form|fence|separator|lspace|rspace|stretchy|symmetric|maxsize|minsize|largeop|movablelimits|accent|linebreak|lineleading|linebreakstyle|linebreakmultchar|indentalign|indentshift|indenttarget|indentalignfirst|indentshiftfirst|indentalignlast|indentshiftlast|depth|lquote|rquote|linethickness|munalign|denomalign|bevelled|voffset|open|close|separators|notation|subscriptshift|superscriptshift|accentunder|align|rowalign|columnalign|groupalign|alignmentscope|columnwidth|rowspacing|columnspacing|rowlines|columnlines|frame|framespacing|equalrows|equalcolumns|side|minlabelspacing|rowspan|columnspan|edge|stackalign|charalign|charspacing|longdivstyle|position|shift|location|crossout|length|leftoverhang|rightoverhang|mslinethickness|selection],msub[href|xref|mathcolor|mathbackground|subscriptshift],msubsup[href|xref|mathcolor|mathbackground|subscriptshift|superscriptshift],msup[href|xref|mathcolor|mathbackground|superscriptshift],mtable[href|xref|mathcolor|mathbackground|align|rowalign|columnalign|groupalign|alignmentscope|columnwidth|width|rowspacing|columnspacing|rowlines|columnlines|frame|framespacing|equalrows|equalcolumns|displaystyle|side|minlabelspacing],mtd[href|xref|mathcolor|mathbackground|rowspan|columnspan|rowalign|columnalign|groupalign],mtext[href|xref|mathcolor|mathbackground|mathvariant|mathsize|width|height|depth|linebreak],mtr[href|xref|mathcolor|mathbackground|rowalign|columnalign|groupalign],munder[href|xref|mathcolor|mathbackground|accentunder|align],munderover[href|xref|mathcolor|mathbackground|accent|accentunder|align],none[href|xref|mathcolor|mathbackground],semantics[href|xref|definitionURL|encoding]",

      non_empty_elements: "td th iframe video audio object script a i area base basefont br col frame hr img input isindex link meta param embed source wbr track",
      content_css: window.ENV.url_to_what_gets_loaded_inside_the_tinymce_editor_css,
      browser_spellcheck: true
    };
  };


  /**
   * builds the configuration information that decides whether to clump
   * up external buttons or not based on the number of extras we
   * want to add.
   *
   * @private
   * @return {String} comma delimited set of external buttons
   */
  EditorConfig.prototype.external_buttons = function() {
    var externals = "";
    for (var idx = 0; this.extraButtons && (idx < this.extraButtons.length); idx++) {
      if (this.extraButtons.length <= this.maxButtons || idx < this.maxButtons - 1) {
        externals = externals + ",instructure_external_button_" + this.extraButtons[idx].id;
      } else if (!externals.match(/instructure_external_button_clump/)) {
        externals = externals + ",instructure_external_button_clump";
      }
    }
    return externals;
  };


  /**
   * uses externally provided settings to decide which instructure
   * plugin buttons to enable, and returns that string of button names.
   *
   * @private
   * @return {String} comma delimited set of non-core buttons
   */
  EditorConfig.prototype.buildInstructureButtons = function(){
    var instructure_buttons = ",instructure_image,instructure_equation";
    instructure_buttons = instructure_buttons + this.external_buttons();
    if(this.instConfig && this.instConfig.allowMediaComments && (this.instConfig.kalturaSettings && !this.instConfig.kalturaSettings.hide_rte_button)) {
      instructure_buttons = instructure_buttons + ",instructure_record";
    }
    var equella_button = this.instConfig && this.instConfig.equellaEnabled ? ",instructure_equella" : "";
    instructure_buttons = instructure_buttons + equella_button;
    return instructure_buttons;
  };

  /**
   * groups of buttons that are always found together, so updating a config
   * name doesn't need to happen 3 places or not work.
   * @private
   */
  EditorConfig.prototype.formatBtnGroup = "bold,italic,underline,forecolor,backcolor,removeformat,alignleft,aligncenter,alignright";
  EditorConfig.prototype.positionBtnGroup = "outdent,indent,superscript,subscript,bullist,numlist";
  EditorConfig.prototype.fontBtnGroup = "ltr,rtl,fontsizeselect,formatselect";


  /**
   * usese the width to decide how many lines of buttons to break
   * up the toolbar over.
   *
   * @private
   * @return {Array<String>} each element is a string of button names
   *   representing the buttons to appear on the n-th line of the toolbar
   */
  EditorConfig.prototype.balanceButtons = function(instructure_buttons){
    var instBtnGroup = "table,instructure_links,unlink" + instructure_buttons;
    var buttons1 = "";
    var buttons2 = "";
    var buttons3 = "";

    if (this.viewportWidth < 359 && this.viewportWidth > 0) {
      buttons1 = this.formatBtnGroup;
      buttons2 = this.positionBtnGroup + "," + instBtnGroup;
      buttons3 = this.fontBtnGroup;
    } else if (this.viewportWidth < 1200) {
      buttons1 = this.formatBtnGroup + "," + this.positionBtnGroup;
      buttons2 = instBtnGroup + "," + this.fontBtnGroup;
    } else {
      buttons1 = this.formatBtnGroup + "," + this.positionBtnGroup + "," + instBtnGroup + "," + this.fontBtnGroup;
    }
    return [buttons1, buttons2, buttons3];
  };


  /**
   * builds the custom buttons, and hands them off to be munged
   * in with the core buttons and balanced across the toolbar.
   *
   * @private
   * @return {Array<String>} each element is a string of button names
   *   representing the buttons to appear on the n-th line of the toolbar
   */
  EditorConfig.prototype.toolbar = function(){
    var instructure_buttons = this.buildInstructureButtons();
    return this.balanceButtons(instructure_buttons);
  };

  return EditorConfig;
});
