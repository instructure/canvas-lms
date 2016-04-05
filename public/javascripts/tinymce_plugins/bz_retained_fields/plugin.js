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
    ed.addCommand('bzRetainedFieldView', function() {
      var name = prompt("Field name");
      if(name && name.length) {
        name = name.replace(/</g, '&lt;');
        name = name.replace(/"/g, '&quot;');
        ed.selection.setContent('<span data-bz-retained="'+name+'">...</span>');
      }
    });
    ed.addButton('bz_retained_field', {
      title: 'Add Retained Field Edit Box',
      image: url + '/button.png',
      cmd: 'bzRetainedField'
    });
    ed.addButton('bz_retained_field_view', {
      title: 'Add Retained Field Display',
      image: url + '/button.png',
      cmd: 'bzRetainedFieldView'
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
