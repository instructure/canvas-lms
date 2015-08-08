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
// xsslint safeString.identifier frameHeight teaser

define([
  'compiled/editor/stocktiny',
  'jquery',
  'jqueryui/dialog'
], function(tinymce, $) {

  tinymce.create('tinymce.plugins.InstructureEquella', {
    init : function(ed, url) {
      ed.addCommand('instructureEquella', function() {
        var $box = $("#equella_dialog");
        var url = $("#equella_endpoint_url").attr('href');
        var action = $.trim($("#equella_action").text() || "") || "selectOrAdd";
        var callback_url = $("#equella_callback_url").attr('href');
        var cancel_url = $("#equella_cancel_url").attr('href');
        if(!url || !callback_url || !cancel_url) {
          alert("Equella is not properly configured for this account, please notify your system administrator.");
          return;
        }
        var frameHeight = Math.max(Math.min($(window).height() - 100, 550), 100);
        if(!$box.length) {
          $box = $('<div id="equella_dialog" style="padding: 0; overflow-y: hidden;"/>')
            .hide()
            .html("<div class='teaser' style='width: 800px; margin-bottom: 10px; display: none;'></div>" +
                  "<iframe style='background: url(/images/ajax-loader-medium-444.gif) no-repeat left top; width: 800px; height: " + frameHeight +"px; border: 0;' src='about:blank' borderstyle='0'/>")
            .appendTo('body')
            .dialog({
              autoOpen: false,
              width: 'auto',
              resizable: true,
              resizeStart: function(){
                $(this).find('iframe').each(function(){
                  $('<div class="fix_for_resizing_over_iframe" style="background: #fff;"></div>')
                    .css({
                      width: this.offsetWidth+"px", height: this.offsetHeight+"px",
                      position: "absolute", opacity: "0.001", zIndex: 10000000
                    })
                    .css($(this).offset())
                    .appendTo("body");
                });
              },
              resizeStop: function(){
                $(".fix_for_resizing_over_iframe").remove();
              },
              resize: function(){
                $(this).find('iframe').add('.fix_for_resizing_over_iframe').height($(this).height()).width($(this).width());
              },
              close: function() {
                $box.find("iframe").attr('src', 'about:blank');
              },
              title: "Embed content from Equella"
            })
            .bind('equella_ready', function(event, data) {
              var clickedEditor = $box.data('editor') || ed;
              var selectedContent = ed.selection.getContent();
              if(selectedContent) { // selected content
                ed.execCommand('mceInsertLink', false, {title: data.name, href: data.url, 'class': 'equella_content_link'});
              } else { // no selected content
                var $link = $("<div><a/></div>");
                $link.find("a")
                  .attr('title', data.name)
                  .attr('href', data.url)
                  .attr('class', 'equella_content_link')
                  .text(data.name)
                ed.execCommand('mceInsertContent', false, $link.html());
              }
              $("#equella_dialog").dialog('close');
            });
        }
        var teaser = $("#equella_teaser").html();
        $box.find(".teaser").hide();
        if(teaser) {
          $box.find(".teaser").html(teaser).show();
        }
        var full_url = url;
        full_url = full_url + "?method=lms&returnprefix=eq_&action=" + action;
        full_url = full_url + "&returnurl=" + encodeURIComponent(callback_url);
        full_url = full_url + "&cancelurl=" + encodeURIComponent(cancel_url);
        $box.data('editor', ed);
        $box.dialog('close').dialog('open');
        $box.find("iframe").attr('src', full_url);
      });
      ed.addButton('instructure_equella', {
        title: 'Insert Equella Links',
        cmd: 'instructureEquella',
        icon: 'equella icon-equella'
      });
    },

    getInfo : function() {
      return {
        longname : 'InstructureEquella',
        author : 'Brian Whitmer',
        authorurl : 'http://www.instructure.com',
        infourl : 'http://www.instructure.com',
        version : tinymce.majorVersion + "." + tinymce.minorVersion
      };
    }
  });

  // Register plugin
  tinymce.PluginManager.add('instructure_equella', tinymce.plugins.InstructureEquella);
});

