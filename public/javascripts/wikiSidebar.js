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
  'i18n!wiki.sidebar',
  'jquery' /* $ */,
  'str/htmlEscape',
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.inst_tree' /* instTree */,
  'jquery.instructure_forms' /* formSubmit, handlesHTML5Files, ajaxFileUpload, fileData */,
  'jqueryui/dialog',
  'jquery.instructure_misc_helpers' /* replaceTags */,
  'jquery.instructure_misc_plugins' /* /\.log\(/ */,
  'compiled/jquery.rails_flash_notifications',
  'jquery.templateData' /* fillTemplateData */,
  'tinymce.editor_box',
  'vendor/jquery.pageless' /* pageless */,
  'jqueryui/accordion' /* /\.accordion\(/ */,
  'jqueryui/tabs' /* /\.tabs/ */,
  'vendor/scribd.view' /* scribd */
], function(I18n, $, htmlEscape) {

  var $editor_tabs,
      $tree1,
      $image_list,
      $course_show_secondary,
      $sidebar_upload_image_form,
      $sidebar_upload_file_form,
      $wiki_sidebar_select_folder_dialog,
      treeItemCount=0;

  // unlikely, but there's a chance this domready call will happen after other
  // scripts try to call methods on wikiSidebar, need to re-architect this a bit
  $(function(){
    $editor_tabs = $("#editor_tabs");
    $tree1 = $editor_tabs.find('ul#tree1');
    $image_list = $editor_tabs.find('#editor_tabs_4 .image_list');
    $course_show_secondary = $("#course_show_secondary");
    $sidebar_upload_image_form = $("form#sidebar_upload_image_form");
    $sidebar_upload_file_form = $("form#sidebar_upload_file_form");
    $wiki_sidebar_select_folder_dialog = $("#wiki_sidebar_select_folder_dialog");
  });

  var wikiSidebar = {
    // Generate a new tree item id. Type can be either 'file' or 'folder'
    generateTreeItemID: function(type) {
      var id = type + "_" + treeItemCount;
      treeItemCount++;

      return id;
    },
    itemSelected: function(item) {
      switch(item.item_type) {
        case 'image':
          wikiSidebar.editor.editorBox('insert_code', '<img alt="' + item.title + '" src="' + item.link_url + '"/>');
          break;
        default: // we'll rely on enhance-user-content to create youtube thumbnails, etc.
          wikiSidebar.editor.editorBox('create_link', {title: (item.title || I18n.t("no_title", "No title")), url: item.link_url});
          break;
      }
    },
    fileSelected: function(node) {
      var $span = node.find('span.text'),
          url = $span.attr('rel');

      // Remove the screenreader only from the text
      var title = $span.clone();
      title.find('.screenreader-only').remove()
      title = title.text();

      wikiSidebar.editor.editorBox('create_link', {title: title , url: url, file: true, image: node.hasClass('image'), scribdable: node.hasClass('scribdable'), kaltura_entry_id: node.attr('data-media-entry-id'), kaltura_media_type: node.hasClass('video_playback') ? 'video' : 'audio'});
    },
    imageSelected: function($img) {
      var src = $img.data('url') || $img.attr('src'),
          alt = $img.attr('alt');
      wikiSidebar.editor.editorBox('insert_code', '<img alt="'+alt+'" src="'+src+'"/>');
    },
    fileAdded: function(attachment, newUploadOrCallbackOrParent, fileCallback) {
      var children, newUpload, imageCallback, $file;
      if($.isFunction(newUploadOrCallbackOrParent)) {
        newUpload = true;
        imageCallback = newUploadOrCallbackOrParent;
      } else if(typeof newUploadOrCallbackOrParent == "object") {
        children = newUploadOrCallbackOrParent;
      } else {
        newUpload = newUploadOrCallbackOrParent;
      }
      if(children == null) {
        children = $tree1.find('.initialized.folder_' + attachment.folder_id + '>ul');
      }
      if(children.length || fileCallback) {
        var file = attachment;
        var displayName = "<span class='screenreader-only'>" + htmlEscape(file.display_name) + " " + I18n.t('aria_tree.file', 'file') + "</span>" + htmlEscape(file.display_name);

        $file = $tree1.find(".file_blank").clone(true);
        $file
          .attr('class', 'file')
          .attr('title', file.display_name)
          .attr('data-tooltip', '')
          .attr('aria-level', children.data('level'))
          .attr('id', this.generateTreeItemID('file'))
          .addClass(file.mime_class)
          .toggleClass('scribdable', file['scribdable?']);
        if(file.media_entry_id) {
          $file
            .addClass('kalturable')
            .attr('data-media-entry-id', file.media_entry_id)
            .addClass(file.content_type && file.content_type.match(/video/) ? 'video_playback' : 'audio_playback');
        }
        file.name = displayName;
        $file.fillTemplateData({
          data: file,
          hrefValues: ['id'],
          htmlValues: ['name']
        });
        if (children) {
          children.append($file);
          $file.show();
          $tree1.instTree.InitInstTree($tree1);
        }
        if (fileCallback) {
          fileCallback($file);
        }
      }
      if(newUpload && (attachment.mime_class == 'image' || attachment.content_type.match(/^image/)) &&
        $image_list.hasClass('initialized')) {
        var url = $.replaceTags($("#editor_tabs_4 .file_url").attr('href'), 'id', attachment.id);
        var $img = $editor_tabs.find("#wiki_sidebar_image_uploads .img_link").clone();
        $img.find(".img")
            .attr({'src': attachment.thumbnail_url || url, 'alt': attachment.display_name})
            .data('url', url).end()
          .fillTemplateData({data: attachment})
          .prependTo($image_list);
        if (imageCallback) {
          $img.slideDown(imageCallback);
        } else {
          $img.slideDown();
        }
      }
    },
    show: function() {
      $editor_tabs.addClass('showing');
      $editor_tabs.show();
      $course_show_secondary.hide();
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
    loadFolder: function(node) {
      node.data('includes_files', true);
      var url = $.replaceTags($("#editor_tabs_3 #folder_url").attr('href'), 'id', node.data('id'));
      $loading = $tree1.find(">.loading").clone();
      $loading.show();
      node.append($loading);
      $.ajaxJSON(url, 'GET', {}, function(data) {
        $loading.remove();
        var children = node.find('ul');
        // Update folder level for accessiblity
        children.data('level', children.parents('ul:first').data('level') + 1);

        for(var idx in data.sub_folders) {
          var folder = data.sub_folders[idx].folder;
          var $folder = $tree1.find(".folder_blank").clone(true);
          $folder.attr('class', 'folder').data('id', folder.id).addClass('folder_' + folder.id);
          $folder.find('.name').html(" <span class='screenreader-only'>" + htmlEscape(folder.name) + " " + I18n.t('aria_tree.folder', 'folder') + "</span>" + htmlEscape(folder.name) );
          $folder.attr('aria-level', children.data('level'))
                 .attr('id', wikiSidebar.generateTreeItemID('folder'));
          children.append($folder);
          $folder.show();
        }
        for(var idx in data.files) {
          wikiSidebar.fileAdded(data.files[idx].attachment, children);
        }
        node.addClass('initialized');
        $tree1.instTree.InitInstTree($tree1);
      }, function() {
        $loading.remove();
      });
    },
    addFolder: function(folders, id, depth) {
      var folder = folders[id];
      // The root folder was loaded in the initial request
      if(depth != 0) {
        var name = htmlEscape(folder.name);
        name = '- ' + name;
        if(name.length + depth + 1 > 38) {
          name = name.substring(0, 35) + '...';
        }
        for(var idx = 0; idx < depth; idx++) {
          name = "&nbsp;&nbsp;" + name;
        }
        var $option = $("<option />");
        $option.val(folder.id);
        $option.html(name);
        $sidebar_upload_file_form.find('#attachment_folder_id').append($option.clone());
        $sidebar_upload_image_form.find('#image_folder_id').append($option.clone());
        $wiki_sidebar_select_folder_dialog.find('.folder_id').append($option.clone());
      }
      for(var idx in folder.sub_folders) {
        wikiSidebar.addFolder(folders, folder.sub_folders[idx], depth + 1);
      }
    },
    loadFolders: function() {
      if(!$sidebar_upload_file_form.hasClass('initialized')){
        $sidebar_upload_file_form.addClass('initialized');
        var url = $sidebar_upload_file_form.find(".json_upload_url").attr('href');
        $.ajaxJSON(url, 'GET', {}, function(data) {
          var folders = {}
          var root_folder_id;
          for(var idx in data.folders) {
            var folder = data.folders[idx].folder;
            if(!folders[folder.id]) {
              folders[folder.id] = folder;
            }
            if(!folder.parent_folder_id) {
              root_folder_id = folder.id;
              continue;
            }
            if(!folders[folder.parent_folder_id]) {
              folders[folder.parent_folder_id] = {};
            }
            if(!folders[folder.parent_folder_id].sub_folders) {
              folders[folder.parent_folder_id].sub_folders = [];
            }
            folders[folder.parent_folder_id].sub_folders.push(folder.id);
          }
          wikiSidebar.addFolder(folders, root_folder_id, 0);
        });
      }
    },
    init: function() {
      wikiSidebar.inited = true;

      $editor_tabs.find("#pages_accordion a.add").click(function(event){
        event.preventDefault();
        $editor_tabs.find('#new_page_drop_down').slideToggle("fast", function() {
          $(this).find(":text:visible:first").focus().select();
        });
      });

      $editor_tabs.find(".upload_new_image_link").click(function(event) {
        event.preventDefault();
        wikiSidebar.loadFolders();
        $sidebar_upload_image_form.slideToggle('fast', function(){
          var $imageForm = $('#sidebar_upload_image_form');
          if($imageForm.is(":visible")){
            $imageForm.find('select').first().focus();
            $(event.currentTarget).attr('aria-label', I18n.t('image_form.expanded', 'Click to toggle the new image form (expanded)'));
          }else{
            $(event.currentTarget).attr('aria-label', I18n.t('image_form.collapsed', 'Click to toggle the new image form (collapsed)'));
          }
        });
      });
      $editor_tabs.find(".find_new_image_link").click(function(event) {
        event.preventDefault();
        wikiSidebar.editor.editorBox('execute', 'instructureEmbed', 'flickr');
      });
      $editor_tabs.find(".upload_new_file_link").click(function(event) {
        event.preventDefault();
        wikiSidebar.loadFolders();
        $sidebar_upload_file_form.slideToggle('fast');
      });
      //make the tabs for the right side

      $editor_tabs.bind( "tabsshow tagselect", function(event, ui) {
        // defer loading everything in the "files" tree until we click on that tab
        if (ui.panel.id === 'editor_tabs_3' && !$tree1.hasClass('initialized')) {
          $tree1.addClass('initialized unstyled_list');
          $tree1.instTree({
            multi: false,
            dragdrop: false,
            onExpand: function(node) {
              if(node.hasClass('folder') && !node.data('includes_files')) {
                wikiSidebar.loadFolder(node);
              }
            },
            onClick: function (event,node) {
              if (node.hasClass('leaf') || node.hasClass('file')) {
                wikiSidebar.fileSelected(node);
              } else if (node.hasClass('node')) {
                node.children('.sign').click();
              }
            },
            onEnter: function (event, node){
              if (node.hasClass('leaf') || node.hasClass('file')) {
                wikiSidebar.fileSelected(node);
              } else if (node.hasClass('node')) {
                node.children('.sign').click();
              }
            }
          });

          $node = $tree1.find('.folder').first();
          $tree1.attr('aria-activedescendant', $node.attr('id'));
          $tree1.find('[aria-selected="true"]').attr('aria-selected', 'false');
          $node.attr('aria-selected', 'true');

        }
        // defer setting up the <img>es until we click the "images" tab
        if (ui.panel.id === 'editor_tabs_4' && !$image_list.hasClass('initialized')) {
          $image_list.addClass('initialized')
          $image_list.pageless({
            container: $image_list,
            currentPage: 0,
            totalPages: 1,
            distance: 500,
            url: $image_list.data('url'),
            loaderMsg: I18n.t('loading_more_results', "Loading more results"),
            scrape: function(data, xhr) {
              this.totalPages = parseInt(xhr.getResponseHeader('X-Total-Pages'));
              return data;
            }
          });
        }
      });

      $editor_tabs.tabs();

      $('.wiki_pages li a').live('click', function(event){
        event.preventDefault();
        wikiSidebar.editor.editorBox('create_link', {title: $(this).text(), url: $(this).attr('href')});
      });

      $editor_tabs.find("#pages_accordion").accordion({
        header: ".header",
        autoHeight: false,
        heightStyle: 'content'
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

      $image_list.delegate('.img_link', 'click', function(event) {
        event.preventDefault();
        wikiSidebar.imageSelected($(this).find(".img"));
      });
      if($.handlesHTML5Files) {
        $("#editor_tabs_3 .file_list_holder").bind('dragenter dragover', function(event) {
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
            alert(I18n.t('errors.no_valid_files_selected', "No valid files were selected"));
            return;
          }
          var folderSelect = function(folder_id) {
            $("#wiki_sidebar_file_uploads").triggerHandler('files_added', {files: filesToUpload, folder_id: folder_id});
          };
          $wiki_sidebar_select_folder_dialog.data('folder_select', folderSelect);
          $wiki_sidebar_select_folder_dialog.find(".file_count").text(filesToUpload.length);
          $wiki_sidebar_select_folder_dialog.find(".folder_id").empty();
          wikiSidebar.loadFolders();
          $wiki_sidebar_select_folder_dialog.dialog({
            title: I18n.t('titles.select_folder_for_uploads', "Select folder for file uploads")
          });
          return false;
        }, false);
        $wiki_sidebar_select_folder_dialog.find(".select_button").click(function(event) {
          var folder_id = $wiki_sidebar_select_folder_dialog.find(".folder_id").val();
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

        $("#editor_tabs_4 .image_list_holder").bind('dragenter dragover', function(event) {
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
            alert(I18n.t('errors.no_valid_image_files_selected', "No valid image files were selected"));
            return;
          }
          var folderSelect = function(folder_id) {
            $("#wiki_sidebar_image_uploads").triggerHandler('files_added', {files: images, folder_id: folder_id});
          };
          $wiki_sidebar_select_folder_dialog.data('folder_select', folderSelect);
          $wiki_sidebar_select_folder_dialog.find(".file_count").text(images.length);
          $wiki_sidebar_select_folder_dialog.find(".folder_id").empty();
          wikiSidebar.loadFolders();
          $wiki_sidebar_select_folder_dialog.dialog({
            title: I18n.t('titles.select_folder_for_uploads', "Select folder for file uploads")
          });
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
          $(this).triggerHandler('file_upload_check');
          $(this).slideDown();
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
              $.flashError(I18n.t('errors.unexpected_upload_problem', 'Unexpected problem uploading %{filename}.  Please try again.', {filename: fileData.name}));
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
          $(this).triggerHandler('file_upload_check');
          $(this).slideDown();
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
              $.flashError(I18n.t('errors.unexpected_upload_problem', 'Unexpected problem uploading %{filename}.  Please try again.', {filename: fileData.name}));
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
        preparedFileUpload: true,
        singleFile: true,
        context_code: $("#editor_tabs .context_code").text(),
        folder_id: function() {
          return $(this).find("[name='attachment[folder_id]']").val();
        },
        upload_only: true,
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
          wikiSidebar.fileAdded(data.attachment, function() {
            wikiSidebar.imageSelected($(this).find(".img"));
          });
        },
        error: function(data) {
          $sidebar_upload_image_form.find(".uploading").slideUp();
        }
      });
      $sidebar_upload_file_form.formSubmit({
        fileUpload: true,
        preparedFileUpload: true,
        singleFile: true,
        object_name: 'attachment',
        context_code: $("#editor_tabs .context_code").text(),
        folder_id: function() {
          return $(this).find("[name='attachment[folder_id]']").val();
        },
        upload_only: true,
        processData: function(data) {
          data['attachment[display_name]'] = $sidebar_upload_file_form.find(".file_name").val();
          return data;
        },
        beforeSubmit: function(data) {
          $sidebar_upload_file_form.find(".uploading").slideDown();
          $sidebar_upload_file_form.attr('action', $sidebar_upload_file_form.find(".json_upload_url").attr('href'));
          $(this).find("button").attr('disabled', true).text(I18n.t('buttons.uploading', "Uploading..."));
        },
        success: function(data) {
          $(this).find("button").attr('disabled', false).text("Upload");
          $sidebar_upload_file_form.slideUp(function() {
            $sidebar_upload_file_form.find(".uploading").hide();
          });
          wikiSidebar.fileAdded(data.attachment, true, function(node) {
            wikiSidebar.fileSelected(node);
          });
        },
        error: function(data) {
          $(this).find("button").attr('disabled', false).text(I18n.t('errors.upload_failed', "Upload Failed, please try again"));
          $sidebar_upload_file_form.find(".uploading").slideUp();
        }
      });
    },
    attachToEditor: function($editor) {
      wikiSidebar.editor = $($editor);
      return wikiSidebar;
    }
  };

  return wikiSidebar;
});

