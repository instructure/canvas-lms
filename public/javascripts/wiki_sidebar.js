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

(function(window, $, undefined){
  // stick the whole thing in a document.ready so we can make sure the dom is ready before we start doing our selectors       
  $(function(){
    
    var $editor_tabs = $("#editor_tabs"),
        $tree1 = $editor_tabs.find('ul#tree1'),
        $course_show_secondary = $("#course_show_secondary"), 
        $sidebar_upload_image_form = $("form#sidebar_upload_image_form"),
        $sidebar_upload_file_form = $("form#sidebar_upload_file_form");
    
    
    var wikiSidebar = window.wikiSidebar = {
      fileSelected: function(node) {
        var $span = node.find('span.text'),
            url = $span.attr('rel'),
            title = $span.text();
        wikiSidebar.editor.editorBox('create_link', {title: title , url: url, file: true, image: node.hasClass('image'), scribdable: node.hasClass('scribdable'), kaltura_entry_id: node.attr('data-media-entry-id'), kaltura_media_type: node.hasClass('video_playback') ? 'video' : 'audio'});
      },
      imageSelected: function($img) {
        var src = $img.data('url') || $img.attr('src'),
            alt = $img.attr('alt');
        wikiSidebar.editor.editorBox('insert_code', '<img alt="'+alt+'" src="'+src+'"/>');
      },
      insertSorted: function($file, $folder, child_selector) {
        $children = $folder.children(child_selector);
        for (var i = 0; i <= $children.length; ++i) {
          if (i == $children.length) {
            $folder.append($file);
          } else {
            $child = $children.eq(i);
            if (($child.data('position') || 0) >= $file.data('position')) {
              $child.before($file);
              break;
            }
          }
        }
      },
      fileAdded: function(attachment, in_folder) {
        var $file = $("#editor_tabs_2 .tree_node_template li.file").clone(true);
        $file
          .attr('class', 'file')
          .addClass(attachment.mime_class)
          .toggleClass('scribdable', attachment['scribdable?'])
          .data('position', attachment.position);
        if(attachment.media_entry_id) {
          $file
            .addClass('kalturable')
            .attr('data-media-entry-id', attachment.media_entry_id)
            .addClass(attachment.content_type && attachment.content_type.match(/video/) ? 'video_playback' : 'audio_playback');
        }
        attachment.name = attachment.display_name;
        $file.fillTemplateData({
          data: attachment,
          hrefValues: ['id'],
          id: 'sidebar_file_' + attachment.id
        });
        if(in_folder) {
          wikiSidebar.insertSorted($file,
              $tree1.find("#sidebar_folder_" + attachment.folder_id).children("ul:first"),
              'li.file');
        } else {
          $file.addClass('in_sidebar_folder_' + (attachment.folder_id || 0));
          wikiSidebar.insertSorted($file, $tree1, 'li.file');
        }
        if(attachment.mime_class == 'image' || attachment.content_type.match(/^image/)) {
          var $originalImage = $("#editor_tabs_3 .image_list .img_link:last"),
              $image = $originalImage.clone(true),
              $img = $image.find("img"),
              url = $.replaceTags($("#editor_tabs_3 .file_url").attr('href'), 'id', attachment.id);
          $image.removeClass('default_image');
          $img.attr({
            rel: url,
            src: attachment.thumbnail_url || '/images/ajax-loader.gif',
            _mce_src: url,
            alt: attachment.display_name,
            title: 'Click to embed ' + attachment.display_name
          }).data('url', url);
          $image.find(".display_name").text(attachment.display_name);
          if(in_folder) {
            $img.attr('src', attachment.thumbnail_url || url);
          }
          $originalImage.before($image);
        }
      },
      show: function() {
 
        $editor_tabs.addClass('showing');
        if(!$tree1.hasClass('initialized')) {
          $tree1.addClass('initialized unstyled_list');
          var url = $("#editor_tabs_2 .files_list_url").attr('href');
          $.ajaxJSON(url, 'GET', {}, function(data) {
            var hasFiles = false;
            $tree1.removeClass('unstyled_list').empty().hide();
            $("#editor_tabs_3 .image_list .img_link:not(.default_image)").remove();
            // load the tree in batches
            var idx = 0;
            var addList = [];
            var options_list = [];

            var finish = function() {
              if(!hasFiles) {
                $tree1.append("<li>No Files</li>");
              }
              $("#editor_tabs_3 .image_list .loading").remove();
              if(options_list.length > 0) {
                $("#editor_tabs_2 #attachment_folder_id").empty();
                $("#editor_tabs_3 #image_folder_id").empty();
                for(var idx in options_list) {
                  var $option = options_list[idx];
                  $("#editor_tabs_2 #attachment_folder_id").append($option.clone());
                  $("#editor_tabs_3 #image_folder_id").append($option.clone());
                }
              }
              //make the tree that holds the folders and files for this course
              $tree1.instTree({                
                multi: false,
                dragdrop: false,
                onClick: function (event,node) {
                  if (node.hasClass('leaf') || node.hasClass('file')) {
                    wikiSidebar.fileSelected(node);
                  } else if (node.hasClass('node')) {
                    node.children('.sign').click();
                  }
                }
              });
              $tree1.show();
              $editor_tabs.find("ul#tree1_temp").remove();
              $tree1.find("li.leaf.to_be_removed").remove();
              if($editor_tabs.tabs('option', 'selected') == 2) {
                $editor_tabs.triggerHandler('tabsselect');
              }
              $editor_tabs.tabs('select', $editor_tabs.tabs('option', 'selected'));
            };

            var addToOptions = function($folder, level) {
              level = level || 0;
              var id = $folder.attr('id');
              if($folder.hasClass('folder')) {
                var folder_id = id.split("_").pop();
                var name = $folder.getTemplateData({textValues: ['name']}).name;
                var $option = $("<option/>");
                $option.val(folder_id);
                if(level > 0) {
                  name = "- " + name;
                }
                if(name.length + level + 1 > 38) {
                  name = name.substring(0, 35) + "...";
                }
                for(var idx = 0; idx < level; idx++) {
                  name = "&nbsp;&nbsp;" + name;
                }
                $option.html(name);
                options_list.push($option);
              }
              $editor_tabs.find("li.folder.in_" + id).each(function() {
                addToOptions($(this), level + 1);
              });
            };

            var processBatch = function(first_time) {
              var batchCount = 0;
              if (first_time) {
                $tree1.find("li.file").addClass('to_be_removed');
                $tree1.find("li.folder.in_sidebar_folder_0").each(function() {
                  addList.push($(this));
                  addToOptions($(this));
                });
              }

              while (batchCount < 50) {
                var $item = addList.shift();
                if($item) {
                  var id = $item.attr('id');
                  $editor_tabs.find("li.in_" + id).each(function() {
                    var $this = $(this);
                    $item.children("ul").append($this);
                    $this.removeClass('to_be_removed');
                    if($this.hasClass('folder')) {
                      addList.push($this);
                    }
                  });
                } else {
                  finish();
                  return;
                }
                ++batchCount;
              }

              setTimeout(processBatch, 50);
            };

            var addBatch = function() {
              var batchCount = 0;
              while (idx < data.length && batchCount < 50) {
                var item = data[idx];
                if(item.attachment) {
                  hasFiles = true;
                  var attachment = item.attachment;
                  wikiSidebar.fileAdded(attachment);
                } else if(item.folder) {
                  var folder = item.folder;
                  var $folder = $("#editor_tabs_2 .tree_node_template li.folder").clone(true);
                  $folder.attr('class', 'folder')
                         .data('position', folder['position']);
                  $folder.addClass('in_sidebar_folder_' + (folder.parent_folder_id || 0));
                  $folder.fillTemplateData({
                    data: folder,
                    hrefValues: ['id'],
                    id: 'sidebar_folder_' + folder.id
                  });
                  wikiSidebar.insertSorted($folder, $tree1, 'li.folder');
                }
                ++idx;
                ++batchCount;
              }

              if (idx < data.length) {
                setTimeout(addBatch, 50);
              } else {
                processBatch(true);
              }
            };

            addBatch();
          });
        }
        $editor_tabs.show();
        $course_show_secondary.hide();
        $editor_tabs.find(".image_list img").each(function() {
          var $this = $(this),
              src = $this.attr('src');
          if(!src || src === "") {
            $this.attr('src', $this.attr('rel'));
          }
        });
      },
      hide: function() {
        $editor_tabs.removeClass('showing').hide();
        $course_show_secondary.show();
      },
      toggle: function() {
        if($editor_tabs.hasClass('showing')) {
          wikiSidebar.hide();
        } else {
          wikiSidebar.show();
        }
      },
      init: function() {
        $editor_tabs.find("#pages_accordion a.add").click(function(event){
          event.preventDefault();
          $editor_tabs.find('#new_page_drop_down').slideToggle("fast", function() {
            $(this).find(":text:visible:first").focus().select();
          });
        });

        $editor_tabs.find(".upload_new_image_link").click(function(event) {
          event.preventDefault();
          $sidebar_upload_image_form.slideToggle('fast');
        });
        $editor_tabs.find(".find_new_image_link").click(function(event) {
          event.preventDefault();
          wikiSidebar.editor.editorBox('execute', 'instructureEmbed', 'flickr');
        });
        $editor_tabs.find(".upload_new_file_link").click(function(event) {
          event.preventDefault();
          $sidebar_upload_file_form.slideToggle('fast');
        });
        //make the tabs for the right side
        $editor_tabs.tabs();
        $('.wiki_pages li a').live('click', function(event){
          event.preventDefault();
          wikiSidebar.editor.editorBox('create_link', {title: $(this).text(), url: $(this).attr('href')});
        });

        $editor_tabs.find("#pages_accordion").accordion({
          header: ".header",
          autoHeight: false
        });

        $("#new_page_drop_down").submit(function(event){
          event.preventDefault();
          var pageName = $.trim($("#new_page_name").val()).replace(/\s/g, '-').toLowerCase();
          wikiSidebar.editor.editorBox('create_link', {
            title: $("#new_page_name").val(), 
            url: $("#new_page_url_prefix").val()+ "/" + pageName
          });
          $('#new_page_drop_down').slideUp("fast");
          $("#new_page_name").val("");
        });

        $editor_tabs.find(".image_list .img_link").click(function(event) {
          event.preventDefault();
          wikiSidebar.imageSelected($(this).find(".img"));
        });
        if($.handlesHTML5Files) {
          var $wiki_sidebar_select_folder_dialog = $("#wiki_sidebar_select_folder_dialog");
          $("#editor_tabs_2 .file_list_holder").bind('dragenter dragover', function(event) {
            if(!$(this).hasClass('file_drop')) { return; }
            event.preventDefault();
            event.stopPropagation();
            $(this).addClass('file_drag');
          }, false).bind('dragleave dragout', function(event) {
            if(!$(this).hasClass('file_drop')) { return; }
            if(!$(this).closest(".file_list_holder")) {
              $(this).removeClass('file_drag');
            }
          }, false).bind('drop', function(event) {
            if(!$(this).hasClass('file_drop')) { return; }
            event.preventDefault();
            event.stopPropagation();
            $(this).removeClass('file_drag');
            var filesToUpload = [];
            var dt = event.originalEvent.dataTransfer;
            var files = dt.files;
            for(var idx = 0; idx < files.length; idx++) {
              if(files[idx]) {
                if(true) {
                  filesToUpload.push(files[idx]);
                }
              }
            }
            if(filesToUpload.length === 0) {
              alert("No valid files were selected");
              return;
            }
            var folderSelect = function(folder_id) {
              $("#wiki_sidebar_file_uploads").triggerHandler('files_added', {files: filesToUpload, folder_id: folder_id});
            };
            $wiki_sidebar_select_folder_dialog.data('folder_select', folderSelect);
            $wiki_sidebar_select_folder_dialog.find(".file_count").text(filesToUpload.length);
            $wiki_sidebar_select_folder_dialog.find(".folder_id").empty();
            $sidebar_upload_file_form.find("select.attachment_folder_id option").each(function() {
              $wiki_sidebar_select_folder_dialog.find(".folder_id").append($(this).clone());
            });
            $wiki_sidebar_select_folder_dialog.dialog('close').dialog({
              autoOpen: false,
              title: "Select folder for file uploads"
            }).dialog('open');
            return false;
          }, false);
          $wiki_sidebar_select_folder_dialog.find(".select_button").click(function(event) {  
            var folder_id = $$wiki_sidebar_select_folder_dialog.find(".folder_id").val();
            if(folder_id) {
              var callback = $wiki_sidebar_select_folder_dialog.data('folder_select');
              if(callback) {
                callback(folder_id);
              }
              $wiki_sidebar_select_folder_dialog.dialog('close');
            }
          });
          $wiki_sidebar_select_folder_dialog.find(".cancel_button").click(function(event) {
            $wiki_sidebar_select_folder_dialog.data('folder_select', null);
            $wiki_sidebar_select_folder_dialog.dialog('close');
          });

          $("#editor_tabs_3 .image_list_holder").bind('dragenter dragover', function(event) {
            if(!$(this).hasClass('file_drop')) { return; }
            event.preventDefault();
            event.stopPropagation();
            $(this).addClass('file_drag');
          }, false).bind('dragleave dragout', function(event) {
            if(!$(this).hasClass('file_drop')) { return; }
            if(!$(this).parents(".image_list_holder").length) {
              $(this).removeClass('file_drag');
            }
          }, false).bind('drop', function(event) {
            if(!$(this).hasClass('file_drop')) { return; }
            event.preventDefault();
            event.stopPropagation();
            $(this).removeClass('file_drag');
            var images = [];
            var dt = event.originalEvent.dataTransfer;
            var files = dt.files;
            for(var idx = 0; idx < files.length; idx++) {
              if(files[idx]) {
                if(!files[idx].type || files[idx].type.match(/^image/)) {
                  images.push(files[idx]);
                }
              }
            }
            if(images.length === 0) {
              alert("No valid image files were selected");
              return;
            }
            var folderSelect = function(folder_id) {
              $("#wiki_sidebar_image_uploads").triggerHandler('files_added', {files: images, folder_id: folder_id});
            };
            $wiki_sidebar_select_folder_dialog.data('folder_select', folderSelect);
            $wiki_sidebar_select_folder_dialog.find(".file_count").text(images.length);
            $wiki_sidebar_select_folder_dialog.find(".folder_id").empty();
            $sidebar_upload_file_form.find("select.attachment_folder_id option").each(function() {
              $wiki_sidebar_select_folder_dialog.find(".folder_id").append($(this).clone());
            });
            $wiki_sidebar_select_folder_dialog.dialog('close').dialog({
              autoOpen: false,
              title: "Select folder for file uploads"
            }).dialog('open');
            return false;
          }, false);
        }
        var fileUploadsFileList = [];
        var fileUploadsReady = true;
        $("#wiki_sidebar_file_uploads").bind('files_added', function(event, data) {
          for(var idx in data.files) { 
            fileUploadsFileList.push({
              file: data.files[idx],
              folder_id: data.folder_id
            });
          }
          $(this).triggerHandler('file_list_update');
        }).bind('file_list_update', function(event) {
          if(fileUploadsFileList.length === 0) {
            $(this).slideUp();
          } else {
            $(this).triggerHandler('file_upload_check').slideDown();
          }
        }).bind('file_upload_check', function(event) {
          var $list = $(this);
          if(fileUploadsReady) {
            var fileWrapper = fileUploadsFileList.shift();
            var fileData = $.fileData(fileWrapper.file);
            $list.fillTemplateData({data: {filename: fileData.name, files_remaining: fileUploadsFileList.length}});
            fileUploadsReady = false;
            $.ajaxFileUpload({
              url: $sidebar_upload_file_form.attr('action'),
              data: {
                'attachment[uploaded_data]': fileWrapper.file,
                'attachment[display_name]': fileData.name,
                'attachment[folder_id]': fileWrapper.folder_id
              },
              method: 'POST',
              success: function(data) {
                wikiSidebar.fileAdded(data.attachment, true);
                fileUploadsReady = true;
                $list.triggerHandler('file_list_update');
              },
              progress: function(data) {
                console.log('progress!');
              },
              error: function(data) {
                $.flashError('Unexpected problem uploading ' + fileData.name + '.  Please try again.');
                $list.triggerHandler('file_list_update');
                fileUploadsReady = true;
              }
            });
            if(fileUploadsFileList.length === 0) {
              $list.find(".remaining").slideUp();
            }
          } else {
            $list.fillTemplateData({data: {files_remaining: fileUploadsFileList.length}});
          }
        });

        var imageUploadsFileList = [];
        var imageUploadsReady = true;
        $("#wiki_sidebar_image_uploads").bind('files_added', function(event, data) {
          for(var idx in data.files) { 
            imageUploadsFileList.push({
              file: data.files[idx],
              folder_id: data.folder_id
            });
          }
          $(this).triggerHandler('file_list_update');
        }).bind('file_list_update', function(event) {
          if(!imageUploadsFileList.length) {
            $(this).slideUp();
          } else {
            $(this).triggerHandler('file_upload_check').slideDown();
          }
        }).bind('file_upload_check', function(event) {
          var $list = $(this);
          if(imageUploadsReady) {
            var fileWrapper = imageUploadsFileList.shift();
            var fileData = $.fileData(fileWrapper.file);
            $list.fillTemplateData({data: {filename: fileData.name, files_remaining: imageUploadsFileList.length}});
            imageUploadsReady = false;
            $.ajaxFileUpload({
              url: $sidebar_upload_image_form.attr('action'),
              data: {
                'attachment[uploaded_data]': fileWrapper.file,
                'attachment[display_name]': fileData.name,
                'attachment[folder_id]': fileWrapper.folder_id
              },
              method: 'POST',
              success: function(data) {
                wikiSidebar.fileAdded(data.attachment, true);
                imageUploadsReady = true;
                $list.triggerHandler('file_list_update');
              },
              progress: function(data) {
                console.log('progress!');
              },
              error: function(data) {
                $.flashError('Unexpected problem uploading ' + fileData.name + '.  Please try again.');
                $list.triggerHandler('file_list_update');
                imageUploadsReady = true;
              }
            });
            if(imageUploadsFileList.length === 0) {
              $list.find(".remaining").slideUp();
            }
          } else {
            $list.fillTemplateData({data: {files_remaining: imageUploadsFileList.length}});
          }
        });
        $sidebar_upload_image_form.formSubmit({
          fileUpload: true,
          object_name: 'attachment',
          processData: function(data) {
            data['attachment[display_name]'] = $(this).find(".file_name").val();
            return data;
          },
          beforeSubmit: function(data) {
            $sidebar_upload_image_form.find(".uploading").slideDown();
            $sidebar_upload_image_form.attr('action', $sidebar_upload_image_form.find(".json_upload_url").attr('href'));
          },
          success: function(data) {

            $sidebar_upload_image_form.slideUp(function() {
              $sidebar_upload_image_form.find(".uploading").hide();
            });
            var attachment = data.attachment,
                url = $.replaceTags($(this).find(".file_url").attr('href'), 'id', attachment.id);
            var $img = $editor_tabs.find(".image_list .img_link:last")
              .find(".img")
                .attr({'src': attachment.thumbnail_url || url, 'alt': attachment.display_name})
                .data('url', url).end()
              .fillTemplateData({data: attachment})
              .prependTo($editor_tabs.find(".image_list"));
            $img.slideDown(function() {
              wikiSidebar.imageSelected($img.find(".img"));
            });
          },
          error: function(data) {
            $sidebar_upload_image_form.find(".uploading").slideUp();
          }
        });
        $sidebar_upload_file_form.formSubmit({
          fileUpload: true,
          object_name: 'attachment',
          processData: function(data) {
            data['attachment[display_name]'] = $sidebar_upload_file_form.find(".file_name").val();
            return data;
          },
          beforeSubmit: function(data) {
            $sidebar_upload_file_form.find(".uploading").slideDown();
            $sidebar_upload_file_form.attr('action', $sidebar_upload_file_form.find(".json_upload_url").attr('href'));
          },
          success: function(data) {
            $sidebar_upload_file_form.slideUp(function() {
              $sidebar_upload_file_form.find(".uploading").hide();
            });
            var attachment = data.attachment;
            var $attachment = $editor_tabs.find(".tree_node_template #attachment_blank").clone(true).removeAttr('id');
            attachment.name = attachment.display_name;
            $attachment.fillTemplateData({
              data: attachment,
              id: 'attachment_' + attachment.id
            });
            $attachment
              .addClass('leaf '+ attachment.content_type)
              .find(".name")
                .addClass('text')
                .toggleClass('scribdable', attachment['scribdable?']);
            if(attachment.media_entry_id) {
              $attachment
                .addClass('kalturable' + (attachment.content_type && attachment.content_type.match(/video/) ? 'video_playback' : 'audio_playback'))
                .attr('data-media-entry-id', attachment.media_entry_id);;
            }
            if(attachment.content_type.match(/image/)) {
              $attachment.addClass('image');
            }
            $attachment.children(".name").attr('rel', $.replaceTags($attachment.children(".name").attr('rel'), 'id', attachment.id));
            var $folder = $tree1.find("#sidebar_folder_" + attachment.folder_id);
            if(!$folder.length) {
              $folder = $tree1.find("li.folder:visible:first");
            }
            $folder.children("ul")
              .children("li.last").removeClass('last').end()
              .append("<li class='separator'></li>").append($attachment);
            $attachment
              .addClass('last')
              .addClass('leaf')
              .toggleClass('scribdable', attachment['scribdable?'])
              .hide()
              .slideDown();
            wikiSidebar.fileSelected($attachment);
          },
          error: function(data) {
            $sidebar_upload_file_form.find(".uploading").slideUp();
          }
        });
      },
      attachToEditor: function($editor) {
        wikiSidebar.editor = $($editor);
      }
    };
  });

})(window, window.jQuery);
