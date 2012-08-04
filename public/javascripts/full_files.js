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
  'INST' /* INST */,
  'i18n!files',
  'jquery' /* jQuery, $ */,
  'str/htmlEscape',
  'jqueryui/draggable' /* /\.draggable/ */,
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.doc_previews' /* loadDocPreview */,
  'jquery.inst_tree' /* instTree */,
  'jquery.instructure_date_and_time' /* parseFromISO */,
  'jquery.instructure_forms' /* formSubmit, handlesHTML5Files, ajaxFileUpload, fileData, fillFormData, formErrors */,
  'jqueryui/dialog',
  'jquery.instructure_misc_helpers' /* replaceTags, /\$\.underscore/ */,
  'jquery.instructure_misc_plugins' /* confirmDelete, fragmentChange, showIf */,
  'jquery.keycodes' /* keycodes */,
  'jquery.loadingImg' /* loadingImage */,
  'jquery.scrollToVisible' /* scrollToVisible */,
  'jquery.templateData' /* fillTemplateData, getTemplateData */,
  'media_comments' /* mediaComment */,
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */,
  'jqueryui/droppable' /* /\.droppable/ */,
  'jqueryui/progressbar' /* /\.progressbar/ */,
  'jqueryui/sortable' /* /\.sortable/ */,
  'vendor/scribd.view' /* scribd */
], function(INST, I18n, $, htmlEscape) {

  var files = {};
  var fileStructureData = [];
  (function() {
    var $files_content = $("#files_content"),
      $swfupload_holder = $("#swfupload_holder"),
      $add_file_link = $("#add_file_link"),
      $files_structure = $("#files_structure"),
      $files_structure_list = $("#files_structure_list");
    $.extend(files, {
      canManageAContext: false,
      init: function() {
        // Re-initialize common finds, just in case
        $files_content = $("#files_content");
        $swfupload_holder = $("#swfupload_holder");
        $add_file_link = $("#add_file_link");
        $files_structure = $("#files_structure");
        $files_structure_list = $("#files_structure_list");
        $files_content.prepend($swfupload_holder);
        files.clearDataCache.cacheIndex = 0;
        for(var idx in contexts) {
          var obj = {
            context: contexts[idx],
            context_name: contexts[idx].name,
            context_string: contexts[idx].asset_string
          };
          if(contexts[idx].asset_string) {
            var context_type = contexts[idx].asset_string.replace(/_\d+$/, '');
            obj[context_type] = contexts[idx];
          }
          fileStructureData.push([
            obj, {}
          ]);
        }
        for(var idx in fileStructureData) {
          if(fileStructureData[idx]) {
            var context = fileStructureData[idx][0];
            var context_type = null;
            var context_name = null;
            var context_object = null;
            for(var jdx in context) {
              if(context[jdx] && jdx != "context_string" && jdx != "context_name" && jdx != 'context') {
                context_type = jdx;
                context_name = context[jdx].name;
                context_object = context[jdx];
              }
            }
            fileStructureData[idx][0].context_string = context_type + "_" + context[context_type].id;
            fileStructureData[idx][0].context_name = context_name;
            fileStructureData[idx][0].context = context_object;
            if(context_object && context_object.permissions && context_object.permissions.manage_files) {
              files.canManageAContext = true;
            }
          }
        }
        $files_content.append($("#drag_n_drop_panel"));
        $files_content.append($("#content_templates .content_panel").hide());

        if($.handlesHTML5Files) {
          $files_content.bind('dragenter dragover', function(event) {
            event.preventDefault();
            event.stopPropagation();
            var folder = files.currentItemData();
            if(!folder || folder.mime_class != 'folder') { return; }
            $(this).addClass('file_drag');
            $("#drag_n_drop_panel").css('top', $files_content.scrollTop());
          }).bind('dragleave dragout', function(event) {
            if(!$(this).closest(".drag_panel").length) {
              $(this).removeClass('file_drag');
            }
          }).bind('drop', function(event) {
            var dt = event.originalEvent.dataTransfer;
            if (dt) {
              var folder = files.currentItemData();
              event.preventDefault();
              event.stopPropagation();
              $(this).removeClass('file_drag');
              if(!folder || folder.mime_class != 'folder') { return; }
              var filesToUpload = [];
              var filesList = dt.files;
              for(var idx = 0; idx < filesList.length; idx++) {
                if(filesList[idx] && filesList[idx].size > 0) {
                  if(true) {
                    filesToUpload.push(filesList[idx]);
                  }
                }
              }
              if(filesToUpload.length === 0) {
                alert(I18n.t('messages.no_files_selected', "No valid files were selected"));
                return;
              }
              var unzip = false;
              if(filesToUpload.length == 1 && filesToUpload[0].type.match(/application\/(x-)?zip/)) {
                unzip = confirm(I18n.t('prompts.extract_zip', "This file is a zip file.  Do you want to extract its contents into this folder?"));
              }
              if(unzip) {
                var file = filesToUpload[0];
                folder.context_string;
                var url = $("." + folder.context_string + "_zip_import_url").attr('href');
                var params = {
                  'folder_id': folder.id,
                  'zip_file': filesToUpload[0],
                  'format': 'json'
                };
                var import_id = null;
                
                var $dialog = $("<div/>");
                $dialog.append("Uploading and extracting <b>" + htmlEscape(file.name) + "</b><br/>to " + htmlEscape(folder.name) + "...");
                $dialog.append("<div class='progress'/>");
                var $progress = $dialog.find(".progress");
                $progress.css('margin', '10px');
                $progress.progressbar();
                $dialog.dialog('close').dialog({
                  autoOpen: false,
                  title: I18n.t('titles.extracting', "Extracting Files into Folder"),
                  close: function() {
                    $dialog.data('closed', true);
                    setTimeout(function() {
                      $dialog.detach();
                    }, 500);
                  }
                }).dialog('open');
                
                var importFailed = function(errors) {
                  $dialog.text(I18n.t('errors.extracting', "There were errors extracting the zip file.  Please try again."));
                  var $ul = $("<ul/>");
                  for(var idx in errors) {
                    var error = errors[idx];
                    var $li = $("<li/>");
                    $li.text(error);
                    $ul.append($li);
                  }
                  $dialog.append($ul);
                };
                var pollImport = function(zip_import_id) {
                  var pollUrl = $("#file_context_links ." + folder.context_string + "_zip_import_status_url").attr('href');
                  pollUrl = $.replaceTags(pollUrl, 'id', zip_import_id);
                  $.ajaxJSON(pollUrl, 'GET', {}, function(data) {
                    var zfi = data.zip_file_import;
                    if($dialog.data('closed')) { return; }
                    if(zfi && zfi.data && zfi.data.errors) {
                      importFailed(zfi.data.errors);
                    } else if(zfi && zfi.workflow_state == 'imported') {
                      $progress.progressbar('value', 100);
                      $dialog.append(I18n.t('messages.extraction_complete', "Extraction complete!  Updating..."));
                      files.refreshContext(folder.context_string, function() {
                        $dialog.dialog('close');
                      });
                    } else if(!zfi) {
                      pollImport.blankCount = pollImport.blankCount || 0;
                      pollImport.blankCount++;
                      if(pollImport.blankCount > 30) {
                        importFailed([I18n.t('errors.server_returned_invalid_status', "The server stopped returning a valid status")]);
                      } else {
                        setTimeout(function() { pollImport(zip_import_id) }, 2000);
                      }
                    } else if (zfi && zfi.workflow_state == 'failed') {
                      importFailed([]);
                    } else {
                      pollImport.errorCount = 0;
                      setTimeout(function() { pollImport(zip_import_id) }, 2000);
                      $progress.progressbar('value', ((zfi.progress || 0) * 100));
                    }
                  }, function(data) {
                    pollImport.errorCount = pollImport.errorCount || 0;
                    pollImport.errorCount++;
                    if(pollImport.errorCount > 5) {
                      importFailed([I18n.t('errors.server_unresponsive', "The server stopped responding to status requests")]);
                    } else {
                      setTimeout(function() { pollImport(zip_import_id) }, 2000);
                    }
                  });
                };
                $.ajaxFileUpload({
                  url: url,
                  data: params,
                  method: 'POST',
                  success: function(data) {
                    zip_import_id = data.zip_file_import.id;
                    pollImport(zip_import_id);
                  },
                  error: function(data) {
                    $dialog.text(I18n.t('errors.uploading_zip', "There were errors uploading the zip file."));
                  }
                });
              } else {
                var folder = files.currentItemData();
                var filenames = [];
                for (idx in filesToUpload) {
                  filenames.push(filesToUpload[idx].name);
                }
                files.preflight(folder.id, folder.context_string, filenames,
                  function(duplicate_handling_method) { // onChooseDuplicateHandler
                    for (idx in filesToUpload) {
                      filesToUpload[idx].duplicate_handling = duplicate_handling_method;
                    }
                  },
                  function() { // onSuccess
                    for(var idx in filesToUpload) {
                      fileUpload.queueAjaxUpload(filesToUpload[idx]);
                    }
                  },
                  function() { // onCancel
                  });
              }
              return false;
            }
          });
        }
      },
      preflight: function(folder_id, folder_context_string, filenames, on_choose, on_success, on_cancel) {
        var params = {
          'folder_id': folder_id,
          'context_code': folder_context_string,
          'filenames': filenames
        };
        $.ajaxJSON('/files/preflight', 'GET', params, function(data) {
          if (data.duplicates && data.duplicates.length > 0) {
            var $dialog = $("#duplicate_filename_dialog");
            $dialog.find(".duplicate_filename_prompt").text(
              I18n.t('prompts.duplicate_filenames', "Files with the following names already exist in this folder. Do you want to replace them, or rename the new files with unique names?"));
            var duplicatesHtml = '';
            for (idx in data.duplicates) {
              duplicatesHtml += "<span class='duplicate_filename'>" + htmlEscape(data.duplicates[idx]) + "</span>";
            }
            $dialog.find(".duplicate_filenames").html(duplicatesHtml);
            $dialog.dialog('close').dialog({
              autoOpen: false,
              title: '',
              width: 500
            }).dialog('open');
            $dialog.find("button").unbind('click');
            $dialog.find(".cancel_button").click(function() {
              on_cancel();
              $dialog.dialog('close');
            });
            $dialog.find(".rename_button").click(function() {
              on_choose('rename');
              on_success();
              $dialog.dialog('close');
            });
            $dialog.find(".overwrite_button").click(function() {
              on_choose('overwrite');
              on_success();
              $dialog.dialog('close');
            });
          } else {
            on_success();
          }
        }, function(data) {
          on_cancel();
        });
      },
      context_page_view_ids: {},
      updatePageView: function(context_string) {
        return;
        // I'm thinking we won't track these as page views after all... I mean,
        // what value is there in knowing the student looked at the file browser,
        // we just care if they access files.
      },
      viewFile: function(context_string, id) {
        var url = $("#file_context_links ." + context_string + "_inline_view_attachment_url").attr('href');
        url = $.replaceTags(url, 'id', id);
        $.ajaxJSON(url, 'POST', {}, function() { }, function() { });
      },
      selectFolder: function($original_node) {
        if(!files.selectFolder.forceRefresh && ($original_node.hasClass('active-node') || $original_node.hasClass('active-leaf'))) { return; }
        files.selectFolder.forceRefresh = false;
        var $node = $original_node;
        while($node.parent("ul").parent("li").length > 0) {
          $node = $node.parent("ul").parent("li");
          files.expandFolder($node);
        }
        $original_node.children('.text:visible:first').click();
        if($files_structure.find("li.node.active-node,li.leaf.active-leaf").length === 0) {
          $files_structure.find("li.node:visible:first").children(".text:visible:first").click();
        }
        if(!files.currentItemData()) {
          setTimeout(function() {
            files.selectFolder($original_node);
          }, 250);
          return;
        }
        if(!files.currentItemData().includes_files && files.currentItemData().full_name) {
          files.getFilesForFolder(files.currentItemData());
        }
      },
      deleteAttachmentIds: function(ids) {
        for(var idx in ids) {
          var id = ids[idx];
          var $file = $("#files_structure .file_" + id)
          $file.prev("li.separator").remove();
          $file.remove();
          files.refreshView();
          files.updateQuota();
        }
      },
      gettingFiles: {},
      getFilesForFolder: function(original_folder, refresh) {
        var key = original_folder.context_string + "_" + original_folder.id;
        if(files.gettingFiles[key]) { return; }
        var $folder = $files_structure.find("li.folder_" + original_folder.id);
        if($folder.hasClass('folder_locked') && (!original_folder.context || !original_folder.context.permissions || !original_folder.context.permissions.manage_files)) {
          return;
        }
        if(original_folder.false_folder) {
          files.refreshContext(original_folder.context_string, function() {
            files.getFilesForFolder(original_folder, refresh);
          });
          return;
        }
        files.gettingFiles[key] = true;
        var url = $.replaceTags($("#file_context_links ." + original_folder.context_string + "_folder_url").attr('href'), 'id', original_folder.id);
        $.ajaxJSON(url, 'GET', {}, function(data) {
          files.gettingFiles[key] = false;
          var folder = data.actual_folder.folder;
          folder.includes_files = true;
          files.updateFolder(original_folder.context_string, {folder: folder, already_in_place: true}, false);
          for(var idx in data.files) {
            var file = data.files[idx].attachment;
            if(file) {
              files.updateFile(original_folder.context_string, {attachment: file, definitely_new: true}, false);
            }
          }
          $files_structure.find(".folder_" + folder.id).triggerHandler('files_load');
          var needsRefreshing = $files_content.find(".message.no_content:visible").length > 0;
          if(refresh !== false || needsRefreshing) {
            if(refresh && $.isFunction(refresh)) {
              refresh(data);
            } else {
              files.refreshView();
            }
          }
          $add_file_link.triggerHandler('show');
        }, function(data) {
          files.gettingFiles[key] = false;
        });
      },
      expandFolder: function($node) {
        $files_structure_list[0] && $files_structure_list[0].ExpandNode && $files_structure_list[0].ExpandNode($("#files_structure_list"), $node);
      },
      collapseFolder: function($node) {
        $files_structure_list[0] && $files_structure_list[0].CollapseNode && $files_structure_list[0].CollapseNode($("#files_structure_list"), $node);
      },
      fullPath: function($node) {
        var names = [];
        var data = files.itemData($node);
        names.unshift(data.name.replace(/\//g, "//"));
        while($node.parent("ul").parent("li").length > 0) {
          $node = $node.parent("ul").parent("li");
          data = files.itemData($node);
          names.unshift(data.name.replace(/\//g, "//"));
        }
        return names.join('/');
      },
      selectNodeFromPath: function(path) {
        var $node = files.nodeFromPath(path);
        files.selectFolder($node);
        var files_load = function() {
          $node.unbind('files_load', files_load);
          if($node.hasClass('active-node')) {
            files.selectNodeFromPath(path);
          }
        };
        $node.bind('files_load', files_load);
        if($files_structure.find(".node.active-node,.leaf.active-leaf").length === 0) {
          files.selectFolder($files_structure.find(".node:visible:first"));
        }
      },
      nodeFromPath: function(path) {
        try {
          if($files_structure.find("#files_structure_list > li." + path).length > 0) {
            return $files_structure.find("#files_structure_list > li." + path);
          }
        } catch(e) {}
        var names = path.replace(/\/\//g, "\\").split('/');
        var $node = $files_structure;
        var keepGoing = true;
        for(var idx in names) {
          var name = names[idx].replace(/\\\\/g, "/");
          var found = false;
          if(keepGoing) {
            $node.children("ul").children("li").each(function() {
              if($(this).children(".text.name").text() == name) {
                $node = $(this);
                found = true;
                return false;
              }
            });
          }
          keepGoing = found;
        }
        return $node;
      },
      draggable_helper: function(event, $item) {
        if($(this).hasClass('folder_item')) {
          $item = $(this);
        } else {
          var width = $item.width();
          return $item.clone().css('backgroundColor', '#eeeeee').css('height', 50).css('borderWidth', 1).css('borderStyle', 'solid').css('borderColor', '#ccc').css('width', width - 50);
        }
        var $result = $item.clone().attr('id', 'file_drag');
        $result.find(".header .sub_header").remove();
        $result.find(".header").append("<div class='sub_header'/>");
        $result.find(".header .sub_header").html("&nbsp;");
        $result.addClass('file_drag');
        $result.find(".links").remove();
        $result.css('width', 100);
        var $ul = $("<ul/>");
        $ul.addClass('files_content');
        $ul.append($result);
        $ul.addClass('true-draggable');
        $ul.css('width', 200);
        $ul.css('height', 50);
        $("#content").append($ul);
        return $ul;
      },
      updateQuota: function() {
        if(!$("#quota").length) { return; }
        var url = $(".quota_url").attr('href');
        $.ajaxJSON(url, 'GET', {}, function(data) {
          $("#quota").text(data.quota);
          $("#quota_used").text(data.quota_used);
        }, function() {
        });
      }
    });
    $.extend(files, {
      draggable_options: {
        handle: '.draggable.item_icon',
        distance: 5,
        helper: files.draggable_helper,
        start: function(event, ui) {
          $files_content.addClass('dragging');
        },
        stop: function() {
          setTimeout(function() {
            $files_content.removeClass('dragging');
          }, 500);
        }
      },
      droppable_options: {
        accept: '.file,.folder',
        hoverClass: 'drop_target',
        tolerance: 'pointer',
        drop: function(event, ui) {
          if(!$(ui.helper).hasClass('true-draggable')) {
            return;
          }
          var $item = $(ui.draggable);
          var draggable = files.itemData($item);
          var $droppable = $(this);
          var droppable = files.itemData($(this).parent(".folder"));
          droppable = droppable || files.itemData($(this));
          $files_structure.loadingImage();
          if($item.hasClass('file')) {
            if($(ui.helper).hasClass('copy_drag')) {
              var url = $("#file_context_links ." + droppable.context_string + "_attachments_url").attr('href');
              var data = {
                'attachment[source_attachment_id]': draggable.id,
                'attachment[folder_id]': droppable.id
              };
              $.ajaxJSON(url, 'POST', data, function(data) {
                $files_structure.loadingImage('remove');
                files.updateFile(droppable.context_string, data, false);
                files.selectFolder($droppable);
                files.refreshView();
              }, function(data) {
                $files_structure.loadingImage('remove');
              });
            } else {
              var url = $("#file_context_links ." + droppable.context_string + "_attachment_url").attr('href');
              url = $.replaceTags(url, 'id', draggable.id);
              $.ajaxJSON(url, 'PUT', {'attachment[folder_id]': droppable.id}, function(data) {
                $files_structure.loadingImage('remove');
                files.updateFile(droppable.context_string, data, false);
                files.selectFolder($droppable);
                files.refreshView();
              }, function(data) {
                $files_structure.loadingImage('remove');
              });
            }
          } else {
            if($(ui.helper).hasClass('copy_drag')) {
              var url = $("#file_context_links ." + droppable.context_string + "_folders_url").attr('href');
              var data = {
                'folder[source_folder_id]': draggable.id,
                'folder[parent_folder_id]': droppable.id
              };
              $.ajaxJSON(url, 'POST', data, function(data) {
                $files_structure.loadingImage('remove');
                files.refreshContext(droppable.root_context_string);
              }, function(data) {
                $files_structure.loadingImage('remove');
              });
            } else {
              var url = $("#file_context_links ." + droppable.context_string + "_folder_url").attr('href');
              url = $.replaceTags(url, 'id', draggable.id);
              $.ajaxJSON(url, 'PUT', {'folder[parent_folder_id]': droppable.id}, function(data) {
                $files_structure.loadingImage('remove');
                files.refreshContext(draggable.root_context_string);
              }, function(data) {
                $files_structure.loadingImage('remove');
              });
            }
          }
        },
        over: function(event, ui) {
          if(!$(ui.helper).hasClass('true-draggable')) {
            $(this).removeClass('drop_target');
          }
          var draggable = files.itemData($(ui.draggable));
          var droppable = files.itemData($(this).parent(".folder"));
          droppable = droppable || files.itemData($(this));
          $(ui.helper).find(".header .sub_header").text("move to " + droppable.name);
          if(draggable && droppable && draggable.context_string != droppable.context_string) {
            $(ui.helper).addClass('copy_drag');
            $(ui.helper).find(".header .sub_header").html("<strong>copy</strong> to " + htmlEscape(droppable.name));
          }
        },
        out: function(event, ui) {
          $(ui.helper).removeClass('copy_drag');
          $(ui.helper).find(".header .sub_header").html("&nbsp;");
        }
      },
      breadcrumb: function() {
        var folders = location.hash.substring(1).replace(/\/\//g, "\\").split("/");
        var $crumbs = $("<div/>");
        var soFar = [];
        for(var idx = 0; idx < folders.length - 1; idx++) {
          var $a = $("<a/>");
          soFar.push(folders[idx].replace(/\\\\/g, "/"));
          $a.attr('href', '#' + soFar.join("/"));
          $a.text(folders[idx]);
          $crumbs.append($a);
        }
        return $crumbs;
      },
      refreshContext: function(context_string, callback) {
        files.refreshContext.refreshing = files.refreshContext.refreshing || {};
        if(files.refreshContext.refreshing[context_string]) { return; }
        files.refreshContext.refreshing[context_string] = true;
        var url = $("#file_context_links ." + context_string + "_attachments_url").attr('href');
        $.ajaxJSON(url, 'GET', {}, function(data) {
          files.clearDataCache();
          files.refreshContext.refreshing[context_string] = false;
          var scrollTop = $files_structure.scrollTop();
          var context_name = null;
          for(var idx in fileStructureData) {
            var context = fileStructureData[idx][0];
            if(context.context_string == context_string) {
              context_name = context.context_name;
              fileStructureData[idx][0].context.includes_files = true;
              for(var jdx in data.folders) {
                for(var kdx in fileStructureData[idx][1].folders) {
                  if(fileStructureData[idx][1].folders[kdx].id == data.folders[jdx].id) {
                    data.folders[jdx].includes_files = fileStructureData[idx][1].folders[kdx].includes_files;
                  }
                }
              }
              data.files = data.files || [];
              for(var jdx in fileStructureData[idx][1].files) {
                data.files.push(fileStructureData[idx][1].files[jdx]);
              }
              fileStructureData[idx][1] = data;
            }
          }
          var $context = $("#files_structure > ul > li.context." + context_string).filter(":first");
          if($context.length === 0) { $context = null; }
          var opens = [];
          var openRoot = false;
          if($context) {
            openRoot = $context.hasClass('open');
            var $opens = $context.find("li.node.open");
            $opens.each(function() {
              opens.push(files.itemData($(this)).id);
            });
          }
          var context_type = null;
          for(var idx in data.contexts) {
            for(var jdx in data.contexts[idx]) {
              if(!context_type) {
                context_type = jdx;
                context_name = data.contexts[idx][jdx].name;
              }
            }
          }
          var root_folder = null;
          if(!data.folders && data[0] && data[0][1] && data[0][1].folders) {
            data.folders = data[0][1].folders;
          }
          for(var idx in data.folders) {
            if(!root_folder && data.folders[idx].folder && data.folders[idx].folder.parent_folder_id === null) {
              root_folder = data.folders[idx].folder;
            }
          }
          var $context_folder = $context;
          if(!$context_folder || $context_folder.length === 0) {
            $context_folder = $files_structure.find(".folder_blank").clone(true).removeClass('folder_blank');
          }
          $context_folder.children(".name").text(context_name);
          $context_folder.children(".id").text(root_folder.id);
          $context_folder.addClass('context folder folder_' + root_folder.id + ' ' + context_string);
          $context_folder.find("li").addClass('to_be_removed');
          var $ul = $context_folder.children("ul");
          var addChildren = function($parent_folder, folder) {
            for(var jdx in data.folders) {
              if(folder.id && data.folders[jdx].folder.parent_folder_id == folder.id) {
                var $folder = $parent_folder.children("ul").children(".folder_" + data.folders[jdx].folder.id);
                if($folder.length === 0) {
                  $folder = $files_structure.find(".folder_blank").clone(true).removeClass('folder_blank');
                  $folder.addClass('folder folder_' + data.folders[jdx].folder.id);
                  $folder.children(".id").text(data.folders[jdx].folder.id);
                  $folder.children(".name").text(data.folders[jdx].folder.name);
                }
                $folder.removeClass('to_be_removed');
                addChildren($folder, data.folders[jdx].folder);
                if($folder.parents("body").length === 0) {
                  $parent_folder.children("ul").append($folder.show());
                }
              }
            }
          };
          for(var idx in data.folders) {
            if(data.folders[idx].folder.parent_folder_id == root_folder.id) {
              var $folder = $ul.find(".folder_" + data.folders[idx].folder.id);
              if($folder.length === 0) {
                $folder = $files_structure.find(".folder_blank").clone(true).removeClass('folder_blank');
                $folder.addClass('folder folder_' + data.folders[idx].folder.id);
                $folder.children(".name").text(data.folders[idx].folder.name);
                $folder.children(".id").text(data.folders[idx].folder.id);
              }
              $folder.removeClass('to_be_removed');
              addChildren($folder, data.folders[idx].folder);
              if($folder.parents("body").length === 0) {
                $ul.append($folder.show());
              }
            }
          }
          if(data.collaborations && !context_string.match(/^user_/)) {
            var $collaborations = $files_structure.find(".folder_blank").clone(true).removeClass('folder_blank');
            $collaborations.addClass('collaborations');
            $collaborations.fillTemplateData({data: {name: "collaborations"}});
            for(var idx in data.collaborations) {
              var collaboration = data.collaborations[idx].collaboration || data.collaborations[idx].google_docs_collaboration || data.collaborations[idx].etherpad_collaboration;
              var $file = $(".collaboration_" + collaboration.id);
              if($file.length === 0) {
                $file = $files_structure.find(".file_blank").clone(true).removeClass('file_blank');
                $file.addClass('collaboration_' + data.collaborations[idx].collaboration.id);
                $file.addClass('collaboration ' + data.collaborations[idx].collaboration.collaboration_type);
                $file.fillTemplateData({data: {name: data.collaborations[idx].collaboration.title, id: data.collaborations[idx].collaboration.id}});
              }
              $file.removeClass('to_be_removed');
              if($file.parents("body").length === 0) {
                $collaborations.children("ul").append($file.show());
              }
            }
            $ul.append($collaborations.show());
          }
          var group_names = {};
          for(var idx in data.groups) {
            group_names[(data.groups[idx].group || data.groups[idx].course_assigned_group).category] = true;
          }
          for(var idx in group_names) {
            var $category = $files_structure.find(".folder_blank").clone(true).removeClass('folder_blank');
            $category.fillTemplateData({data: {name: idx}});
            $category.addClass('groups');
            for(var jdx in data.groups) {
              var group = (data.groups[jdx].group || data.groups[jdx].course_assigned_group);
              if(group.category == idx) {
                var root_group_folder = null;
                for(var kdx in data.folders) {
                  if(!root_group_folder && !data.folders[kdx].folder.parent_folder_id === null) {
                    root_group_folder = data.folders[kdx].folder;
                  }
                }
                if(root_group_folder) {
                  var $group = $category.children("ul").children(".group_" + group.id);
                  if($group.length === 0) {
                    $group = $files_structure.find(".folder_blank").clone(true).removeClass('folder_blank');
                    $group.addClass('group context folder folder_' + root_group_folder.id);
                    $group.addClass('group_' + group.id);
                    $group.fillTemplateData({data: {name: group.name, id: root_group_folder.id}});
                  }
                  $group.removeClass('to_be_removed');
                  addChildren($group, root_group_folder);
                  if($group.parents("body").length === 0) {
                    $category.children("ul").append($group.show());
                  }
                }
              }
            }
            $ul.append($category.show());
          }
          var found = false;
          $context_folder.find(".to_be_removed").remove();
          $files_structure.find("#files_structure_list > .folder").each(function() {
            var data = files.itemData($(this));
            if(data && data.root_context_string == context_string) {
              if($(this)[0] != $context_folder[0]) {
                $(this).after($context_folder.show());
                $(this).remove();
              }
              found = true;
            }
          });
          if(!found) {
            $files_structure.find("#files_structure_list").append($context_folder.show());
          }
          $context_folder.children(".text").droppable(files.droppable_options);
          $context_folder.find(".folder > .text").droppable(files.droppable_options);
          for(var idx in opens) {
            files.expandFolder($context_folder.find(".folder_" + opens[idx]));
          }
          if(openRoot) {
            files.expandFolder($context_folder);
          }

          $files_structure.scrollTop(scrollTop);

          $files_structure_list.instTree.InitInstTree($files_structure_list);
          $files_structure.find("li.node.active-node,li.leaf.active-leaf").filter(":first").children(".name").click();
          if(callback && $.isFunction(callback)) {
            callback();
          }
        }, function() {
          files.refreshContext.refreshing[context_string] = false;
        });
      },
      refreshContentListeners: function() {
        var context = files.currentContext();
        if(context && context.permissions && context.permissions.manage_files) {
          $files_content.find(".folder.draggable_droppable").droppable(files.droppable_options);
          $files_content.sortable('enable');
          $files_content.sortable('refresh');
        } else {
          $files_content.sortable('disable').removeClass('ui-state-disabled');
        }
        if(files.canManageAContext) {
          $files_content.find(".folder.draggable_droppable").draggable(files.draggable_options);
          $files_content.find(".file").draggable(files.draggable_options);
        }
      },
      nodeClumpSize: 25,
      addScrollCatcher: function() {
        var addMoreItems = function() {
          var scrollTop = $files_content.scrollTop();
          var more = false;
          var itemIdx = 0;
          $files_content.find(".catcher").remove();
          var $lastItem = $files_content.find(".folder_item:visible:last");
          var $node = $lastItem.data('node');
          if($node) {
            $node = $node.next();
            var tooMany = false;
            while($node.length > 0) {
              if(!$node.hasClass('separator')) {
                itemIdx++;
                if(itemIdx <= files.nodeClumpSize) {
                  files.addContentItem($node);
                } else {
                  tooMany = true;
                }
              }
              $node = $node.next();
            }
            files.refreshContentListeners();
            if(tooMany) {
              files.addScrollCatcher();
            }
          }
          $files_content.scrollTop(scrollTop);
        };
        var $li = $("<li class='catcher'>&nbsp;</li>");
        if(!files.watchingScroll) {
          $files_content.bind('scroll', function(event) {
            var $catcher = $files_content.find(".catcher:visible:first");
            if($catcher.length > 0) {
              var catcherTop = $catcher.offset().top;
              var contentBottom = $files_content.offset().top + $files_content.height();
              if(catcherTop < contentBottom) {
                addMoreItems();
              }
            }
          });
          files.watchingScroll = true;
        }
        $files_content.append($li);
      },
      addContentItem: function($item, hidden) {
        var data = files.itemData($item);
        if(!data || !data.id) { return; }
        var isNew = false;
        if($item.hasClass('node')) {
          var $content = $files_content.find(".folder_" + data.id);
          if($content.length === 0) {
            isNew = true;
            $content = $("#content_templates .folder:first").clone(true);
            if(hidden) {
              $content.hide();
            }
            $content.fillTemplateData({
              data: data
            });
            $content.data('parent_node', $item.parent().parent());
            var folder_url = $.replaceTags($("." + data.context_string + "_folder_url").attr('href'), 'id', data.id);
            $content.find(".rename_item_link,.delete_item_link,.folder_url").attr('href', folder_url);
            $content.addClass('folder_' + data.id);
            $content.find(".item_icon.draggable").attr('title', I18n.t('titles.click_and_drag', 'Click and drag to move folder to another folder'));
            $content.data('node', $item);
          }
          $content.toggleClass('editable_folder_item', !!(!$item.hasClass('context') && ((data.context && data.context.permissions && data.context.permissions.manage_files) || (data.permissions && data.permissions.update))));
          $content.removeClass('to_be_removed');
          $content.find(".item_icon").toggleClass('draggable', $content.hasClass('editable_folder_item'));
          $content.find(".item_icon").attr('alt', 'Folder').attr('src', $("#content_blank_icon").attr('src'));
          if(data && data.currently_locked) {
            $content.find(".item_icon").attr('alt', I18n.t('alts.folder_locked', 'Locked Folder'))
              .attr('src', $("#content_locked_icon").attr('src'));
          }
          $content.find(".lock_item_link").showIf(!data.currently_locked);
          $content.find(".unlock_item_link").showIf(data.currently_locked);
          $content.toggleClass('folder_locked', !!(data && data.currently_locked));
          $content.toggleClass('draggable_droppable', $item.hasClass('folder') && !$item.hasClass('context'));
          if(isNew) {
            $files_content.append($content);
          }
        } else if($item.hasClass('collaboration')) {
          // set the edit and delete urls, for sure
          var $content = $files_content.find(".collaboration_" + data.id);
          if($content.length === 0) {
            isNew = true;
            $content = $("#content_templates .collaboration:first").clone(true);
            if(hidden) {
              $content.hide();
            }
            $content.fillTemplateData({
              data: data
            });
            $content.data('parent_node', $item.parent().parent());
            $content.data('node', $item);
            var collaboration_url = $.replaceTags($("." + data.context_string + "_collaboration_url").attr('href'), "id", data.id);
            $content.find(".collaboration_url").attr('href', collaboration_url);
            $content.addClass('collaboration_' + data.id);
            $content.addClass(data.collaboration_type);
          }
          $content.toggleClass('editable_folder_item', !!(data.permissions && data.permissions.update));
          $content.removeClass('to_be_removed');
          $content.find(".item_icon").attr('alt', I18n.t('alts.collaboration', 'Collaboration')).attr('src', $("#content_blank_icon").attr('src'));
          if(isNew) {
            $files_content.append($content);
          }
        } else {
          var $content = $files_content.find(".file_" + data.id);
          if($content.length === 0) {
            isNew = true;
            $content = $("#content_templates .file:first").clone(true);
            if(hidden) {
              $content.hide();
            }
            var file_url = $.replaceTags($("#file_context_links ." + data.context_string + "_attachment_url").attr('href'), "id", data.id);
            var download_url = $.replaceTags($("#file_context_links ." + data.context_string + "_download_attachment_url").attr('href'), "id", data.id);
            $content
              .fillTemplateData({
                data: data
              })
              .data({
                parent_node: $item.parent().parent(),
                node: $item
              })
              .addClass(data.mime_class + ' file_' + data.id);
            $content.find(".attachment_url").attr('href', file_url);
            $content.find(".download_url").attr('href', download_url);
            $content.find(".item_icon.draggable").attr('title', 'Click and drag to move file to another folder');
          }
          $content
            .toggleClass('editable_folder_item', !!((data.context && data.context.permissions && data.context.permissions.manage_files) || (data.permissions && data.permissions.update)))
            .removeClass('to_be_removed')
            .find(".item_icon")
              .attr({
                alt: I18n.t('alts.file', 'File'),
                src: $("#content_blank_icon").attr('src')
              });
          if(data && data.currently_locked) {
            $content.find(".item_icon").attr({
              alt: I18n.t('alts.locked_file', 'Locked File'),
              src: $("#content_locked_icon").attr('src')
            });
          }
          $content.find(".lock_item_link").showIf(!data.currently_locked);
          $content.find(".unlock_item_link").showIf(data.currently_locked);
          $content.find(".preview_item_link").showIf(data.scribd_doc || data.content_type.match(/image/) || (data.content_type.match(/(video|audio)/) && data.media_entry_id));
          // Need to be careful on this one... we can't let students turn in a
          // file and then edit it after the fact...
          $content.find(".edit_item_content_link_holder").showIf($content.hasClass('editable_folder_item') && data.context_type != 'User' && ($content.hasClass('text') || $content.hasClass('html') || $content.hasClass('code')));
          $content.find(".item_icon").toggleClass('draggable', $content.hasClass('editable_folder_item'));
          if(isNew) {
            $files_content.append($content);
          }
        }
        return isNew;
      },
      reorderContent: function(folder_id, subcontent) {
        var attachments = [];
        var folders = [];
        for(var idx = 0; idx < subcontent.length; idx++) {
          if(subcontent[idx].attachment) {
            attachments.push(subcontent[idx]);
          } else if(subcontent[idx].folder) {
            folders.push(subcontent[idx]);
          }
        }
        $files_structure.find(".folder_" + folder_id).each(function() {
          var $folder = $(this);
          var $folders = [];
          var $files = [];
          $folder.children("ul").children("li").each(function() {
            if($(this).hasClass('file')) {
              $files.push($(this));
            } else {
              $folders.push($(this));
            }
          });
          $files = $files.sort(function($a, $b) {
            var a = files.itemData($a);
            var b = files.itemData($b);
            return a.position - b.position;
          });
          for(var idx in $files) {
            $folder.children("ul").append($files[idx].prev(".separator"));
            $folder.children("ul").append($files[idx]);
          }
          $folders = $folders.sort(function($a, $b) {
            var a = files.itemData($a) || {};
            var b = files.itemData($b) || {};
            return (b.position || 0) - (a.position || 0);
          });
          for(var idx in $folders) {
            if ($files[idx]) {
              $folder.children("ul").prepend($files[idx].prev(".separator"));
              $folder.children("ul").prepend($files[idx]);
            }
          }
        });
        files.refreshView();
      },
      updateCollaboration: function(context_string, data, refresh) {
        var file_context_string = $.underscore(data.collaboration.context_type) + "_" + data.collaboration.context_id;
        for(var idx in fileStructureData) {
          if(fileStructureData[idx] && (fileStructureData[idx][0].context_string == context_string || fileStructureData[idx][0].context_string == file_context_string)) {
            var found = false;
            for(var jdx in fileStructureData[idx][1].collaborations) {
              var collab = fileStructureData[idx][1].collaborations[jdx].collaboration;
              if(collab.id == data.collaboration.id) {
                fileStructureData[idx][1].collaborations[jdx] = data;
                $files_structure.find(".collaboration_" + collab.id).each(function() {
                  var folder = files.itemData($(this).parent("ul").parent("li"));
                  $(this).fillTemplateData({data: {'name': data.collaboration.title}});

                  // add 'title="this is the filename.txt" so you can read files/folders that have really long names
                  if (data.collaboration.title) $(this).find('.name').attr('title', data.collaboration.title);

                });
                found = true;
              }
            }
            if(!found) {
              var collab = data.collaboration;
              fileStructureData[idx][1].collaborations.push(data);
              var $collab = $files_structure.find(".file_blank").clone(true).removeClass('file_blank');
              $collab.removeClass('file');
              $collab.addClass('collaboration collaboration_' + collab.id + ' ' + collab.collaboration_type);
              collab.name = collab.title;
              $collab.fillTemplateData({data: collab});

              // add 'title="this is the filename.txt" so you can read files/folders that have really long names
              if (collab.title) $collab.find('.name').attr('title', collab.title);

              $files_structure.find("." + context_string + " .collaborations").children("ul").prepend($collab.show());
            }
          }
        }
        if(refresh !== false ) {
          files.refreshView(data.attachment);
          $files_structure_list.instTree.InitInstTree($files_structure_list);
        }
      },
      updateFile: function(context_string, data, refresh) {
        files.clearDataCache();
        var file_context_string = $.underscore(data.attachment.context_type) + "_" + data.attachment.context_id;
        for(var idx in fileStructureData) {
          if(fileStructureData[idx] && (fileStructureData[idx][0].context_string == context_string || fileStructureData[idx][0].context_string == file_context_string)) {
            var found = false;
            var moved = false;
            if(!data.definitely_new) {
              for(var jdx in fileStructureData[idx][1].files) {
                var file = fileStructureData[idx][1].files[jdx].attachment;
                if(file.id == data.attachment.id) {
                  fileStructureData[idx][1].files[jdx] = data;
                  $files_structure.find(".file_" + file.id).each(function() {
                    var folder = files.itemData($(this).parent("ul").parent("li"));
                    if(folder.id == data.attachment.folder_id) {
                      $(this).fillTemplateData({data: {'name': data.attachment.display_name}});

                      // add 'title="this is the filename.txt" so you can read files/folders that have really long names
                      if (data.attachment.display_name) $(this).find('.name').attr('title', data.attachment.display_name);

                    } else {
                      moved = true;
                    }
                  });
                  found = true;
                  if(moved) {
                    $files_structure.find(".file_" + file.id).remove();
                  }
                }
              }
            }
            if(!found || moved) {
              var attachment = data.attachment;
              if(!found) {
                data.definitely_new = false;
                fileStructureData[idx][1].files.push(data);
              }
              var $file = $files_structure.find(".file_blank").clone(true).removeClass('file_blank');
              $file.addClass('file_' + attachment.id);
              $file.addClass(attachment.mime_class);
              attachment.name = attachment.display_name;
              $file.fillTemplateData({data: attachment});

              // add 'title="this is the filename.txt" so you can read files/folders that have really long names
              if (attachment.name) $file.find('.name').attr('title', attachment.name);

              $files_structure.find(".folder_" + attachment.folder_id).children("ul").append($file.show());
            }
          }
        }
        if(refresh !== false ) {
          files.refreshView(data.attachment);
          $files_structure_list.instTree.InitInstTree($files_structure_list);
        }
      },
      updateFolder: function(context_string, data, refresh) {
        files.clearDataCache();
        var folder_context_string = $.underscore(data.folder.context_type) + "_" + data.folder.context_id;
        var already_in_place = data.already_in_place;
        data.already_in_place = null;
        for(var idx in fileStructureData) {
          // Check for the folder in all contexts
          if(fileStructureData[idx] && (fileStructureData[idx][0].context_string == context_string || fileStructureData[idx][0].context_string == folder_context_string)) {
            var found = false;
            var moved = false;
            for(var jdx in fileStructureData[idx][1].folders) {
              var folder = fileStructureData[idx][1].folders[jdx].folder;
              if(folder.id == data.folder.id) {
                // Update the cached data for the folder
                if(folder.includes_files) {
                  data.folder.includes_files = folder.includes_files;
                }
                fileStructureData[idx][1].folders[jdx] = data;
                // For each visual representation, update the name
                // and insert into the dom if not there already
                $files_structure.find(".folder_" + folder.id).each(function() {
                  var folder = files.itemData($(this).parent("ul").parent("li"));
                  folder = folder || {parent_folder_id: null};
                  if(folder.id == data.folder.parent_folder_id) {
                    if(!$(this).hasClass('context')) {
                      $(this).children(".name").text(data.folder.name)
                        // add 'title="this is the filename.txt" so you can read files/folders that have really long names
                        .attr('title', data.folder.name);
                    }
                    if(!already_in_place) {
                      $(this).prev("li.separator").remove();
                      var $parent = $(this).parent("ul").parent("li");
                      var $before = null;
                      var $current = $(this);
                      $parent.children("ul").children("li:not(.separator)").each(function() {
                        var position = files.itemData($(this)).position;
                        if($(this)[0] != $current[0] && (!$(this).hasClass('folder') || position >= folder.position)) {
                          $before = $(this);
                          return false;
                        }
                      });
                      if($before) {
                        $before.before($(this).show());
                        $before.before("<li class='separator'/>");
                      } else {
                        $parent.children("ul").append("<li class='separator'/>");
                        $parent.children("ul").append($(this).show());
                      }
                    }
                  } else {
                    moved = true;
                  }
                });
                found = true;
                if(moved) {
                  $files_structure.find(".folder_" + folder.id).remove();
                }
              }
            }
            if(!found || moved) {
              files.foldersStillLoading = files.foldersStillLoading || {};
              files.foldersStillLoading[data.folder.id] = data;
              files.refreshContext(context_string);
              if(context_string != folder_context_string) {
                files.refreshContext(folder_context_string);
              }
            }
          }
        }
        if(refresh !== false ) {
          files.refreshView(data.folder);
        }
      },
      refreshView: function(file) {
        $files_structure.find("li.node.active-node,li.leaf.active-leaf").filter(":first").children(".text:visible:first").click();
        if(file && file.id) {
          $files_content.find(".file_" + file.id).mouseover();
          $files_content.find(".folder_" + file.id).mouseover();
        }
        $add_file_link.triggerHandler('show');
      },
      currentItemData: function() {
        return files.itemData($files_structure.find("li.node.active-node,#files_structure li.leaf.active-leaf"));
      },
      currentContext: function() {
        var context_string = files.currentItemData().context_string;
        for(var idx in fileStructureData) {
          if(fileStructureData[idx][0].context_string == context_string) {
            return fileStructureData[idx][0].context;
          }
        }
        return null;
      },
      clearDataCache: function() {
        files.clearDataCache.cacheIndex++;
      },
      itemData: function($node) {
        var res = $node.data('item_data');
        if(res && res.cacheIndex == files.clearDataCache.cacheIndex) {
          return res;
        }
        var res = files.uncachedItemData($node);
        if(res) {
          res.cacheIndex = files.clearDataCache.cacheIndex;
          $node.data('item_data', res);
        }
        return res;
      },
      uncachedItemData: function($node) {
        if($node.closest("#files_content").length > 0) {
          return files.itemData($node.data('node'));
        }
        var id = $node.getTemplateData({textValues: ['id']}).id;
        for(var idx in fileStructureData) {
          var context = fileStructureData[idx];
          var context_object = null;
          if($node.hasClass('file')) {
            var file_list = context[1].files;
            for(var jdx in file_list) {
              var file = file_list[jdx].attachment;
              if(file.id == id) {
                file.context_string = $.underscore(file.context_type) + "_" + file.context_id;
                file.root_context_string = context[0].context_string;
                file.context = context[0].context;
                file.name = file.display_name;
                return file;
              }
            }
          } else if($node.hasClass('collaborations')) {
            if($node.parents("li.context:last").hasClass(context[0].context_string)) {
              res = $node.getTemplateData({textValues: ['name']});
              res.context_string = context[0].context_string;
              res.context = context[0].context;
              return res;
            }
          } else if($node.hasClass('groups')) {
            if($node.parents("li.context:last").hasClass(context[0].context_string)) {
              res = $node.getTemplateData({textValues: ['name']});
              res.context_string = context[0].context_string;
              res.context = context[0].context;
              return res;
            }
          } else if($node.hasClass('collaboration')) {
            var collaborations = context[1].collaborations;
            for(var jdx in collaborations) {
              var collaboration = collaborations[jdx].collaboration;
              if(collaboration.id == id) {
                collaboration.context_string = $.underscore(collaboration.context_type) + "_" + collaboration.context_id;
                collaboration.root_context_string = context[0].context_string;
                collaboration.name = collaboration.title;
                return collaboration;
              }
            }
          } else if($node.hasClass('folder')) {
            var folders = context[1].folders;
            for(var jdx in folders) {
              var folder = folders[jdx].folder;
              if(folder.id == id) {
                folder.context_string = $.underscore(folder.context_type) + "_" + folder.context_id;
                folder.root_context_string = context[0].context_string;
                if($node.hasClass('context')) {
                  folder.name = $node.getTemplateData({textValues: ['name']}).name;
                }
                folder.context = context[0].context;
                return folder;
              }
            }
          } else if($node.hasClass('group')) {
            var groups = context[1].groups;
            for(var jdx in groups) {
              var group = groups[jdx].group || groups[jdx].course_assigned_group;
              group.context_string = $.underscore(group.context_type) + "_" + group.context_id;
              group.root_context_string = context[0].context_string;
              if(group.id == id) {
                return group;
              }
            }
          }
        }
        if($node.hasClass('folder')) {
          var context = null;
          for(var idx in fileStructureData) {
            if($node.closest('.context').hasClass(fileStructureData[idx][0].context_string)) {
              context = fileStructureData[idx];
            }
          }
          for(var idx in files.foldersStillLoading) {
            if(files.foldersStillLoading[idx].folder.id == id) {
              var folder = files.foldersStillLoading[idx].folder;
              folder.name = $node.getTemplateData({textValues: ['name']}).name;
              folder.context_string = context[0].context_string;
              folder.context = context[0].context;
              return folder;
            }
          }
          if(context) {
            var folder = {};
            folder.name = $node.getTemplateData({textValues: ['name']}).name;
            folder.id = id;
            folder.context_string = context[0].context_string;
            folder.permissions = {read_contents: true};
            folder.context = context[0].context;
            folder.false_folder = true;
            return folder;
          }
        }
        return null;
      }
    });

    $(document).ready(function() {
      files.init();
      setInterval(function() {
        $add_file_link.triggerHandler('show');
      }, 1000);
      $(".folder_item").live('mousedown', function(event) {
        event.preventDefault();
      });
      $(".folder_item.ui-draggable").live('mouseover', function() {
        $(this).find(".item_icon").attr('title', I18n.t('titles.drag_to_move', 'Drag to move to a different folder'));
      });
      // on hover of the swfupload link, manually set the underline on
      // the add files link because otherwise the swf keeps the link from
      // registering mouseover events.
      $swfupload_holder.hover(function(e) {
        $add_file_link.css('text-decoration', 'underline');
      }, function(e) {
        $add_file_link.css('text-decoration', 'none');
      });
      $add_file_link.bind('show', function() {
        var linkWidth = $add_file_link.width();
        var linkHeight = $add_file_link.height();
        var linkOffset = $add_file_link.offset();
        var holderOffset = $files_content.offset();
        linkOffset.left = linkOffset.left - holderOffset.left;
        linkOffset.top = linkOffset.top - holderOffset.top;
        $swfupload_holder.css({
          width: linkWidth + 5,
          height: linkHeight + 5,
          top: linkOffset.top - 5,
          left: linkOffset.left - 5
        });
      });
      $("#file_uploads_dialog_link").click(function(event) {
        event.preventDefault();
        $("#file_uploads").dialog('close').dialog({
          autoOpen: false,
          title: I18n.t('titles.file_uplaods_queue', "File Uploads Queue")
        }).dialog('open');
      });
      setTimeout(function() {
        $files_structure.find(".folder > .text").droppable(files.droppable_options);
        $files_content.sortable({
          distance: 5,
          cancel: '.draggable.item_icon',
          items: 'li.file,li.folder',
          axis: 'y',
          hoverClass: 'lameness',
          containment: 'parent',
          start: function(event, ui) {
            $files_content.addClass('dragging');
          },
          stop: function(event, ui) {
            setTimeout(function() {
              $files_content.removeClass('dragging');
            }, 500);
          },
          helper: files.draggable_helper,
          update: function(event, ui) {
            var data = files.itemData($(ui.item));
            var folder_order = [];
            var order = [];
            var $first_file = $files_content.find(".file:first");
            var $items = $files_content.find(".folder_item");
            var firstFileIndex = $items.index($first_file);
            $files_content.find(".folder").each(function() {
              if($items.index($(this)) > firstFileIndex) {
                $first_file.before($(this));
              }
              var id = files.itemData($(this)).id;
              folder_order.push(id);
            });
            $files_content.find(".file").each(function() {
              var id = files.itemData($(this)).id;
              order.push(id);
            });
            $files_content.loadingImage();
            var send_data = {
              order: order.join(','),
              folder_id: data.folder_id || data.parent_folder_id,
              folder_order: folder_order.join(',')
            };
            var url = $("#file_context_links ." + data.context_string + "_reorder_attachments_url").attr('href');
            $.ajaxJSON(url, 'POST', send_data, function(return_data) {
              $files_content.loadingImage('remove');
              for(var idx in return_data) {
                if(return_data[idx].attachment) {
                  files.updateFile(data.context_string, return_data[idx], false);
                } else if(return_data[idx].folder) {
                  files.updateFolder(data.context_string, return_data[idx], false);
                }
              }
              files.reorderContent(data.folder_id, return_data);
              files.refreshView(data);
            }, function() {
              $files_content.loadingImage('remove');
            });
          }
        });
        $("#files_structure_list > li").hide();
        $files_structure_list.instTree({
          autoclose: false,
          multi: false,
          dragdrop: false,
          onExpand: function(node) {
            if(node.hasClass('folder')) {
              var folder = files.itemData(node);
              if(folder && !folder.includes_files) {
                files.getFilesForFolder(folder, false);
              }
            }
          },
          onCollapse: function(node) {
            if(node.find(".node.active-node,.leaf.active-leaf").length > 0) {
              node.find(".text:visible:first").click();
            }
          },
          onClick: function(event, node) {
            $files_content.find(".content_panel").addClass('to_be_hidden');
            $files_content.find(".folder_item").addClass('to_be_removed');
            $files_content.find(".catcher").addClass('to_be_removed');
            $files_content.find(".file_preview").remove();
            $files_content.find(".message").remove();
            var clearExtras = function() {
              $files_content.find(".content_panel.to_be_hidden").hide();
              $files_content.find(".catcher.to_be_removed").remove();
              $files_content.find(".folder_item.to_be_removed").remove();
            };
            var data = files.itemData(node);
            var path = encodeURIComponent(files.fullPath(node));
            if(location.hash != "#" + path) {
              location.replace("#" + path);
            }
            // $swfupload_holder.css('left', -1000);
            if(!data.includes_files && data.full_name) {
              files.getFilesForFolder(data);
            }
            if(data.context_string) {
              if(INST) {
                INST.interaction_context = data.context_string;
              }
              files.updatePageView(data.context_string);
            }
            if(node.hasClass('node')) {
              var folder_url = $.replaceTags($("." + data.context_string + "_folder_url").attr('href'), 'id', data.id);
              var cancelled = false;
              var $no_content = $("<li class='message'>" + I18n.t('messages.folder_empty', "Nothing in this Folder") + "</li>");
              if(node.hasClass('folder')) {
                if(!data || !data.permissions || !data.permissions.read_contents) {
                  $files_content.find(".content_panel:last").after("<li class='message'>" + I18n.t('messages.access_denied', "You cannot read the contents of this folder.") + "</li>");
                  cancelled = true;
                } else {
                  // add a control panel to the top for adding files, folders to this
                  var $panel = $("#folder_panel");
                  $panel.find(".rename_item_link,.delete_item_link,.folder_url").attr('href', folder_url);
                  $panel.find(".breadcrumb").empty().append(files.breadcrumb());
                  $panel.toggleClass('editable_content_panel', !!((data.context && data.context.permissions && data.context.permissions.manage_files) || (data.permissions && data.permissions.update)))
                    .toggleClass('addable_content_panel', !!((data.context && data.context.permissions && data.context.permissions.manage_files) || (data.permissions && data.permissions.update)))
                    .toggleClass('downloadable_content_panel', !$panel.hasClass('editable_content_panel') && !$panel.hasClass('addable_content_panel') && !!(data.permissions && data.permissions.read_contents));

                  $panel.removeClass('to_be_hidden');
                  $panel.find(".download_zip,.upload_zip").hide();
                  if(node.hasClass('context') || !(data && data.permissions && data.permissions.update)) {
                    $panel.removeClass('editable_content_panel');
                  }

                  var download_folder_url = $.replaceTags($("." + data.context_string + "_folder_url").attr('href') + "/download", 'id', data.id);
                  $(".download_zip_link").attr('href', download_folder_url);
                  $(".upload_zip_link").attr('href', $("." + data.context_string + "_import_url").attr('href') + "?return_to=" + encodeURIComponent(location.href) + "&folder_id=" + data.id);
                  data.unlock_at_string = $.parseFromISO(data.unlock_at).datetime_formatted;
                  data.lock_at_string = $.parseFromISO(data.lock_at).datetime_formatted;
                  $panel.find(".lock_after").showIf(data.lock_at);
                  $panel.find(".lock_until").showIf(data.unlock_at);
                  $panel.find(".currently_locked_box").showIf(data.currently_locked);
                  $panel.find(".lock_item_link").showIf(data.parent_folder_id && !data.currently_locked);
                  $panel.find(".unlock_item_link").showIf(data.parent_folder_id && data.currently_locked);
                  $panel.find(".download_zip").showIf(data.permissions && data.permissions.read_contents);
                  $panel.find(".upload_zip").showIf(data.context && data.context.permissions && data.context.permissions.manage_files);
                  $panel.find(".edit_link").showIf(data.context && data.context.permissions && data.context.permissions.manage_files);
                  $panel.fillTemplateData({data: data});
                  $panel.data('node', node);
                  $panel.show();
                  $add_file_link.triggerHandler('show');
                }
              } else if(node.hasClass('collaborations')) {
                var $panel = $("#collaborations_panel");
                var context = data.context;
                $panel.find(".header .name").text(context.name);
                $panel.find(".breadcrumb").empty().append(files.breadcrumb());
                var collaborations_url = $("." + data.context_string + "_collaborations_url").attr('href');
                $panel.find(".collaborations_link").attr('href', collaborations_url);
                $panel.find(".add_collaboration_link").attr('href', collaborations_url);
                $panel.find(".view_collaborations").showIf(context && context.permissions && context.permissions.manage_grades);
                $panel.removeClass('to_be_hidden');
                $panel.toggleClass('addable_content_panel', !!(data.context && data.context.permissions && data.context.permissions.create_collaborations));
                $panel.data('node', node);
                $panel.show();
              } else if(node.hasClass('groups')) {
                var $panel = $("#groups_panel");
                var context = data.context;
                var groups_url = $("." + data.context_string + "_groups_url").attr('href');
                $panel.find(".category_name").text(data.name);
                $panel.find(".context_name").text(context.name);
                $panel.find(".breadcrumb").empty().append(files.breadcrumb());
                $panel.find(".groups_link").attr('href', groups_url);
                $panel.removeClass('to_be_hidden');
                if(context && context.permissions && context.permissions.read_roster) {
                  $panel.toggleClass('addable_content_panel', true);
                }
                $panel.show();
              }
              if(!cancelled) {
                var nodeIdx = 0;
                var nodeCount = node.children("ul").children("li.node,li.leaf").length;
                clearExtras.already_cleared = true;
                setTimeout(function() {
                  var added = false;
                  node.children("ul").children("li.node,li.leaf").each(function() {
                    nodeIdx++;
                    if(nodeIdx < files.nodeClumpSize) {
                      newItem = files.addContentItem($(this), true);
                      if(newItem) { added = true; }
                    }
                  });
                  $files_content.find("li.folder_item").show();
                  if(nodeCount >= files.nodeClumpSize) {
                    files.addScrollCatcher();
                  }
                  if(added) {
                    files.refreshContentListeners();
                  }
                  if(node.children("ul").children("li.node,li.leaf").length === 0 || (node.hasClass('folder') && !data.includes_files)) {
                    if(node.hasClass('folder') && !data.includes_files) {
                      $no_content.addClass('no_content');
                      $no_content.text(I18n.t('messages.loading_files', "Loading Files..."));
                      files.getFilesForFolder(data, function(data) {
                        if(data.files.length > 0) {
                          files.refreshView();
                        } else {
                          $files_content.find(".message.no_content").remove();
                        }
                      });
                    }
                    if($files_content.find(".message.no_content").length === 0) {
                      if (node.hasClass('collaborations')) {
                        var find_out_more = "";
                        if(data.context.permissions.create_collaborations) {
                          find_out_more = '<p>' + I18n.t('descriptions.collaborations2', 'To find out more about a particular type of collaboration, click &quot;New collaboration&quot; and then choose that type in the dropdown list.') + '</p>';
                        }
                        $no_content.html([
                          '<div class="ui-state-highlight" style="padding:1em;">',
                            '<p>', I18n.t('descriptions.collaborations',
                            'Collaborations are a way for you to use web-based tools like ' +
                            'Google Docs and EtherPad ' +
                            'to work collaboratively on tasks like group papers or note-taking.  This is a special folder that shows you any collaborations you have created ' +
                            'so you have an easy place to keep track of and create those collaborations'),
                            '</p>',
                            find_out_more,
                          '</div>',
                          '<p>', I18n.t('messages.no_collaborations', "There are no collaborations to show"), '</p>'
                        ].join('').replace('Google Docs', '<a href="http://docs.google.com">Google Docs</a>').replace('EtherPad', '<a href="http://www.etherpad.org">EtherPad</a>'));
                      }
                      $files_content.append($no_content);
                    }
                  }
                  clearExtras();
                }, 10);
              }
            } else {
              if(node.hasClass('file')) {
                // show a file control panel with file size, download link, etc.
                var $panel = $("#file_panel");
                var $preview = null;
                data.unlock_at_string = $.parseFromISO(data.unlock_at).datetime_formatted;
                data.lock_at_string = $.parseFromISO(data.lock_at).datetime_formatted;
                $panel.find(".lock_after").showIf(data.lock_at);
                $panel.find(".lock_until").showIf(data.unlock_at);
                $panel.find(".currently_locked_box").showIf(data.currently_locked);
                $panel.find(".lock_item_link").showIf(!data.currently_locked);
                $panel.find(".unlock_item_link").showIf(data.currently_locked);
                $panel.removeClass('to_be_hidden');
                $panel.fillTemplateData({data: data});
                var file_url = $.replaceTags($("#file_context_links ." + data.context_string + "_attachment_url").attr('href'), "id", data.id);
                var download_url = $.replaceTags($("#file_context_links ." + data.context_string + "_download_attachment_url").attr('href'), "id", data.id);
                $panel.find(".breadcrumb").empty().append(files.breadcrumb());
                $panel.find(".attachment_url").attr('href', file_url).end()
                  .find(".download_item_link").attr('href', download_url);
                $panel.removeClass('editable_content_panel');
                if(data && data.permissions && data.permissions.update) {
                  // show a few more settings in the top control panel
                  $panel.addClass('editable_content_panel');
                }
                $panel.removeClass('panel_locked');
                if(!data || !data.permissions || !data.permissions.download) {
                  // get rid of the download link, add a "this file is currently locked (details)"
                  $panel.addClass('panel_locked');
                } else if (data && data.permissions && data.permissions.download && $.isPreviewable(data.content_type)) {
                  // show an inline preview
                  $preview = $("#content_templates .file_scribd_preview").clone(true);
                  $preview.append("<div id='doc_preview_holder'/>");
                } else {
                  // show a few more details about the file, preview if possible
                  if(data && data.content_type.match(/image/)) {
                    $preview = $("#content_templates .file_image_preview").clone(true);
                    var url = $.replaceTags($("#file_context_links ." + data.context_string + "_preview_attachment_url").attr('href'), "id", data.id);
                    $preview.find("a").attr('href', download_url);
                    $preview.find("img")
                      .attr('src', $(".preview_loading_image").attr('src'))
                      .attr('src', url || "")
                      .attr('title', data.display_name);
                  } else if(data && data.content_type.match(/(video|audio)/) && data.media_entry_id) {
                    $preview = $("#content_templates .file_media_preview").clone(true);
                    $preview.fillTemplateData({data: data});
                    var type = data.content_type.match(/video/) ? 'video' : 'audio';
                    $preview.find(".media_preview").mediaComment('show_inline', 'maybe', type, download_url);
                    $preview.find("a").attr('href', download_url);
                  } else {
                    $preview = $("#content_templates .file_no_preview").clone(true);
                    $preview.fillTemplateData({data: data});
                    $preview.find("a").attr('href', download_url);
                  }
                }
                $panel.data('node', node);
                $panel.show();
                if($preview) {
                  $preview.addClass('file_preview');
                  $files_content.append($preview);
                  if (data.permissions && data.permissions.download && $.isPreviewable(data.content_type)) {
                    $('#doc_preview_holder').loadDocPreview({
                      mimeType: data.content_type,
                      attachment_id: data.id,
                      height: '100%',
                      scribd_doc_id: data.scribd_doc && data.scribd_doc.attributes && data.scribd_doc.attributes.doc_id,
                      scribd_access_key: data.scribd_doc && data.scribd_doc.attributes && data.scribd_doc.attributes.access_key
                    });
                    files.viewFile(data.context_string, data.id);
                  }
                }
                $(window).triggerHandler('resize');
              } else if(node.hasClass('collaboration')) {
                var $panel = $("#collaboration_panel");
                $panel.find(".header .name").text(data.name);
                $panel.removeClass('to_be_hidden');
                var subdata = {
                  name: data.name,
                  updated_at: $.parseFromISO(data.updated_at).datetime_formatted,
                  collaborator_count: (data.collaborator_ids || "").split(",").length,
                  description: data.description,
                  collaborator_ids: data.collaborator_ids
                };
                $panel.find(".breadcrumb").empty().append(files.breadcrumb());
                var collaboration_url = $("." + data.context_string + "_collaboration_url").attr('href');
                collaboration_url = $.replaceTags(collaboration_url, 'id', data.id);
                $panel.find(".collaborations_link").attr('href', collaboration_url);
                $panel.find(".edit_collaboration_link").attr('href', collaboration_url);
                $panel.find(".delete_collaboration_link").attr('href', collaboration_url);
                $panel.find(".view_item_link").attr('href', collaboration_url);
                $panel.data('node', node);
                var $subpanel = $("#collaboration_sub_panel");
                $subpanel.find(".subcontent").fillTemplateData({data: subdata});
                $subpanel.removeClass('to_be_hidden');
                $subpanel.find(".subcontent .collaboration_icon").hide();
                $subpanel.find(".subcontent .google_docs_icon").showIf(data.collaboration_type == 'google_docs');
                $subpanel.find(".subcontent .etherpad_icon").showIf(data.collaboration_type == 'etherpad');
                $subpanel.find(".view_item_link").attr('href', collaboration_url);
                $subpanel.find(".collaborators").empty();
                var ids = (subdata.collaborator_ids || '').split(',');
                for(var idx in ids) {
                  var id = ids[idx];
                  var $user = $("." + data.context_string + "_user_list:first .collaborator_" + id).clone(true);
                  $user.find(":checkbox").remove();
                  $subpanel.find(".collaborators").append($user);
                }
                $files_content.find(".content_panel:last").after($subpanel); //.prepend($subpanel);
                $panel.show();
                $panel.removeClass('editable_content_panel');
                // show the collaboration control panel with description, link, etc.
                // show list of participants, delete (two possibles: delete for everyone, just take me off the ACL)
                if(data && data.permissions && data.permissions.update) {
                  // show a few more settings for editing, deleting
                  // managing list of participants
                  $panel.addClass('editable_content_panel');
                }
              }
            }
            if(!clearExtras.already_cleared) {
              clearExtras();
            }
          }
        });
        $("#files_structure_list > li.context").show();
        if($("#files_structure_list .context").length == 1) {
          files.expandFolder($("#files_structure_list .context"));
        }
      }, 500);
      $(window).bind('resize', function() {
        var top = $files_structure.offset().top;
        var height = $(window).height() - top;
        var spaceNeededForFooter = 142;
        var sectionTabsHeight = $("#section-tabs").height();

        $files_structure.height(Math.max(sectionTabsHeight, height - spaceNeededForFooter));
        $files_content.height(Math.max(sectionTabsHeight, height - spaceNeededForFooter));
        var contentHeight = $files_content.height();
        var panelHeight = $("#file_panel").outerHeight();
        $("#doc_preview_holder").height(contentHeight - panelHeight);
      });
      $(".folder_item .edit_collaboration_link, #collaboration_panel .edit_collaboration_link").click(function(event) {
        event.preventDefault();
        event.stopPropagation();
        $("#edit_collaboration_form").attr('action', $(this).attr('href'));
        $("#edit_collaboration_form").attr('method', 'PUT');
        $("#edit_collaboration_form .submit_button").text(I18n.t('buttons.update_collaboration', "Update Collaboration"));
        $("#edit_collaboration_form .add_collaboration").hide();
        if($files_content.find(".add_form:visible").length> 0) { return; };
        $files_content.children(".message").remove();
        var data = files.itemData($(this).parents(".folder_item,#collaboration_panel"));
        var context_string = data.context_string;
        $("#edit_collaboration_dialog").data('context_string', context_string);
        var $users = $("." + context_string + "_user_list:first").clone(true);
        var ids = (data.collaborator_ids || "").split(",");
        $("#edit_collaboration_form").fillFormData(data, {object_name: 'collaboration'});
        $users.find(".collaborator input").each(function() {
          $(this).attr('id', $(this).attr('class'));
          var id = $(this).parent("li.collaborator").getTemplateData({textValues: ['user_id']}).user_id;
          if($.inArray(id, ids) != -1) {
            $(this).attr('checked', true);
          }
        });

        $("#edit_collaboration_dialog .collaborator_list").empty().append($users);
        $("#edit_collaboration_dialog").dialog('close').dialog({
          autoOpen: false,
          title: I18n.t('titles.edit_collaboration', 'Edit Collaboration'),
          width: 500
        }).dialog('open');
      });
      $("#collaborations_panel .add_collaboration_link").click(function(event) {
        event.preventDefault();
        $("#edit_collaboration_form").attr('action', $(this).attr('href'));
        $("#edit_collaboration_form").attr('method', 'POST');
        $("#edit_collaboration_form .submit_button").text(I18n.t('buttons.add_collaboration', "Add Collaboration"));
        $("#edit_collaboration_form .add_collaboration").show();
        $("#collaboration_collaboration_type").triggerHandler('change');
        if($files_content.find(".add_form:visible").length> 0) { return; };
        $files_content.children(".message").remove();
        var data = files.itemData($("#collaborations_panel").data('node'));
        data.title = "";
        data.description = "";
        $("#edit_collaboration_form").fillFormData(data, {object_name: 'collaboration'});
        var context_string = data.context_string;
        $("#edit_collaboration_dialog").data('context_string', context_string);
        var $users = $("." + context_string + "_user_list:first").clone(true);
        $users.find(".collaborator input").each(function() {
          $(this).attr('id', $(this).attr('class'));
        });
        $("#edit_collaboration_dialog .collaborator_list").empty().append($users);
        $("#edit_collaboration_dialog").dialog('close').dialog({
          autoOpen: false,
          title: I18n.t('titles.add_collaboration', 'Add New Collaboration'),
          width: 500
        }).dialog('open');
      });
      $("#folder_panel .download_zip").click(function(event) {
        event.preventDefault();
        INST.downloadFolderFiles($(this).find(".download_zip_link").attr('href'));
      });
      $("#edit_collaboration_dialog").find(".select_all_link,.deselect_all_link").click(function(event) {
        event.preventDefault();
        var $link = $(this);
        $("#edit_collaboration_dialog .collaborator_list :checkbox").each(function() {
          $(this).attr('checked', $link.hasClass('select_all_link'));
        });
      });
      $("#edit_collaboration_dialog .cancel_button").click(function() {
        $("#edit_collaboration_dialog").dialog('close');
      });
      $("#edit_collaboration_form").formSubmit({
        beforeSubmit: function(data) {
          $(this).loadingImage();
        },
        success: function(data) {
          var context_string = $("#edit_collaboration_dialog").data('context_string');
          $("#edit_collaboration_dialog").dialog('close');
          files.updateCollaboration(context_string, data);
          $(this).loadingImage('remove');
        },
        error: function(data) {
          $(this).loadingImage('remove');
          $(this).formErrors(data);
        }
      });
      $("#collaboration_collaboration_type").change(function() {
        $("#edit_collaboration_dialog .collaboration_description").hide();
        $("#edit_collaboration_dialog #" + $(this).val() + "_description").show();
        $("#edit_collaboration_dialog .collaborate_data").show();
        $("#edit_collaboration_dialog .collaboration_authorization").hide();
        if($(this).val() == "google_docs" && $("#edit_collaboration_dialog #collaborate_authorize_google_docs").length > 0) {
          $("#edit_collaboration_dialog .collaborate_data").hide();
          $("#edit_collaboration_dialog #collaborate_authorize_google_docs").show();
        }
      }).triggerHandler('change');
      $(".folder_item .edit_item_content_link").click(function(event) {
        event.preventDefault();
        event.stopPropagation();
        var $item = $(this).parents(".folder_item,#file_panel,#folder_panel");
        var data = files.itemData($item);
        var url = $item.find(".download_url").attr('href');
        var display_name = $item.find(".name:first").text();
        var $dialog = $("#edit_content_dialog");
        $dialog.data('update_url', $item.find(".rename_item_link").attr('href')).data('content_type', data.content_type || '').data('filename', data.filename || 'file_to_update');
        $dialog.find(".display_name").text(display_name);
        $dialog.find(".loading_message").text("Loading File Contents...").show().end()
          .find(".content").hide();
        $dialog.dialog('close').dialog({
          autoOpen: false,
          width: 600,
          height: 410
        }).dialog('open');
        $.ajax({
          dataType: 'json',
          error: function() {
            $dialog.find(".loading_message").text(I18n.t('errors.loading_file', "Error Loading File Contents.  Please try again."));
          },
          success: function(data) {
            var body = data.body;
            $dialog.find("textarea").val(body);
            $dialog.find(".loading_message").hide().end()
              .find(".content").show();
            $dialog.find(".textarea").focus();
          },
          url: url.replace(/\/download/, "/contents")
        });
      });
      $("#edit_content_dialog .cancel_button").click(function() {
        $("#edit_content_dialog").dialog('close');
      });
      $("#edit_content_dialog .save_button").click(function() {
        var $dialog = $("#edit_content_dialog");
        $dialog.find("button").attr('disabled', false).filter(".save_button").text(I18n.t('buttons.update_file', "Update File"));
        $dialog.find("button").attr('disabled', true).filter(".save_button").text(I18n.t('messages.updating_file', "Updating File..."));
        var context_string = files.currentItemData().context_string;
        $.ajaxFileUpload({
          url: $dialog.data('update_url'),
          method: 'PUT',
          binary: false,
          data: {
            'attachment[uploaded_data]': {
              fake_file: true,
              name: $dialog.data('filename'),
              content_type: $dialog.data('content_type'),
              content: $dialog.find("textarea").val()
            }
          },
          success: function(data) {
            $dialog.find("button").attr('disabled', false).filter(".save_button").text(I18n.t('buttons.update_file', "Update File"));
            files.updateFile(context_string, data);
            $dialog.dialog('close');
          },
          error: function() {
            $dialog.find("button").attr('disabled', false).filter(".save_button").text(I18n.t('errors.update_file_failed', "Updating File Failed, please try again"));
          }
        });
      });
      $(".folder_item .preview_item_link").click(function(event) {
        event.preventDefault();
        event.stopPropagation();
        files.selectFolder($(this).parents(".folder_item").data('node'));
      });
      $(".folder_item .rename_item_link,#file_panel .rename_item_link,#folder_panel .rename_item_link").click(function(event) {
        event.preventDefault();
        event.stopPropagation();
        var $item = $(this).parents(".folder_item,#file_panel,#folder_panel");
        var name = $item.getTemplateData({textValues: ['name']}).name;
        $item.find(".name").hide()
          .after($("#rename_entry_field"));
          $("#rename_entry_field").val(name).focus().select();
        $(this).blur();
      });
      $("#rename_entry_field").bind('blur', function(event, update) {
        var $item = $(this).parents(".folder_item,#file_panel,#folder_panel");
        if($item.length === 0) { return; }
        var old_name = $item.getTemplateData({textValues: ['name']}).name;
        var new_name = $(this).val();
        if(update !== false && new_name != "" && old_name != new_name) {
          $item.find(".name").text(new_name);
          var data = files.itemData($item.data('node'));
          var context_string = data.root_context_string;
          if($item.hasClass('folder') || $item.attr('id') == 'folder_panel') {
            var url = $.replaceTags($("#file_context_links ." + context_string + "_folder_url").attr('href'), 'id', data.id);
            $.ajaxJSON(url, 'PUT', {'folder[name]': new_name}, function(data) {
              files.updateFolder(context_string, {folder: data.folder, already_in_place: true});
            }, function() {
            });
          } else {
            var url = $.replaceTags($("#file_context_links ." + context_string + "_attachment_url").attr('href'), 'id', data.id);
            $.ajaxJSON(url, 'PUT', {'attachment[display_name]': new_name}, function(data) {
              files.updateFile(context_string, data);
            }, function() {
            });
          }
        }
        $item.find(".name").show();
        $(this).val("").appendTo($("#file_context_links"));
        $(this).triggerHandler('blur', false);
      });
      $("#rename_entry_field").keycodes('return esc', function(event) {
        $(this).triggerHandler('blur', event.keyString == 'return');
      });
      $(".folder_item .delete_item_link,#folder_panel .delete_item_link,#file_panel .delete_item_link").click(function(event) {
        event.preventDefault();
        event.stopPropagation();
        var data = files.itemData($(this).parents(".folder_item"));
        data = data || files.itemData($(this).parents("#folder_panel,#file_panel").data('node'));
        var item_type = $(this).parents(".folder_item").hasClass('file') ? 'file' : 'folder';
        if($(this).parents(".folder_item").hasClass('collaboration')) { item_type = 'collaboration'; }
        $(this).parents(".folder_item").confirmDelete({
          message: ($(this).parents(".folder_item").hasClass('folder') || $(this).hasClass('folder_url') ? I18n.t('prompts.delete_folder', "Are you sure you want to delete this folder and all of its contents?") : I18n.t('prompts.delete_file', "Are you sure you want to delete this file?")),
          url: $(this).attr('href'),
          success: function() {
            if($files_structure.find(".file_" + data.id + ",.folder_" + data.id).filter(".active-node,.active-leaf").length > 0) {
              files.selectFolder($files_structure.find(".file_" + data.id + ",.folder_" + data.id).filter(".active-node,.active-leaf").parent("ul").parent("li"));
            }
            $files_structure.find(".file_" + data.id).prev("li.separator").remove();
            $files_structure.find(".file_" + data.id).remove();
            $files_structure.find(".folder_" + data.id).prev("li.separator").remove();
            $files_structure.find(".folder_" + data.id).remove();
            $files_structure.find(".collaboration_" + data.id).prev("li.separator").remove();
            $files_structure.find(".collaboration_" + data.id).remove();
            files.refreshView();
            files.updateQuota();
            $(this).slideUp(function() {
              $(this).remove();
            });
          }
        });
      });
      $(".folder_item:not(.add_item)").click(function(event) {
        var $item = $(this);
        event.preventDefault();
        if($files_content.filter(".dragging").length > 0) { return; }
        if($(this).find("#rename_entry_field").length > 0) { return; }
        event.stopPropagation();
        if($item.data('parent_node')) {
          files.expandFolder($item.data('parent_node'));
        }
        setTimeout(function() {
          if($item.hasClass('folder')) {
            files.expandFolder($item.data('node'));
            var refresh = function() {
              files.refreshView();
              $(this).unbind('files_load', refresh);
            };
            $item.data('node').bind('files_load', refresh);
            $item.data('node').children(".text").click();
          } else if($item.hasClass('collaboration')) {
            $item.data('node').children(".text").click();
          } else {
            $item.find(".name").focus();
            location.href = $item.find(".download_url").attr('href');
          }
        }, 50);
      });
      $(".folder_item").hover(function(event, scroll) {
        $(".folder_item_hover").removeClass('folder_item_hover');
        $(this).addClass('folder_item_hover');
      }, function() {
      });
      $("#folder_panel .add_file_link").click(function(event) {
        event.preventDefault();
        if($files_content.find(".add_form:visible").length> 0) { return; };
        var $form = $("#add_file_form").clone(true).removeAttr('id');
        $files_content.children(".message").remove();
        $files_content.append($form);
        $files_content.scrollToVisible($form);
        var itemData = files.currentItemData();
        $form.fillFormData({folder_id: itemData.id}, {object_name: 'attachment'});
        $form.find("form").attr('action', $("#file_context_links ." + itemData.context_string + "_attachments_url").attr('href') + ".text");
        $form.mouseover();
        $form.find(":text:first").focus().select();
      });
      $("#folder_panel .add_folder_link").click(function(event) {
        event.preventDefault();
        if($files_content.find(".add_form:visible").length> 0) { return; };
        var $form = $("#add_folder_form").clone(true).removeAttr('id');
        $files_content.children(".message").remove();
        $files_content.find("#folder_panel.addable_content_panel").after($form);
        $files_content.scrollToVisible($form);
        var itemData = files.currentItemData();
        $form.fillFormData({parent_folder_id: itemData.id}, {object_name: 'folder'});
        $form.find("form").attr('action', $("#file_context_links ." + itemData.context_string + "_folders_url").attr('href'));
        $form.mouseover();
        $form.find(":text:first").focus().select();
      });
      $("#add_folder_form :text").keycodes('esc', function(event) {
        if(event.keyString == 'esc') {
          $(this).trigger('blur', true);
        }
      });
      $("#add_folder_form :text").bind('blur', function(event, isFromEscKey) {
        if (isFromEscKey) {
          $(this).parents("li").remove();
        } else if ($.trim($(this).val())) {
          $(this).parents("form").trigger('submit');
        }
      });
      $("#add_folder_form .add_folder_form").formSubmit({
        beforeSubmit: function(data) {
          if($(this).hasClass('submitting')) { return false; }
          $(this).addClass('submitting');
          $(this).find(".name").show().text(data['folder[name]']);
          $(this).find(":text").hide();
          $(this).data('root_context_string', files.currentItemData().root_context_string);
        },
        success: function(data) {
          $(this).removeClass('submitting');
          for(var idx in fileStructureData) {
            if(fileStructureData[idx][0].context_string == $(this).data('root_context_string')) {
              fileStructureData[idx][1].folders.push(data);
            }
          }
          var folder = data.folder;
          var $folder = $files_structure.find(".folder_blank").clone(true).removeClass('folder_blank');
          $folder.addClass('folder folder_' + folder.id);
          $folder.fillTemplateData({data: {name: folder.name, id: folder.id}});
          var $parent = $files_structure.find(".folder_" + folder.parent_folder_id);

          $parent.children("ul").append("<li class='separator'/>");
          $parent.children("ul").append($folder.show());
          files.updateFolder($(this).data('root_context_string'), data);
          $(this).parents("li").remove();
          $folder.find('span').droppable(files.droppable_options);
          files.refreshView(folder);
        },
        error: function(data) {
          $(this).removeClass('submitting');
          $(this).formErrors(data);
        }
      });
      $("#add_file_form .add_file_form").formSubmit({
        fileUpload: true,
        beforeSubmit: function(data) {
          $(this).data('context_string', files.currentItemData().context_string);
          $(this).find(".loading_message").slideDown();
        },
        success: function(data) {
          $(this).parents("li").remove();
          files.updateFile($(this).data('context_string'), data);
          files.updateQuota();
        },
        error: function(data) {
          $(this).find(".loading_message").slideUp();
          $(this).formErrors(data);
        }
      });
      $("#add_file_form .cancel_button").click(function() {
        $(this).parents("li").remove();
      });

      $(".folder_item .lock_item_link,#file_panel .lock_item_link,#folder_panel .lock_item_link").click(function(event) {
        event.preventDefault();
        event.stopPropagation();
        var item_type = 'attachment';
        var $form = $("#lock_attachment_form");
        var $item = $(this).parents(".folder_item,#file_panel,#folder_panel");
        var data = files.itemData($item) || files.itemData($item.data('node'));
        var url = $(this).attr('href');
        if($item.hasClass('folder') || $(this).parents("#folder_panel").length > 0) {
          item_type = 'folder';
          $form = $("#lock_folder_form");
        }
        $form.attr('action', url);
        $form.data('context_string', data.context_string);
        $("#lock_item_dialog form").hide();
        $form.show();
        data.lock_at = $.parseFromISO(data.last_lock_at).datetime_formatted;
        data.unlock_at = $.parseFromISO(data.last_unlock_at).datetime_formatted;
        data.locked = (!data.lock_at && !data.unlock_at) ? '1' : '0';
        $("#lock_item_dialog").fillTemplateData({data: {name: data.name}});
        $form.fillFormData(data, {
          object_name: item_type
        });
        $form.find("#folder_just_hide,#attachment_just_hide").attr('checked', false).change();
        $form.find(".item_type").text(item_type);
        $("#lock_item_dialog").dialog('close').dialog({
          autoOpen: true,
          modal: true,
          width: 350,
          title: item_type == 'folder' ? I18n.t('titles.lock_folder', "Lock Folder") : I18n.t('titles.lock_file', 'Lock File')
        }).dialog('open');
      });
      $("#folder_just_hide,#attachment_just_hide").change(function() {
        $(this).parents("form").find(".full_lock").showIf(!$(this).attr('checked'));
        $(this).parents("form").find(".lock_checkbox").change();
      }).change();
      $("#lock_item_dialog .cancel_button").click(function() {
        $("#lock_item_dialog").dialog('close');
      });
      $("#lock_item_dialog .lock_checkbox").change(function() {
        $(this).parents("table").find(".lock_range").showIf(!$(this).attr('checked'));
      }).change();
      $("#lock_attachment_form").formSubmit({
        processData: function(data) {
          return data;
        },
        beforeSubmit: function(data) {
          $(this).loadingImage();
        },
        success: function(data) {
          $(this).loadingImage('remove');
          $("#lock_item_dialog").dialog('close');
          files.updateFile($(this).data('context_string'), data);
        }
      });
      $("#lock_folder_form").formSubmit({
        processData: function(data) {
          return data;
        },
        beforeSubmit: function(data) {
          $(this).loadingImage();
        },
        success: function(data) {
          $(this).loadingImage('remove');
          $("#lock_item_dialog").dialog('close');
          files.updateFolder($(this).data('context_string'), {folder: data.folder, already_in_place: true});
        }
      });
      $(".folder_item .unlock_item_link,#file_panel .unlock_item_link,#folder_panel .unlock_item_link").click(function(event) {
        event.preventDefault();
        event.stopPropagation();
        var item_type = 'attachment';
        var $form = $("#lock_attachment_form");
        var $item = $(this).parents(".folder_item,#file_panel,#folder_panel");
        var item_data = files.itemData($item) || files.itemData($item.data('node'));
        var url = $(this).attr('href');
        if($item.hasClass('folder') || $(this).parents("#folder_panel").length > 0) {
          item_type = 'folder';
          $form = $("#lock_folder_form");
          url = $item.find(".folder_url").attr('href');
        }
        $item.loadingImage();
        var data = {};
        data['[' + item_type + '][locked]'] = '';
        data['[' + item_type + '][hidden]'] = '';
        data['[' + item_type + '][lock_at]'] = '';
        data['[' + item_type + '][unlock_at]'] = '';
        $item.loadingImage();
        $.ajaxJSON(url, 'PUT', data, function(data) {
          $item.loadingImage('remove');
          if(item_type == 'attachment') {
            files.updateFile(item_data.context_string, data);
          } else {
            files.updateFolder(item_data.context_string, {folder: data.folder, already_in_place: true});
          }
        }, function(data) {
          $item.loadingImage('remove');
        });
      });

      if(location.hash === "" || location.hash == "#") {
        var text = $("#files_structure_list .context:first .name:first").text();
        location.href = "#" + encodeURIComponent(text);
      }
      $(document).fragmentChange(function(event, hash) {
        setTimeout(function() {
          files.selectNodeFromPath(hash.substring(1));
          $files_structure.scrollToVisible($("li.active-node,li.active-leaf").find("span.name").filter(":first"));
        }, 100);
      }).fragmentChange();

      setTimeout(function() {
        $(window).triggerHandler('resize');
        $("#file_swf").uploadify({
          fileDataName: 'file',
          uploader: '/flash/uploadify/uploadify.swf',
          buttonText: 'testing',
          folder: 'no_idea',
          script: 's3_url',
          scriptAccess: 'always',
          multi: true,
          auto: false,
          sizeLimit: 10737418240,
          simUploadLimit: 1,
          buttonText: "",
          hideButton: true,
          wmode: 'transparent',
          width: 60,
          height: 22,
          cancelImg: '/images/blank.png',
          onInit: function() {
            $add_file_link.text(I18n.t('links.add_files', "Add Files")).triggerHandler('show');
          },
          onSelect: fileUpload.swfFileQueue,
          onSelectOnce: fileUpload.swfFileQueueOnce,
          onCancel: fileUpload.swfCancel,
          onClearQueue: fileUpload.swfQueueClear,
          onError: fileUpload.swfFileError,
          onOpen: fileUpload.swfFileOpen,
          onProgress: fileUpload.swfFileProgress,
          onComplete: fileUpload.swfFileComplete,
          onAllComplete: fileUpload.swfQueueComplete
        });
      }, 1000);
    });

  })();

  var fileUpload = {
    ajaxUploadCount: 0,
    swfUploadCount: 0,
    queuedAjaxUploads: [],
    currentlyUploading: false,
    status_status: "hidden",
    status_request: "hidden",
    showStatus: function() {
      fileUpload.status_request = "shown";
      if(fileUpload.status_status == "hidden") {
        fileUpload.status_status = "showing";
        $("#file_uploads_progress").slideDown(null,null,function() {
          setTimeout(function() {
            fileUpload.status_status = "shown";
            if(fileUpload.status_request == "hidden") fileUpload.hideStatus();
          }, 3000);
        });
      }
    },
    hideStatus: function() {
      fileUpload.status_request = "hidden";
      if(fileUpload.status_status == "shown") {
        fileUpload.status_status = "hiding";
        $("#file_uploads_progress").slideUp(null,null,function() {
          fileUpload.status_status = "hidden";
          if(fileUpload.status_request == "shown") fileUpload.showStatus();
        });
      }
    },
    queueAjaxUpload: function(file, folder_id) {
      fileUpload.ajaxUploadCount = fileUpload.queuedAjaxUploads.length;
      var fileWrapper = {
        file: file,
        folder_id: folder_id,
        name: file.name
      };
      var $file = fileUpload.initFile(fileWrapper);
      $file.data('folder', files.currentItemData());
      $file.find(".status").text("Queued");
      fileUpload.queuedAjaxUploads.push(fileWrapper);
      fileUpload.updateUploadCount();
      fileUpload.uploadAjaxFiles();
    },
    uploadAjaxFiles: function(cycle) {
      if(fileUpload.currentlyUploading && !cycle) { return; }
      var file = fileUpload.queuedAjaxUploads.shift();
      if(!file) {
        fileUpload.currentlyUploading = false;
        fileUpload.ajaxUploadCount = 0;
        fileUpload.updateUploadCount();
      } else {
        fileUpload.currentlyUploading = true;
        var $file = fileUpload.initFile(file);
        $file.find(".status").text("Uploading");
        $file.find(".progress_bar").progressbar('value', 10);
        var folder = $file.data('folder');
        var fileData = file.file;
        $.ajaxFileUpload({
          url: $("." + folder.context_string + "_attachments_url").attr('href'),
          data: {
            'attachment[uploaded_data]': fileData,
            'attachment[display_name]': fileData.name,
            'attachment[folder_id]': folder.id,
            'duplicate_handling': file.file.duplicate_handling
          },
          method: 'POST',
          success: function(data) {
            setTimeout(function() {
              fileUpload.uploadAjaxFiles(true);
            }, 500);
            var attachment = data.attachment;
            var context_code = $.underscore(attachment.context_type) + "_" + attachment.context_id;
            $file.find(".cancel_upload_link").hide().end()
              .find(".status").text(I18n.t('messages.done_uploading', "Done uploading"));
            $file.addClass('done');
            setTimeout(function() {
              $file.slideUp(function() {
                $file.remove();
              });
            }, 5000);
            if (data.deleted_attachment_ids) {
              files.deleteAttachmentIds(data.deleted_attachment_ids);
            }
            files.updateFile(attachment.context_code, data);
          },
          error: function(data) {
            setTimeout(function() {
              fileUpload.uploadAjaxFiles(true);
            }, 500);
            $file.find(".status").text(I18n.t('#errors.failed', "Failed")).end()
              .find(".cancel_upload_link").hide();
          }
        });
      }
    },
    updateUploadCount: function() {
      fileUpload.ajaxUploadCount = fileUpload.queuedAjaxUploads.length;
      if(fileUpload.currentlyUploading) { fileUpload.ajaxUploadCount++; }
      var count = (fileUpload.swfFiles.length + fileUpload.ajaxUploadCount);
      var errorCount = $("#file_uploads .file_upload.errored:visible").length;
      if(count === 0 && errorCount == 0) {
        fileUpload.hideStatus();
        var $msg = $("#file_upload_blank").clone(true).removeAttr('id').addClass('finished_message').empty();
        $msg.text("Finished uploading all files");
        if(!$("#file_uploads .file_upload:visible:first").hasClass('finished_message')) {
          $("#file_uploads").prepend($msg);
          $msg.slideDown('fast');
        }
        $msg.addClass('finished_message');
        $msg.click(function() {
          $(this).slideUp(function() {
            $(this).remove();
          });
        });
        setTimeout(function() {
          $msg.slideUp(function() {
            $msg.remove();
          });
        }, 5000);
      } else {
        $("#file_uploads_dialog_link").text(I18n.t('messages.uploading_files', {one: "Uploading 1 File...", other: "Uploading %{count} Files..."}, { count: count}));
        if(count === 0) {
          $("#file_uploads_dialog_link").text(I18n.t('messages.error_count', {one: "1 Error", other: "%{count} Errors"}, { count: errorCount}));
        }
        fileUpload.showStatus();
      }
    },
    fileDialogComplete: function(numFilesSelected, numFilesQueued) {
      try {
        if (numFilesQueued > 0) {
          this.startUpload();
        }
      } catch (ex) {
        this.debug(ex);
      }
    },
    fileQueued: function(file) {
      var $file = fileUpload.initFile(file);
      $file.data('folder', files.currentItemData());
      $file.find(".status").text(I18n.t('messages.queue', "Queued"));
      fileUpload.updateSwfUploadCount(this.getStats().files_queued);
    },
    fileQueueError: function(file, error, message) {
      var $file = fileUpload.initFile(file);
      $file.find(".status").text(I18n.t('errors.failed', "Failed")).end()
        .find(".cancel_upload_link").hide();
      $file.append(message);
    },
    swfPreQueued: [],
    swfQueuedAndPendingFiles: [],
    swfFiles: [],
    swfFileQueueOnce: function(event, data) {
      var queue = fileUpload.swfPreQueued;
      fileUpload.swfPreQueued = [];
      var folder = files.currentItemData();
      var filenames = [];
      for (idx in queue) {
        filenames.push(queue[idx].name);
      }
      files.preflight(folder.id, folder.context_string, filenames,
        function(method) {
          for (idx in queue) {
            queue[idx].duplicate_handling = method;
          }
        },
        function() {
          for (idx in queue) {
            var file = queue[idx];
            fileUpload.swfFileQueueReal(event, file.id, file);
          }
        },
        function() {
          for (idx in queue) {
            $("#file_swf").uploadifyCancel(queue[idx].id);
          }
        }
      );
    },
    swfFileQueue: function(event, id, file) {
      file.id = id;
      fileUpload.swfPreQueued.push(file);
    },
    swfFileQueueReal: function(event, id, file) { //onSelect
      file.id = id;
      var $file = fileUpload.initFile(file);
      $file.data('folder', files.currentItemData());
      $file.find(".status").text(I18n.t('messages.queued', "Queued"));
      fileUpload.swfFiles.push(file);
      var folder = $file.data('folder');
      var post_params = {
        'attachment[folder_id]': folder.id,
        'attachment[filename]': file.name,
        'attachment[context_code]': folder.context_string,
        'no_redirect': true,
        'attachment[duplicate_handling]': file.duplicate_handling
      };
      $("#file_swf").uploadifySettings('folder', '' + folder.id);
      fileUpload.updateUploadCount();
      $.ajaxJSON('/files/pending', 'POST', post_params, function(data) {
        file.upload_url = data.proxied_upload_url || data.upload_url;
        // It seems that the swf uploader is unencoding some of these params, so we need
        // to encode them now.
        data.upload_params.key = encodeURIComponent(data.upload_params.key);
        data.upload_params.Signature = encodeURIComponent(data.upload_params.Signature);
        file.upload_params = data.upload_params;
        $file.data('success_url', data.success_url);
        if(!$file.hasClass('done')) {
          fileUpload.swfQueuedAndPendingFiles.push(file);
          fileUpload.swfUploadNext();
        }
        fileUpload.updateUploadCount();
      }, function(data) {
        $.flashError(
          data && data.base && data.base.match(/quota/) ?
          data.base :
          I18n.t('upload_error', 'There was an error uploading your file')
        );
        $("#file_swf").uploadifyCancel(id);
        $file.find(".cancel_upload_link").hide().end()
          .find(".status").text("Upload Failed");
      }, {skipDefaultError: true});
    },
    swfUploadNext: function() {
      if(fileUpload.swfQueuedAndPendingFiles.length > 0) {
        file = fileUpload.swfQueuedAndPendingFiles.shift();
        if(file) {
          $("#file_swf").uploadifySettings('script', file.upload_url);
          $("#file_swf").uploadifySettings('scriptData', file.upload_params);
          $("#file_swf").uploadifyUpload(file.id);
        }
      }
      fileUpload.updateUploadCount();
    },
    swfCancel: function(event, id, file, data) { // onCancel
      file.id = id;
      var $file = fileUpload.initFile(file);
      $("#file_uploads_dialog_link").text(I18n.t('errors.uploading', "Uploading Error"));
      $file.addClass('done');
      if(!$file.hasClass('errored') && !$file.hasClass('error_cancelled')) {
        $file.find(".cancel_upload_link").hide().end()
          .find(".status").text("Canceled");
        fileUpload.swfFiles = $.grep(fileUpload.swfFiles, function(f) { return f.id != file.id; });
      }
      fileUpload.swfUploadNext();
      return false;
    },
    swfQueueClear: function(event, data) { // onClearQueue
    },
    swfFileError: function(event, id, file, error, cancelable) { // onError
      cancelable = typeof(cancelable) != 'undefined' ? cancelable : true;
      file.id = id;
      if (error.info == 201 && error.type == "HTTP") {
        // As of Chrome 21 on Windows, uploadify seems to be calling the error callback when
        // the upload succeeds. Luckily we can see the success in the error code here and
        // intercept it.
        fileUpload.s3Success(file);
        return;
      }
      var $file = fileUpload.initFile(file);
      setTimeout(function() {
        $file.addClass('error_cancelled');
        if(cancelable) $("#file_swf").uploadifyCancel(id);
      }, 50);
      fileUpload.swfFiles = $.grep(fileUpload.swfFiles, function(f) { return f.id != file.id; });
      $("#file_uploads_dialog_link").text(I18n.t('errors.uploading', "Uploading Error"));
      fileUpload.showStatus();
      $file.find(".cancel_upload_link").hide().end()
        .find(".status").text(I18n.t('errors.failed_uploading', "Failed uploading: %{error_info}", {error_info: error.info}));
      $file.addClass('done').addClass('errored');
      fileUpload.swfUploadNext();
      return false;
    },
    swfFileOpen: function(event, id, file) { // onOpen
      file.id = id;
      var $file = fileUpload.initFile(file);
      if(file.upload_url) $("#file_swf").uploadifySettings('script', file.upload_url);
      if(file.upload_params) $("#file_swf").uploadifySettings('scriptData', file.upload_params);
      fileUpload.swfQueuedAndPendingFiles = $.grep(fileUpload.swfQueuedAndPendingFiles, function(f) { return f.id != file.id; });
      $file.find(".progress_bar").progressbar('value', 1);
      $file.find(".status").text(I18n.t('messages.uploading', "Uploading"));
    },
    swfFileProgress: function(event, id, file, data) { // onProgress
      file.id = id;
      var $file = fileUpload.initFile(file);
      $file.find(".status").text(I18n.t('messages.uploading_with_speed', "Uploading (%{speed}KB/s)", {speed: parseInt(data.speed, 10)}));
      $file.find(".cancel_upload_link").showIf(data.percentage < 100);
      $file.find(".progress_bar").progressbar('value', data.percentage);
    },
    s3Success: function(file) {
      var $file = fileUpload.initFile(file);
        $file.find(".status").text(I18n.t('messages.finalizing', "Finalizing"));
        var errored = function() {
          fileUpload.swfFileError({}, file.id, file, {type: "server", info: I18n.t('errors.unexpected_response', "didn't get back expected response")});
        };
        $.ajaxJSON($file.data('success_url'), 'GET', {}, function(data) {
          if(data && data.attachment) {
            fileUpload.swfFileComplete({}, file.id, file, JSON.stringify(data), {});
            if (data.deleted_attachment_ids) {
              files.deleteAttachmentIds(data.deleted_attachment_ids);
            }
          } else {
            errored();
          }
        }, errored);
    },
    swfFileComplete: function(event, id, file, response, data) { // onComplete
      file.id = id;
      if(response.indexOf("<PostResponse>") >= 0) {
        // we just got back XML stuff from S3. that means success (?)
        fileUpload.s3Success(file);
        return;
      }
      var $file = fileUpload.initFile(file);
      fileUpload.swfFiles = $.grep(fileUpload.swfFiles, function(f) { return f.id != file.id; });
      $file.find(".status").text(I18n.t('messages.upload_complete', "Done uploading"));
      $file.find(".cancel_upload_link").remove();
      $file.find(".progress_bar").progressbar('value', 100);
      $file.addClass('done');
      var context_string = $file.data('folder').context_string;
      setTimeout(function() {
        $file.slideUp(function() {
          $file.remove();
        });
      }, 5000);
      if(response) {
        try {
          var data = $.parseJSON(response);
          if("errors" in data && !jQuery.isEmptyObject(data["errors"])) {
            fileUpload.swfFileError(event, id, file, {type: "server", info: JSON.stringify(data["errors"])}, false);
          } else {
            data.swf = true;
            setTimeout(function() {
              if (data.deleted_attachment_ids) {
                files.deleteAttachmentIds(data.deleted_attachment_ids);
              }
              files.updateFile(context_string, data);
            }, 500);
          }
        } catch(e) {
          fileUpload.swfFileError(event, id, file, {type: "JS", info: e.toString()}, false);
        }
      } else {
        $file.find(".status").text(I18n.t('warnings.file_uploaded_without_response', "File may have uploaded, but the server failed to respond.  Reload the page to confirm."));
      }
      fileUpload.swfUploadNext();
    },
    swfQueueComplete: function(event, data) { // onAllComplete
      fileUpload.updateUploadCount();
    },
    initFile: function(file) {
      if(!file.id) {
        file.id = "tmp_" + Math.round(Math.random() * 9999);
      }
      var $file = $("#file_upload_" + file.id);
      if($file.length === 0) {
        $file = $("#file_upload_blank").clone(true).attr('id', "file_upload_" + file.id);
        $("#file_uploads").append($file);
        $file.find(".progress_bar").progressbar();
        $file.click(function(event) {
          if($(this).find(".cancel_upload_link:visible").length === 0 && $(this).hasClass('done')) {
            event.preventDefault();
            $(this).slideUp(function() {
              $(this).remove();
              fileUpload.updateUploadCount();
            });
          }
        });
        $file.find(".cancel_upload_link").click(function(event) {
          event.preventDefault();
          var id = ($(this).parents(".file_upload").attr('id') || "").substring(12);
          $("#file_swf").uploadifyCancel(file.id);
        });
      }
      $file.find(".file_name").text(file.name);
      $file.slideDown('fast');
      return $file;
    },
    attempt: 0,
    file_details: {}
  };
});

