tinymce.create('tinymce.plugins.BZRetainedFields', {
  init : function(ed, url) {
    ed.addCommand('bzRetainedField', function() {
      var name = prompt("Field name");
      if(name && name.length) {
        name = name.replace(/</g, '&lt;');
        name = name.replace(/"/g, '&quot;');
        ed.selection.setContent('<textarea data-bz-retained="'+name+'"></textarea>');
      }
    });
    ed.addButton('bz_retained_field', {
      title: 'Add Retained Field',
      image: url + '/button.png',
      cmd: 'bzRetainedField'
    });
  },

  getInfo : function() {
    return {
      longname : 'BZRetainedFields',
      version : tinymce.majorVersion + "." + tinymce.minorVersion
    };
  }
});

tinymce.PluginManager.add('bz_retained_fields', tinymce.plugins.BZRetainedFields);
