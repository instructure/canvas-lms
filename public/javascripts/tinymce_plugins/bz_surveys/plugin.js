tinymce.create('tinymce.plugins.BZSurveys', {
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

      var existingQuestion = '';
      var existingOptions = '';

      var existing = ed.dom.get("instant-survey");
      if(existing) {
        existingQuestion = existing.querySelector("h6").textContent;
        var items = existing.querySelectorAll("label");
	for(var a = 0; a < items.length; a++) {
	  if(a)
	    existingOptions += "\n";
	  existingOptions += items[a].textContent;
	}
      }

      var label = document.createElement("label");
      label.innerHTML = "<span>Question:</span> ";
      var question = document.createElement("input");
      question.type = "text";
      question.name = "question";
      question.value = existingQuestion;
      label.appendChild(question);
      div.appendChild(label);

      var label = document.createElement("label");
      label.innerHTML = "<span>Options (one per line, max 5):</span> ";
      var ta = document.createElement("textarea");
      ta.setAttribute("rows", 5);
      ta.textContent = existingOptions;
      label.appendChild(ta);
      div.appendChild(label);

      var i = document.createElement("button");
      i.setAttribute("type", "button");
      i.className = "submit";
      i.innerHTML = "Remove Survey";
      i.onclick = function() {
            callback("", []);
            dialog.parentNode.removeChild(dialog);
      };
      div.appendChild(i);



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
            callback(question.value, ta.value.split("\n"));
            dialog.parentNode.removeChild(dialog);
      };
      div.appendChild(i);


      document.body.appendChild(dialog);
    }

    ed.addCommand('bzSurvey', function() {
      showFieldDialog("Instant Survey", function(question, options) {
	var existing = ed.dom.get("instant-survey");
	if(existing) {
		ed.dom.remove("instant-survey");
	}

	if(options.length == 0)
		return;

	var form = document.createElement("form");
	form.setAttribute("id", "instant-survey");
	var header = document.createElement("h6");
	header.textContent = question;
	form.appendChild(header);

	for(var i = 0; i < options.length; i++) {
		if(options[i].length == 0)
			continue;
		var label = document.createElement("label");

		var input = document.createElement("input");
		input.setAttribute("type", "radio");
		input.setAttribute("name", "instant_survey");
		input.setAttribute("value", options[i]);

		label.appendChild(input);

		var txt = document.createTextNode(" " + options[i]);
		label.appendChild(txt);

		form.appendChild(label);
	}

	ed.dom.add(ed.getBody(), form);
      });
    });
    ed.addButton('bz_survey', {
      title: 'Edit Instant Survey',
      image: url + '/button.png',
      cmd: 'bzSurvey'
    });
  },

  getInfo : function() {
    return {
      longname : 'BZSurveys',
      version : tinymce.majorVersion + "." + tinymce.minorVersion
    };
  }
});

tinymce.PluginManager.add('bz_surveys', tinymce.plugins.BZSurveys);
