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

define([
  'compiled/editor/stocktiny',
  'jquery',
  'jquery.instructure_jquery_patches',
  'mathquill'
], function(tinymce, $) {

  // the loading of this @font-face is done here because tinyMCE was blocking rendering untill all of the css
  // was loaded. Remember to update the ?v1 querystring parameter if we ever update the font.
  $('<style>' +
      '@font-face { '+
        'font-family: Symbola; src: url(/font/Symbola.eot?v1); src: local("Symbola Regular"), local("Symbola"),' +
        'url(/font/Symbola.ttf?v1) format("truetype"),' +
        'url(/font/Symbola.otf?v1) format("opentype"),' +
        'url(/font/Symbola.svg?v1#webfont7MzkO3xs) format("svg");' +
      '}' +
    '</style>').appendTo("head");

  $("<span class='mathquill-embedded-latex' style='position: absolute; z-index: -1; top: 0; left: 0; width: 0; height: 0; overflow: hidden;'>a</span>").appendTo("body").mathquill();

  // like $.text() / Sizzle.getText(elems), except it also gets alt attributes
  // from images
  function getEquationText(elems) {
    var ret = "", elem;
    for ( var i = 0; elems[i]; i++ ) {
      elem = elems[i];
      // Get the text from text nodes and CDATA nodes
      if ( elem.nodeType === 3 || elem.nodeType === 4 ) {
        ret += elem.nodeValue;
      // Get alt attributes from IMG nodes
      } else if ( elem.nodeName == 'IMG' && elem.className == 'equation_image' ) {
        ret += $(elem).attr('alt');
      // Traverse everything else, except comment nodes
      } else if ( elem.nodeType !== 8 ) {
        ret += getEquationText( elem.childNodes );
      }
    }
    return ret;
  }

  tinymce.create('tinymce.plugins.InstructureEquation', {
    init : function(ed, url) {
      ed.addCommand('instructureEquation', function() {
        var nodes = $('<span>' + ed.selection.getContent() + '</span>');
        var equation = getEquationText(nodes).replace(/^\s+|\s+$/g, '');
        if (!equation) {
          equation = "1 + 1";
        }

        var $editor = $("#" + ed.id);
        var $box = $("#instructure_equation_prompt");
        if($box.length == 0) {
          var $box = $(document.createElement('div'));
          $box.append("Use the equation editor below (or type/paste in your equation in LaTeX format). " +
                      "<form id='instructure_equation_prompt_form' style='margin-top: 5px;'>" +
                      "<span class='mathquill-editor' style='width: auto; font-size: 1.5em'></span>" +
                      "<div class='actions' style='padding-top: 10px'><button type='submit' class='button' style='float: right'>Insert Equation</button></div>" +
                      "</form>");
          $box.find("#instructure_equation_prompt_form").submit(function(event) {
            var $editor = $box.data('editor');
            event.preventDefault();
            event.stopPropagation();
            var text = $(this).find(".mathquill-editor").mathquill('latex');
            var url = "/equation_images/" + encodeURIComponent(escape(text));
            var $div = $(document.createElement('div'));
            var $img = $(document.createElement('img'));
            $img.attr('src', url).attr('alt', text).attr('title', text).attr('class', 'equation_image');
            $div.append($img);
            $box.data('restore_caret')();
            $editor.editorBox('insert_code', $div.html());
            $box.dialog('close');
          });
          $box.attr('id', 'instructure_equation_prompt');
          $("body").append($box);
        }
        var prevSelection = ed.selection.getBookmark();
        $box.data('restore_caret', function() {
          ed.selection.moveToBookmark(prevSelection);
        });

        $box.data('editor', $editor);
        $box.dialog('close').dialog({
          autoOpen: false,
          width: 690,
          minWidth: 690,
          minHeight: 300,
          resizable: true,
          height: "auto",
          title: "Embed Math Equation"
        }).dialog('open');

        // needs to be visible for some computed styles to work when we write
        // the equation
        $box.find(".mathquill-editor").mathquill('revert').
          addClass('mathquill-editor').mathquill('editor').
          mathquill('write', equation).focus();
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
});

