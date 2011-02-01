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
	tinymce.create('tinymce.plugins.InstructureEmbed', {
		init : function(ed, url) {
      var promptInteraction = {};
      setInterval(function() {
        promptInteraction.counter = (promptInteraction.counter || 0) + 1;
        if(promptInteraction.counter > 5) {
          promptInteraction.counter = 0;
          if (promptInteraction.hasChanged) {
            promptInteraction.hasChanged = false;
            $("#instructure_embed_prompt_form .prompt").triggerHandler('data_update');
          }
        }
      }, 100);
			ed.addCommand('instructureEmbed', function(search) {
				var $editor = $("#" + ed.id);
        // var url = "";
        // var link = $editor.editorBox('selection_link')
        // if(link) { url = link.url; }
        // url = url || "http://";
        // url = prompt("Type or paste the link in the box below", url);
        // if(url) {
          // $editor.editorBox('create_link', url);
        // }
        // return;
        var $box = $("#instructure_embed_prompt");
        if($box.length == 0) {
          var $box = $(document.createElement('div'));
          $box.append("Paste or type the URL of the image you'd like to embed:<form id='instructure_embed_prompt_form' style='margin-top: 5px;'><table class='formtable'><tr><td>URL:</td><td><input type='text' class='prompt' style='width: 250px;' value='http://'/></td></tr><tr><td class='nobr'>Alternate Text:</td><td><input type='text' class='alt_text' style='width: 150px;' value=''/></td></tr><tr><td colspan='2' style='text-align: right;'><input type='submit' value='Embed Image'/></td></tr></table></form><div class='actions'></div>");
          var $a = $("<a href='#'/>");
          $a.addClass('flickr_search_link');
          $a.text("Search flickr creative commons");
          $a.click(function(event) {
            event.preventDefault();
            $("#instructure_embed_prompt").dialog('close');
            $.findImageForService("flickr_creative_commons", function(data) {
              var $div = $("<div/>");
              var $a = $("<a/>");
              $a.attr('href', data.link_url);
              var $img = $("<img/>");
              $img.attr('src', data.image_url);
              $img.attr('title', data.title);
              $img.attr('alt', data.title);
              $img.css('maxWidth', 500).css('maxHeight', 500);
              $a.append($img);
              $div.append($a);
              $("#instructure_embed_prompt").dialog('close');
              $editor.editorBox('insert_code', $div.html());
            });
          });
          $box.append($a);
          $box.find("#instructure_embed_prompt_form").submit(function(event) {
            event.preventDefault();
            event.stopPropagation();
            var alt = $("#instructure_embed_prompt_form .alt_text").val() || "";
            var text = $(this).find(".prompt").val();
            $editor.editorBox('insert_code', "<img src='" + text + "' alt='" + alt + "'/>");
            $box.dialog('close');
          });
          $box.find(".actions").delegate('.embed_image_link', 'click', function(event) {
            event.preventDefault();
            var alt = $("#instructure_embed_prompt_form .alt_text").val() || "";
            $editor.editorBox('insert_code', "<img src='" + $(event.target).closest('img').attr('src') + "' alt='" + alt + "'/>");
            $box.dialog('close');
          });
          $box.find("#instructure_embed_prompt_form .prompt").bind('change keypress', function() {
            promptInteraction.counter = 0;
            promptInteraction.hasChanged = true;
          }).bind('data_update', function() {
            $("#instructure_embed_prompt .actions").empty();
            var val = $(this).val();
            if(val.match(/\.(gif|png|jpg|jpeg)$/)) {
              var $div = $(document.createElement('div'));
              $div.css('textAlign', 'center');
              var $img = $(document.createElement('img'));
              $img.attr('src', val);
              $img.addClass('embed_image_link');
              $img.css('cursor', 'pointer');
              var img = new Image();
              img.src = val;
              var checkCompletion = function() {
                if(img.complete) {
                  if(img.height < 100 || (img.height > 100 && img.height < 200)) {
                    $img.height(img.height);
                  }
                } else {
                  setTimeout(checkCompletion, 500);
                }
              }
              setTimeout(checkCompletion, 500);
              $img.height(100);
              $img.attr('title', 'Click to Embed the Image');
              $div.append($img);
              $("#instructure_embed_prompt .actions").append($div);
            }
          });
          $box.attr('id', 'instructure_embed_prompt');
          $("body").append($box);
        }
        $box.dialog('close').dialog({
          autoOpen: false,
          width: 425,
          height: "auto",
          title: "Embed External Image",
          open: function() {
            $(this).find(".prompt").focus().select();
          }
        }).dialog('open');
        if(search == 'flickr') {
          $box.find(".flickr_search_link").click();
        }
				// var $content = $("#embed_content_" + ed.id);
				// var $editor = $("#" + ed.id);
				// var link = $editor.editorBox('selection_link');
        // var text = null;
        // if(link && link.url) {
          // text = link.url;
        // } else if(link && link.title) {
          // text = link.title
        // } else {
          // text = $content.find("table .search .search_terms").val();
        // }
				// if(text) {
					// $content.find("table .search .search_terms").val(text);
					// $content.find("table .options li.selected").removeClass('selected');
				// }
				// $content.show().dialog('close').dialog('open');
			});
			ed.addButton('instructure_embed', {
				title: 'Embed Image',
				cmd: 'instructureEmbed',
				image: url + '/img/button.gif'
			});
			// ed.onNodeChange.add(function(ed, cm, e) {
				// while(e.nodeName != 'A' && e.nodeName != 'BODY' && e.parentNode) {
					// e = e.parentNode;
				// }
				// if(e.nodeName == 'A') {
					// cm.setActive('instructure_embed', true);
				// } else {
					// cm.setActive('instructure_embed', false);
				// }
			// });
		},

		getInfo : function() {
			return {
				longname : 'InstructureEmbed',
				author : 'Brian Whitmer',
				authorurl : 'http://www.instructure.com',
				infourl : 'http://www.instructure.com',
				version : tinymce.majorVersion + "." + tinymce.minorVersion
			};
		}
	});
	
	// Register plugin
	tinymce.PluginManager.add('instructure_embed', tinymce.plugins.InstructureEmbed);
})();

