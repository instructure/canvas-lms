tinymce.create('tinymce.plugins.BZIframes', {
  init : function(ed, url) {
    function showFieldDialog(header, callback) {
      var dialog = document.createElement("div");
      dialog.setAttribute("id", "bz-retained-field-dialog-holder");
      var div = document.createElement("div");
      div.setAttribute("id", "bz-retained-field-dialog");
      dialog.appendChild(div);

      var hdr = document.createElement("div");
      hdr.innerHTML = header;
      hdr.className = "bz-dialog-header";
      div.appendChild(hdr);

      var label = document.createElement("label");
      label.innerHTML = "<span>Page to embed:</span> ";
      var type = document.createElement("select");
      label.appendChild(type);
      div.appendChild(label);

      $.get("/api/v1/courses/" + location.pathname.split("/")[2] + "/modules?include[]=items", function(data) {
        for(var i = 0; i < data.length; i++) {
          if(data[i].published) {
            var optgroup = document.createElement("optgroup");
            optgroup.setAttribute("label", data[i].name);
            for(var a = 0; a < data[i].items.length; a++) {
              var item = data[i].items[a];
              if(!item.published) continue;
              if(item.type != "Page") continue;
              var option = document.createElement("option");
              option.value = "/courses/" + location.pathname.split("/")[2] + "/pages/" + item.page_url;
              var str = "";
              for(var lol = 0; lol < item.indent; lol++)
                str += "\u00a0\u00a0\u00a0";
              str += item.title;
              option.textContent = str;
              optgroup.appendChild(option);
            }
            type.appendChild(optgroup);
          }
        }
      });

      var i = document.createElement("button");
      i.setAttribute("type", "button");
      i.className = "cancel";
      i.innerHTML = "Cancel";
      i.onclick = function() {
            dialog.parentNode.removeChild(dialog);
      };
      div.appendChild(i);


      var i = document.createElement("button");
      i.setAttribute("type", "button");
      i.className = "submit";
      i.innerHTML = "Insert";
      i.onclick = function() {
            callback(type.options[type.selectedIndex].value);
            dialog.parentNode.removeChild(dialog);
      };
      div.appendChild(i);


      document.body.appendChild(dialog);
    }

    ed.addCommand('bzIframe', function() {
      showFieldDialog("Embed Page", function(link) {
        link = link.replace(/</g, '&lt;');
        link = link.replace(/"/g, '&quot;');
        ed.selection.setContent('<iframe class="bz-self-reference" src="'+link+'" width="800" height="450">&#8291;</iframe>');
      });
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
