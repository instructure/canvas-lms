/**
 * Copyright (C) 2011 Instructure, Inc.
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
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
(function() {
	tinymce.create('tinymce.plugins.InstructureEquation', {
		init : function(ed, url) {
      var promptInteraction = {};
      setInterval(function() {
        promptInteraction.counter = (promptInteraction.counter || 0) + 1;
        if(promptInteraction.counter > 5) {
          promptInteraction.counter = 0;
          if (promptInteraction.hasChanged) {
            promptInteraction.hasChanged = false;
            $("#instructure_equation_prompt_form .prompt").triggerHandler('data_update');
          }
        }
      }, 100);
			ed.addCommand('instructureEquation', function() {
        var node = ed.selection.getNode()
        var equation = "1 + 1";
        if(node.nodeName == 'IMG' && node.className == 'equation_image') {
          equation = $(node).attr('alt');
        }
				var $editor = $("#" + ed.id);
        var $box = $("#instructure_equation_prompt");
        if($box.length == 0) {
          var $box = $(document.createElement('div'));
          $box.append("Paste or type your equation in the box below (using the LaTeX format). " +
                      "You should see a preview show up below the box: " +
                      "<form id='instructure_equation_prompt_form' style='margin-top: 5px;'>" +
                      "<textarea class='prompt' style='width: 100%; height: 50%'></textarea>" +
                      "<div class='rendered'></div>" +
                      "<div class='actions'><input type='submit' style='float: right' value='Insert Equation'/></div>" +
                      "</form>");
          $box.find("#instructure_equation_prompt_form").submit(function(event) {
            event.preventDefault();
            event.stopPropagation();
            var text = $(this).find(".prompt").val();
            var url = "http://latex.codecogs.com/gif.latex?" + escape(text);
            var $div = $(document.createElement('div'));
            var $img = $(document.createElement('img'));
            $img.attr('src', url).attr('alt', text).attr('title', text).attr('class', 'equation_image');
            $div.append($img);
            $editor.editorBox('insert_code', $div.html()); //"<img src='" + url + "' alt='" + text + "' class='equation_image'/>");
            $box.dialog('close');
          });
          $box.find(".rendered").delegate('.embed_image_link', 'click', function(event) {
            event.preventDefault();
            $box.find("#instructure_equation_prompt_form").submit();
          });
          $box.find("#instructure_equation_prompt_form .prompt").bind('change keypress', function() {
            promptInteraction.counter = 0;
            promptInteraction.hasChanged = true;
          }).bind('data_update', function() {
            var $img = $(".embed_image_link");
            var val = $(this).val();
            var url = "http://latex.codecogs.com/gif.latex?" + escape(val);
            if($img.length == 0) {
              var $div = $(document.createElement('div'));
              $div.css({
                textAlign: 'center',
                padding: 20
              });
              var $img = $(document.createElement('img'));
              $img.addClass('embed_image_link');
              $img.css('cursor', 'pointer');
              $img.attr('title', 'Click to Embed the Equation');
              $div.append($img);
              $("#instructure_equation_prompt .rendered").append($div);
            }
            $img.attr('src', url);
          }).triggerHandler('data_update');
          $box.attr('id', 'instructure_equation_prompt');
          $("body").append($box);
        }
        $box.find("#instructure_equation_prompt_form .prompt").val(equation)
          .triggerHandler('data_update');
        $box.dialog('close').dialog({
          autoOpen: false,
          width: 425,
          minWidth: 425,
          minHeight: 215,
          resizable: true,
          height: "auto",
          title: "Embed Math Equation",
          open: function() {
            $(this).find(".prompt").focus().select();
            promptInteraction.heightDelta = $(this).height() - $(this).find("textarea").height();
          },
          resize: function(event, ui) {
            $(this).find("textarea").height($(this).height() - promptInteraction.heightDelta);
          }
        }).dialog('open');
			});
			ed.addButton('instructure_equation', {
				title: 'Insert Math Equation',
				cmd: 'instructureEquation',
				image: url + '/img/button.gif'
			});
			ed.onNodeChange.add(function(ed, cm, e) {
				if(e.nodeName == 'IMG' && e.className == 'equation_image') {
					cm.setActive('instructure_equation', true);
				} else {
					cm.setActive('instructure_equation', false);
				}
			});
		},

		getInfo : function() {
			return {
				longname : 'InstructureEquation',
				author : 'Brian Whitmer',
				authorurl : 'http://www.instructure.com',
				infourl : 'http://www.instructure.com',
				version : tinymce.majorVersion + "." + tinymce.minorVersion
			};
		}
	});
	
	// Register plugin
	tinymce.PluginManager.add('instructure_equation', tinymce.plugins.InstructureEquation);
})();

