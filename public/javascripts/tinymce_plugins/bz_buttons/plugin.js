tinymce.create('tinymce.plugins.BZButtons', {
  init : function(ed, url) {
    /* *********************** */
    /* Generic helper function */
    function showDialog(headerHtml, creationFunction, callback) {
      var dialog = document.createElement("div");
      dialog.setAttribute("id", "bz-retained-field-dialog-holder");
      var div = document.createElement("div");
      div.setAttribute("id", "bz-retained-field-dialog");
      dialog.appendChild(div);

      var hdr = document.createElement("div");
      hdr.innerHTML = headerHtml;
      hdr.className = "bz-dialog-header";
      div.appendChild(hdr);

      creationFunction(div);

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
            callback();
            dialog.parentNode.removeChild(dialog);
      };
      div.appendChild(i);


      document.body.appendChild(dialog);
    }

    // returns the element reference
    function addField(div, title, tag_name) {
      var label = document.createElement("label");
      label.innerHTML = "<span>"+title+"</span> ";
      var type = document.createElement(tag_name);
      label.appendChild(type);
      div.appendChild(label);
      return type;
    }

    function addOptionToSelect(select, value) {
      var opt = document.createElement("option");
      opt.value = value;
      opt.innerHTML = value;
      select.appendChild(opt);
      return opt;
    }

    function htmlEncode(str) {
      return str.replace(/</, '&lt;');
    }

    /* *********************** */
    /* Button UI functions */

    function tooltipDialog() {
    	var contentInput, visibleInput;
	showDialog(
		"Add Tooltip",
		function(div) {
		  contentInput = addField(div, "Tooltip Content:", "input");
		  visibleInput = addField(div, "Visible Content:", "input");
		},
		function() {
        	  ed.selection.setContent('<span class="bz-has-tooltip" title="'+htmlEncode(contentInput.value)+'">'+htmlEncode(visibleInput.value)+'</span>');
		}
	);
    }

    ed.addCommand('bzTooltip', tooltipDialog);
    ed.addButton('bz_tooltip', {
      title: 'Add Tooltip',
      image: url + '/btn-tooltip.png',
      cmd: 'bzTooltip'
    });


    function quickQuizDialog() {
    	var titleInput;
	var statements = [], typeSelects = [];
	showDialog(
		"Add Tooltip",
		function(div) {
		  titleInput = addField(div, "Question:", "input");

		  var addButton = document.createElement("button");
		  addButton.setAttribute("type", "button");
		  addButton.innerHTML = "Add Item";
		  addButton.onclick = function() {
		  	statements.push(addField(div, "Option:", "input"));

			var types = addField(div, "Type:", "select");
			addOptionToSelect(types, "");
			addOptionToSelect(types, "wrong");
			addOptionToSelect(types, "true");
			addOptionToSelect(types, "correct");

			typeSelects.push(types);
		  };
		  div.appendChild(addButton);

		},
		function() {
		  var html = '';
		  html += '<h3>Quick Quiz</h3>';
		  html += '<div class="bz-quick-quiz">';
		  html += '<h5>Quick Quiz: '+titleInput.value+'</h5>';
	          html += '<ul style="list-style: none; margin: 0.25em 0;">';

		  for(var a = 0; a < statements.length; a++) {
			var s = statements[a].value;
			var v = typeSelects[a].options[typeSelects[a].selectedIndex].value;

			if(s.length)
				html += '<li><input name="insta" type="radio" value="'+v+'" />&nbsp;'+htmlEncode(s)+'</li>';
		  }
	          html += '</ul></div>';

        	  ed.selection.setContent(html);
		}
	);
    }

    ed.addCommand('bzQuickQuiz', quickQuizDialog);
    ed.addButton('bz_quickquiz', {
      title: 'Add Quick Quiz',
      image: url + '/btn-quick-quiz.png',
      cmd: 'bzQuickQuiz'
    });


    function checklistDialog() {
    	var headerInput, questionInput;
	var statements = [];
	showDialog(
		"Add Checklist",
		function(div) {
		  headerInput = addField(div, "Header:", "input");
		  questionInput = addField(div, "Question:", "input");

		  var addButton = document.createElement("button");
		  addButton.setAttribute("type", "button");
		  addButton.innerHTML = "Add Item";
		  addButton.onclick = function() {
		  	statements.push(addField(div, "Statement to checkoff:", "input"));
		  };
		  div.appendChild(addButton);
		},
		function() {
		  var html = '<form>';
		  html += '<h4>'+htmlEncode(headerInput.value)+'</h4>';
		  html += '<p>'+htmlEncode(questionInput.value)+'</p>';
	          html += '<ul class="bz-real-checkboxes">';

		  for(var a = 0; a < statements.length; a++) {
		  	var s = statements[a].value;
			if(s.length)
		  	  html += '<li><input name="todo" type="checkbox" />'+htmlEncode(s)+'</li>';
		  }

		  html += '</ul></form>';

        	  ed.selection.setContent(html);
		}
	);
    }

    ed.addCommand('bzChecklist', checklistDialog);
    ed.addButton('bz_checklist', {
      title: 'Add Checklist',
      image: url + '/btn-magic-checklist.png',
      cmd: 'bzChecklist'
    });


    /* *********************** */
  },

  getInfo : function() {
    return {
      longname : 'BZButtons',
      version : tinymce.majorVersion + "." + tinymce.minorVersion
    };
  }
});

tinymce.PluginManager.add('bz_buttons', tinymce.plugins.BZButtons);
