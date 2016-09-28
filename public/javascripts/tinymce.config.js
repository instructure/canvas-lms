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
      paste_data_images: true, /* Needed for IMG hack to get retained data field working */
      external_plugins: {
        "instructure_image": "/javascripts/tinymce_plugins/instructure_image/plugin.js",
        "instructure_links": "/javascripts/tinymce_plugins/instructure_links/plugin.js",
        "instructure_embed": "/javascripts/tinymce_plugins/instructure_embed/plugin.js",
        "instructure_equation": "/javascripts/tinymce_plugins/instructure_equation/plugin.js",
        "instructure_equella": "/javascripts/tinymce_plugins/instructure_equella/plugin.js",
        "instructure_external_tools": "/javascripts/tinymce_plugins/instructure_external_tools/plugin.js",
        "instructure_record": "/javascripts/tinymce_plugins/instructure_record/plugin.js",
        "bz_retained_fields": "/javascripts/tinymce_plugins/bz_retained_fields/plugin.js",
        "bz_iframes":         "/javascripts/tinymce_plugins/bz_iframes/plugin.js"
      },
      language_load: false,
      relative_urls: false,
      menubar: true,
      remove_script_host: true,
      resize: true,
      block_formats: "Paragraph=p;Header 3=h3;Header 4=h4;Header 5=h5;Block Quote=blockquote",

      style_formats: [
	{title: 'Intro', inline: 'span', classes: 'bz-intro'},
	{title: 'Spoiler', inline: 'span', classes: 'bz-spoiler'},
	{title: 'Teaser', inline: 'span', classes: 'bz-teaser'},
	{title: 'Video play button', inline: 'span', classes: 'bz-video-link'},
	{title: 'Quote source', inline: 'span', classes: 'bz-quote-source'},
	{title: 'Screen Reader Only', inline: 'span', classes: 'bz-screen-reader-text'},
	{title: 'Hidden from students', inline: 'span', classes: 'bz-hide-from-students'},
	{title: 'Hidden from everyone', inline: 'span', classes: 'bz-hide-from-all-users'},

	{title: 'Case Study Box', wrapper: true, block: 'div', classes: 'bz-case-study-box'},
	{title: 'Example Box', wrapper: true, block: 'div', classes: 'bz-example'},
	{title: 'Watch Out Box', wrapper: true, block: 'div', classes: 'bz-watch-out-box'},
	{title: 'Helpful Tip Box', wrapper: true, block: 'div', classes: 'bz-helpful-tip-box'},
	{title: 'Diagram Box', wrapper: true, block: 'div', classes: 'bz-diagram-box'},
	{title: 'Resource Box', wrapper: true, block: 'div', classes: 'bz-resource-box'},
	{title: 'Quick Practice Box', wrapper: true, block: 'div', classes: 'bz-practice-box'},
	{title: 'Pull out Box', wrapper: true, block: 'div', classes: 'bz-pull-out-box'},

	{title: 'To Do List', block: 'ul', classes: 'bz-to-do-item'},
	{title: 'Pros List', block: 'ul', classes: 'bz-pros'},
	{title: 'Cons List', block: 'ul', classes: 'bz-cons'}
      ],

      extended_valid_elements: "*[*]",
      valid_children: "+body[style|script|svg|textarea|img],+p[textarea|input]",

      content_css: "/stylesheets_compiled/legacy_normal_contrast/bundles/what_gets_loaded_inside_the_tinymce_editor.css," + window.bz_custom_css_url + ",/bz_editor.css",
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
  EditorConfig.prototype.external_buttons = function(){
    var externals = "";
    for(var idx in this.extraButtons) {
      if(this.extraButtons.length <= this.maxButtons || idx < this.maxButtons - 1) {
        externals = externals + ",instructure_external_button_" + this.extraButtons[idx].id;
      } else if(!externals.match(/instructure_external_button_clump/)) {
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
  EditorConfig.prototype.fontBtnGroup = "ltr,rtl,formatselect,styleselect";


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
    var stuff = this.balanceButtons(instructure_buttons);
    stuff[0] += (",bz_retained_field,bz_retained_field_view,bz_iframe,bz_tooltip,bz_quickquiz,bz_checklist");
    return stuff;
  };

  return EditorConfig;
});
