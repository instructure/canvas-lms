tinymce.create('tinymce.plugins.BZIframes', {
  init : function(ed, url) {
    ed.addCommand('bzIframe', function() {
      var link;
      if(link = prompt("Link to canvas page")) {
        link = link.replace(/</g, '&lt;');
        link = link.replace(/"/g, '&quot;');

        ed.selection.setContent('<iframe class="bz-self-reference" src="'+link+'" width="800" height="450"></iframe>');
      }
    });
    ed.addButton('bz_iframe', {
      title: 'Add Framed Page',
      image: url + '/button.png',
      cmd: 'bzIframe'
    });
  },

  getInfo : function() {
    return {
      longname : 'BZIframes',
      version : tinymce.majorVersion + "." + tinymce.minorVersion
    };
  }
});

tinymce.PluginManager.add('bz_iframes', tinymce.plugins.BZIframes);
