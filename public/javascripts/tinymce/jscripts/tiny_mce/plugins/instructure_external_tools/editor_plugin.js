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

// tinymce doesn't like its plugins being async,
// all dependencies must export to window

define([
  'compiled/editor/stocktiny',
  'i18n!editor',
  'jquery',
  'str/htmlEscape',
  'jquery.dropdownList',
  'jquery.instructure_jquery_patches',
  'jquery.instructure_misc_helpers',
  'jquery.instructure_misc_plugins',
], function(tinymce, I18n, $, htmlEscape) {

  var TRANSLATIONS = {
    embed_from_external_tool: I18n.t('embed_from_external_tool', '"Embed content from External Tool"'),
    more_external_tools: INST.htmlEscape(I18n.t('more_external_tools', "More External Tools"))
  };

  tinymce.create('tinymce.plugins.InstructureExternalTools', {
    init : function(ed, url) {
      if(!window || !window.INST || !window.INST.editorButtons || !window.INST.editorButtons.length) {
        return
      }
      var $dialog = null;
      var clumpedButtons = [];
      function buttonSelected(button) {
        var frameHeight = Math.max(Math.min($(window).height() - 100, 550), 100);
        if(!$dialog) {
          $dialog = $('<div id="external_tool_button_dialog" style="padding: 0; overflow-y: hidden;"/>')
            .hide()
            .html("<div class='teaser' style='width: 800px; margin-bottom: 10px; display: none;'></div>" +
                  "<iframe id='external_tool_button_frame' style='width: 800px; height: " + frameHeight +"px; border: 0;' src='/images/ajax-loader-medium-444.gif' borderstyle='0'/>")
            .appendTo('body')
            .dialog({
              autoOpen: false,
              width: 'auto',
              resizable: true,
              close: function() {
                $dialog.find("iframe").attr('src', '/images/ajax-loader-medium-444.gif');
              },
              title: TRANSLATIONS.embed_from_external_tool
            })
            .bind('dialogresize', function() {
              $(this).find('iframe').add('.fix_for_resizing_over_iframe').height($(this).height()).width($(this).width());
            })
            .bind('dialogresizestop', function() {
              $(".fix_for_resizing_over_iframe").remove();
            })
            .bind('dialogresizestart', function() {
              $(this).find('iframe').each(function(){
                $('<div class="fix_for_resizing_over_iframe" style="background: #fff;"></div>')
                  .css({
                    width: this.offsetWidth+"px", height: this.offsetHeight+"px",
                    position: "absolute", opacity: "0.001", zIndex: 10000000
                  })
                  .css($(this).offset())
                  .appendTo("body");
              });
            })
            .bind('selection', function(event, data) {
              var editor = $dialog.data('editor') || ed;
              if(data.embed_type == 'basic_lti') {
                if($("#external_tool_retrieve_url").attr('href')) {
                  var external_url = $.replaceTags($("#external_tool_retrieve_url").attr('href'), 'url', data.url);
                  $("#" + ed.id).editorBox('create_link', {
                    url: external_url,
                    title: data.title,
                    text: data.text
                  });
                } else {
                  console.log("cannot embed basic lti links in this context");
                }
              } else if(data.embed_type == 'image') {
                var html = $("<div/>").append($("<img/>", {
                  src: data.url,
                  alt: data.alt
                }).css({
                  width: data.width,
                  height: data.height
                })).html();
                $("#" + ed.id).editorBox('insert_code', html);
              } else if(data.embed_type == 'link') { 
                $("#" + ed.id).editorBox('create_link', {
                  url: data.url,
                  title: data.title,
                  text: data.text,
                  target: data.target == '_blank' ? '_blank' : null
                });
              } else if(data.embed_type == 'iframe') {
                var html = $("<div/>").append($("<iframe/>", {
                  src: data.url,
                  title: data.title
                }).css({
                  width: data.width,
                  height: data.height
                })).html();
                $("#" + ed.id).editorBox('insert_code', html);
              } else if(data.embed_type == 'rich_content') {
                $("#" + ed.id).editorBox('insert_code', data.html);
              } else if(data.embed_type == 'error' && data.message) {
                alert(data.message);
              } else {
                console.log("unrecognized embed type: " + data.embed_type);
              }
              $("#external_tool_button_dialog iframe").attr('src', 'about:blank');
              $("#external_tool_button_dialog").dialog('close');
            });
        }
        $dialog.dialog('option', 'title', 'Embed content from ' + button.name);
        $dialog.dialog('close')
          .dialog('option', 'width', button.width || 800)
          .dialog('option', 'height', button.height || frameHeight || 400)
          .dialog('open');
        $dialog.triggerHandler('dialogresize')
        $dialog.data('editor', ed);
        var url = $.replaceTags($("#context_external_tool_resource_selection_url").attr('href'), 'id', button.id);
        $dialog.find("iframe").attr('src', url);
      }
      for(var idx in INST.editorButtons) {
        var current_button = INST.editorButtons[idx];
        if(INST.editorButtons.length > INST.maxVisibleEditorButtons && idx >= INST.maxVisibleEditorButtons - 1) {
          clumpedButtons.push(current_button);
        } else {
          (function(button) {
            ed.addCommand('instructureExternalButton' + button.id, function() {
              buttonSelected(button);
            });
            ed.addButton('instructure_external_button_' + button.id, {
              title: button.name,
              cmd: 'instructureExternalButton' + button.id,
              image: button.icon_url,
              'class': 'instructure_external_tool_button'
            });
          })(current_button)
        }
      }
      if(clumpedButtons.length) {
        ed.addCommand('instructureExternalButtonClump', function() {
          var items = {};
          for(var idx in clumpedButtons) {
            (function(idx) {
              items["<img src='" + clumpedButtons[idx].icon_url + "'/>&nbsp;" + clumpedButtons[idx].name] = function() {
                buttonSelected(clumpedButtons[idx]);
              }
            })(idx);
          }
          $("#" + ed.id + "_instructure_external_button_clump").dropdownList({
            options: items
          });
        });
        ed.addButton('instructure_external_button_clump', {
          title: TRANSLATIONS.more_external_tools,
          cmd: 'instructureExternalButtonClump',
          image: '/images/downtick.png'
        })
      }
    },

    getInfo : function() {
      return {
        longname : 'InstructureExternalTools',
        author : 'Brian Whitmer',
        authorurl : 'http://www.instructure.com',
        infourl : 'http://www.instructure.com',
        version : tinymce.majorVersion + "." + tinymce.minorVersion
      };
    }
  });

  // Register plugin
  tinymce.PluginManager.add('instructure_external_tools', tinymce.plugins.InstructureExternalTools);
});

