define([
  'compiled/editor/stocktiny',
  'i18n!editor',
  'jquery',
  'str/htmlEscape',
  'jqueryui/dialog'
], function(tinymce, I18n, $, htmlEscape) {

  tinymce.create('tinymce.plugins.InstructureImagePlugin', {
    init : function(ed, url) {
      // Register commands
      ed.addCommand('mceInstructureImage', function() {
        var selectedNode = ed.selection.getNode();

        // Internal image object like a flash placeholder
        if (ed.dom.getAttrib(selectedNode, 'class', '').indexOf('mceItem') != -1) return;

        require(['compiled/views/tinymce/InsertUpdateImageView'], function(InsertUpdateImageView){
          new InsertUpdateImageView(ed, selectedNode);
        });
      });

      // Register buttons
      ed.addButton('instructure_image', {
        title : htmlEscape(I18n.t('embed_image', 'Embed Image')),
        cmd : 'mceInstructureImage',
        icon : 'image',
        onPostRender: function(){
          // highlight our button when an image is selected
          var btn = this;
          ed.on('NodeChange', function(event) {
            btn.active(event.nodeName == 'IMG' && event.className != 'equation_image');
          });
        }
      });

    },

    getInfo : function() {
      return {
        longname : 'Instructure image',
        author : 'Instructure',
        authorurl : 'http://instructure.com',
        infourl : 'http://instructure.com',
        version : '1'
      };
    }
  });

  // Register plugin
  tinymce.PluginManager.add('instructure_image', tinymce.plugins.InstructureImagePlugin);
});
