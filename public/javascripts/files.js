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

/* global currentFolder, folderObjectList, */
var iconFileTypes = {
  "text_plain": "Plain Text",
  "application_msword": "Word Document",
  "application_vnd.ms-excel": "Excel Spreadsheet",
  "application_vnd.ms-powerpoint": "PowerPoint Presentation",
  "application_pdf": "Adobe PDF"
};
var swfUpload;
var files = {
  folderStructure: {},
  folderObjects: {},
  processFolderObjects: function() {
    files.folderObjects = {};
    files.folderStructure = {};
    for(var i in folderObjectList) {
      if(folderObjectList[i]) {
        var folderObject = folderObjectList[i].folder;
        files.folderObjects[folderObject.full_name] = folderObject;
        var folders = folderObject.full_name.split("/");
        var folder = files.folderStructure;
        for(var idx = 0; idx < folders.length; idx++) {
          if(!folder[folders[idx]]) {
            folder[folders[idx]] = {};
          }
          folder = folder[folders[idx]];
        }
      }
    }
  },
  getFolderNames: function(folderName) {
    if(!folderName) {
      folderName = "";
    }
    var folders = folderName.split("/");
    var folder = files.folderStructure;
    if(folderName && folderName != "") {
      for(var idx = 0; idx < folders.length; idx++) {
        if(!folder[folders[idx]]) {
          return [];
        }
        folder = folder[folders[idx]];
      }
    }
    var result = [];
    for(var name in folder) {
      result.push(name);
    }
    return result.sort();
  },
  updateFolderObject: function(folderData) {
    var newList = [];
    var found = false;
    for(var idx in folderObjectList) {
      var folder = folderObjectList[idx].folder;
      if(folder.id == folderData.id) {
        found = true;
        newList.push({folder: folderData});
      } else {
        newList.push({folder: folder});
      }
    }
    if(!found) {
      newList.push({folder: folderData});
    }
    folderObjectList = newList;
    files.processFolderObjects();
  },
  deleteFolderObject: function(full_name) {
    var newList = [];
    var found = false;
    for(var idx in folderObjectList) {
      var folder = folderObjectList[idx].folder;
      if(folder.full_name.indexOf(full_name) == 0) {
      } else {
        newList.push(folder);
      }
    }
    folderObjectList = newList;
    files.processFolderObjects();
  },
  addFolder: function(folderData) {
    var name = folderData && folderData.full_name;
    if(!name || name == "") {
      return false;
    }
    files.updateFolderObject(folderData);
    var folders = name.split("/");
    var folder = files.folderStructure;
    for(var idx = 0; idx < folders.length - 1; idx++) {
      if(!folder[folders[idx]]) {
        return false;
      }
      folder = folder[folders[idx]];
    }
    var folderName = folders[folders.length - 1];
    if(!folder[folderName]) {
      folder[folderName] = {};
    }

    var $folder = $("#folder_content_folder").clone(true);
    folderData.lock_at = (Date.parse(folderData.lock_at) || "").toString($.datetime.defaultFormat);
    folderData.unlock_at = (Date.parse(folderData.unlock_at) || "").toString($.datetime.defaultFormat);
    folderData.last_lock_at = (Date.parse(folderData.last_lock_at) || "").toString($.datetime.defaultFormat);
    folderData.last_unlock_at = (Date.parse(folderData.last_unlock_at) || "").toString($.datetime.defaultFormat);
    $folder.fillTemplateData({
      data: folderData,
      id: 'folder_content_' + folderData.id,
      hrefValues: ['id']
    });
    $folder.find(".edit_item_link").showIf(folderData.permissions && folderData.permissions.update);
    $folder.find(".delete_item_link").showIf(folderData.permissions && folderData.permissions['delete']);
    $folder.toggleClass('folder_locked', folderData.permissions && !folderData.permissions['read_contents']);
    $folder.toggleClass('currently_locked_folder', !!folderData.currently_locked);
    if(folderData.permissions && folderData.permissions.update) {
      $folder.draggable(files.draggable_options);
    }
    $folder.droppable(files.droppable_options);
    
    var $before = null;
    $("#folder_content .content_item").each(function() {
      if($(this).hasClass('file') || $(this).find(".name").text() > folderData.name) {
        $before = $(this);
        return false;
      }
    });
    if($before) {
      $before.before($folder);
    } else {
      $("#folder_content").append($folder);
    }
    
    files.refreshFolder($("#folder_" + folderData.id));
    return folder[folderName];
  },
  renameFolder: function(oldDir, newDir) {
    if(!oldDir || oldDir == "") { 
      return;
    }
    var re = new RegExp("^" + oldDir);
    for(var idx in folderObjectList) {
      var folder = folderObjectList[idx].folder;
      if(folder.full_name.match(re)) {
        folder.full_name = folder.full_name.replace(re, newDir);
        folderObjectList[idx].folder = folder;
      }
    }
    files.processFolderObjects();
    var folderData = files.folderObjects[oldDir] || files.folderObjects[newDir];
    var oldFolders = oldDir.split("/");
    var newFolders = newDir.split("/");
    var name = newFolders[newFolders.length - 1];
    folderData.name = name;
    $("#folder_" + oldDir.replace(/[\/ ]/g, "_"))
      .attr('id', "folder_" + folderData.id)
      .find(".folder_name").text(name);
    $("#folder_" + folderData.id).find(".folder_name").text(name);
    files.folderLookupCache[newDir] = files.folderLookupCache[oldDir];
    delete files.folderLookupCache[oldDir];
  },
  moveFolder: function($folder, oldFolderName, newFolderName) {
    $folder.dim();
    var folderName = $folder.getTemplateData({textValues: ['name']}).name;
    var url = $folder.find(".folder_url").attr('href');
    if(files.folderObjects[newFolderName] && files.folderObjects[newFolderName].id) {
      var data = {'folder[parent_folder_id]': files.folderObjects[newFolderName].id};
      $.ajaxJSON(url, 'PUT', data, function(data) {
        $folder.remove();
        files.renameFolder(oldFolderName + '/' + folderName, newFolderName + '/' + folderName);
        files.deselectFolderItem(true);
        files.checkFolderContent();
        files.refreshFolder($("#folder_" + files.folderObjects[oldFolderName].id));
        files.refreshFolder($("#folder_" + files.folderObjects[newFolderName].id));
        files.selectFolder($("#folder_" + files.folderObjects[currentFolder].id));
      });
    }
  },
  moveFile: function($file, oldFolderName, newFolderName) {
    $file.dim();
    var url = $file.find(".attachment_url").attr('href');
    var data = {};
    if(!files.folderLookupCache[oldFolderName]) {
      files.folderLookupCache[oldFolderName] = [];
    }
    var oldSpot = files.folderLookupCache[oldFolderName];
    var oldList = [];
    for(var i = 0; i < oldSpot.length; i++) {
      if($file.attr('id') != "folder_file_" + oldSpot[i].attachment.id) {
        oldList.push(oldSpot[i]);
      } else {
        if(!files.folderLookupCache[newFolderName]) {
          files.folderLookupCache[newFolderName] = [];
        }
        oldSpot[i].attachment.folder_name = newFolderName;
        files.folderLookupCache[newFolderName].push(oldSpot[i]);
      }
    }
    files.folderLookupCache[oldFolderName] = oldList;
    data['attachment[folder_id]'] = files.folderObjects[newFolderName].id;
    $.ajaxJSON(url, "PUT", data, function(data) {
      var attachment = data.attachment;
      $file.remove();
      files.deselectFolderItem(true);
      files.checkFolderContent();
      files.addAttachment(attachment);
    });
  },
  getFolderName: function($folder) {
    var folder = $folder.attr('title');
    var $obj = $folder;
    if($obj.parents(".folder_content").length > 0) {
      $obj = $("#folders .folder_name.selected");
    }
    while($obj.parents(".folder").length > 0) {
      $obj = $obj.parents(".folder");
      var tail = folder ? '/' + folder : "";
      folder = $obj.attr('title') + tail;
    }
    return folder;
  },
  refreshFolder: function($folder) {
    if($folder.length === 0) { return; }
    var folder = files.getFolderName($folder);
    files.hideEditFile();
    files.hideEditFolder();
    var $children = $folder.children(".folder_list");
    $children.empty();
    var names = files.getFolderNames(folder);
    for(var idx in names) {
      var name = names[idx];
      var $subfolder = $("#folder_blank").clone(true);
      $subfolder.attr('title', name);
      $subfolder.find(".folder_name").text(name);
      var folderData = files.folderObjects[folder + "/" + name];
      $subfolder.toggleClass('folder_locked', folderData.permissions && !folderData.permissions['read_contents']);
      $subfolder.toggleClass('currently_locked_folder', !!folderData.currently_locked);
      $subfolder.attr('id', 'folder_' + folderData.id);
      $subfolder.find(".folder_name").droppable(files.droppable_options);
      $children.append($subfolder.show());
    }
    if(files.folderObjects[currentFolder]) {
      var $name = $("#folder_" + files.folderObjects[currentFolder].id + " .folder_name");
      if(!$name.hasClass('selected')) {
        $name.addClass('selected');
      }
    }
  },
  toggleSubfolder: function($folder, forceShow) {
    files.refreshFolder($folder);
    if($folder.hasClass('folder_locked')) { return; }
    if(forceShow) {
      $folder.children(".folder_name").addClass('open').end()
        .children(".folder_list").show();
    } else {
      $folder.children(".folder_name").toggleClass('open').end()
        .children(".folder_list").toggle();
    }
  },
  folderLookupCache: {},
  openFolder: function(folderName) {
    var folders = [];
    if(files.folderObjects[folderName]) {
      var folder = files.folderObjects[folderName];
      while(folder && folder.parent_folder_id) {
        folders.unshift(folder.parent_folder_id);
        var new_folder = null;
        for(var idx in files.folderObjects) {
          if(files.folderObjects[idx].id == folder.parent_folder_id) {
            new_folder = files.folderObjects[idx];
          }
        }
        folder = new_folder;
      }
      for(var idx in folders) {
        var $folder = $("#folder_" + folders[idx]);
        if(!$folder.find(".folder_name").hasClass('open')) {
          files.toggleSubfolder($folder, true);
        }
      }
      var $folder = $("#folder_" + files.folderObjects[folderName].id);
      if($folder.length > 0) {
        files.selectFolder($folder);
      }
    }
  },
  selectFolder: function($folder) {
    if($folder.hasClass('selected') || $folder.hasClass('related')) {
      return;
    }
    var $content = $("#folder_content");
    files.deselectFolderItem(true);
    files.hideEditFile();
    files.hideEditFolder();
    var folderName = files.getFolderName($folder);
    if(folderName == currentFolder) { return; }
    currentFolder = folderName;
    location.hash = "#" + currentFolder;
    $("#edit_file_form :input.folder_name").val(currentFolder);
    $("#folders .folder_name.selected").removeClass('selected').removeClass('related');
    $("#tags .tag.selected").removeClass('selected');
    $folder.children('.folder_name').addClass('selected');
    if($folder.hasClass('folder_locked')) {
      $content.find(".content_item").remove().end()
        .find(".no_content_message").hide().end()
        .find(".locked_content_message").show();
      return;
    }
    $content.find(".content_item").remove().end()
      .find(".locked_content_message").hide().end()
      .find(".no_content_message").hide();
    var subfolderNames = files.getFolderNames(folderName);
    var subfolderList = [];
    for(var i in subfolderNames) {
      subfolderList.push(subfolderNames[i]);
    }
    subfolderList.sort();
    for(var i in subfolderList) {
      var name = subfolderList[i];
      var data = files.folderObjects[folderName + "/" + name];
      files.addFolder(data);
    }
    $content.loadingImage({horizontal: "right"});
    var addedFiles = {};
    var url = $(".list_folder_url").attr('href') + escape(files.folderObjects[folderName].id);
    if(files.folderLookupCache[folderName]) {
      var data = files.folderLookupCache[folderName];
      for(var i = 0; i < data.length; i++) {
        var attachment = data[i].attachment;
        addedFiles[attachment.id] = attachment.id;
        files.addAttachment(attachment);
      }
    }
    files.checkFolderContent(true);
    $("#folder_content").sortable('refresh');
    $.ajaxJSON(url, "GET", {}, function(data) {
      if(currentFolder != folderName) { return; }
      $content.loadingImage('remove');
      for(var i = 0; i < data.length; i++) {
        var attachment = data[i].attachment;
        files.addAttachment(attachment);
        delete addedFiles[attachment.id];
      }
      for(var idx in addedFiles) {
        $("#folder_file_" + idx).remove();
      }
      files.checkFolderContent();
      files.folderLookupCache[folderName] = data;
      $("#folder_content").sortable('refresh');
    });
  },
  addAttachment: function(attachment) {
    var $content = $("#folder_content");
    if($content.find("#folder_file_" + attachment.id).length > 0) {
      return;
    }
    var validUnfiled = currentFolder == 'unfiled' && !attachment.folder_id;
    if(attachment.folder_id != files.folderObjects[currentFolder].id && !validUnfiled) { return; }
    var $obj = $("#folder_content_file").clone(true);
    attachment.name = attachment.display_name;
    attachment.size = attachment.readable_size;
    attachment.lock_at = (Date.parse(attachment.lock_at) || "").toString($.datetime.defaultFormat);
    attachment.unlock_at = (Date.parse(attachment.unlock_at) || "").toString($.datetime.defaultFormat);
    attachment.last_lock_at = (Date.parse(attachment.last_lock_at) || "").toString($.datetime.defaultFormat);
    attachment.last_unlock_at = (Date.parse(attachment.last_unlock_at) || "").toString($.datetime.defaultFormat);
    if(attachment.scribd_doc && attachment.scribd_doc.attributes && attachment.permissions && attachment.permissions.download) {
      attachment.document_id = attachment.scribd_doc.attributes.doc_id;
      attachment.access_key = attachment.scribd_doc.attributes.access_key;
    }
    
    $obj.fillTemplateData({
      data: attachment,
      id: "folder_file_" + attachment.id,
      hrefValues: ['id']
    });
    $obj.find(".preview_item_link").showIf(attachment.permissions && attachment.permissions.download && attachment.workflow_state != 'errored' && attachment.scribd_doc && attachment.scribd_doc.attributes);
    $obj.find(".edit_item_link").showIf(attachment.permissions && attachment.permissions['update']);
    $obj.find(".reorder_item_link").showIf(attachment.permissions && attachment.permissions['update']);
    $obj.find(".delete_item_link").showIf(attachment.permissions && attachment.permissions['delete']);
    $obj.toggleClass('locked', attachment.permissions && !attachment.permissions.download);
    $obj.toggleClass('currently_locked', !!attachment.currently_locked);
    if(attachment.permissions && attachment.permissions['update']) {
      $obj.addClass('draggable');
      $obj.draggable(files.draggable_options);
    }
    var $before = null;
    $content.find(".file").each(function() {
      var name = $(this).find(".name").text();
      var position = $(this).getTemplateData({textValues: ['position']}).position || 9999;
      if(position > attachment.position || (position == attachment.position && name > attachment.display_name)) {
        $before = $(this);
        return false;
      }
    });
    if(!$before) {
      $content.append($obj.show());
    } else {
      $before.before($obj.show());
    }
    $content.find(".no_content_message").hide().end()
      .find(".locked_content_message").hide();
  },
  selectTag: function($tag) {
    if($tag.hasClass('selected')) {
      return;
    }
    files.hideEditFile();
    files.hideEditFolder();
    $("#folders .folder_name.selected").removeClass('selected').removeClass('related');
    $("#tags .tag.selected").removeClass('selected');
    $tag.addClass('selected');
    var $content = $("#folder_content");
    $content.empty();
    for(var i = 0; i < 20; i++) {
      var $obj = $("#folder_content_file").clone(true);
      $obj.addClass('file_item').attr('id', 'folder_content_' + i)
        .find(".name").text("Testing");
      
      $obj.draggable(files.draggable_options);
      $content.append($obj.show());
    }
  },
  selectFolderItem: function($item) {
    if($item.hasClass('selected')) {
      return;
    }
    files.hideEditFile();
    files.hideEditFolder();
    files.deselectFolderItem(true);
    $item.addClass('selected');
    $("#folders .folder_name.selected").addClass('related');
    $("#selection_details .details").hide();
    var url = "#";
    $("#selection_details .edit_link").showIf($item.find(".edit_item_link").css('display') != 'none');
    $("#selection_details .delete_link").showIf($item.find(".delete_item_link").css('display') != 'none');
    if($item.hasClass('folder')) {
      $("#folder_details").show();
      var data = $item.getTemplateData({textValues: ['name', 'lock_at', 'unlock_at']});
      $("#folder_details").find(".lock_at").text(data.lock_at || "").end()
        .find(".unlock_at").text(data.unlock_at || "");
      $("#folder_details").find(".current_folder_name").text(data.name).end()
        .find(".current_folder_preview").showIf($item.hasClass('folder_locked') || $item.hasClass('currently_locked_folder')).end()
        .find(".current_folder_preview .lock_until").showIf(data.unlock_at).end()
        .find(".current_folder_preview .lock_after").showIf(data.lock_at).end()
        .find(".lock_item_link").showIf(!$item.hasClass('folder_locked') && !$item.hasClass('currently_locked_folder')).end()
        .find(".unlock_item_link").showIf($item.hasClass('folder_locked') || $item.hasClass('currently_locked_folder'));
    } else {
      var $details = $("#file_details");
      $details.show();
      var data = $item.getTemplateData({textValues: ['name', 'content_type', 'size', 'id', 'lock_at', 'unlock_at']});
      $details.find(".lock_item_link").showIf(!$item.hasClass('locked') && !$item.hasClass('currently_locked')).end()
        .find(".unlock_item_link").showIf($item.hasClass('locked') || $item.hasClass('currently_locked'));

      data.content_type = data.content_type || "";
      if(data.id && $("#image_cache_" + data.id).length > 0) {
        $details.find(".current_file_preview .image_cache").hide().appendTo($("body"));
        var $img = $("#image_cache_" + data.id);
        $details.find(".current_file_preview").showIf(data.content_type.indexOf("image") != -1)
          .find("img.image_preview").hide().end()
          .find(".download_item_link").append($img.css('display', 'inline'));
      } else {
        $details.find(".current_file_preview .image_cache").hide().appendTo($("body"));
        if(data.content_type.indexOf("image") != -1) {
          $details.find(".current_file_preview").show()
            .find("img.image_preview").show().attr("src", $(".preview_loading_image").attr("src")).attr("src", $item.find(".preview_url").attr("href"))
            .attr('title', 'image');
        } else if(iconFileTypes[data.content_type.replace(/\//g, "_")]) {
          mime_type = data.content_type.replace(/\//g, "_");
          $details.find(".current_file_preview").show()
            .find("img.image_preview").show().attr("src", "/images/mime_types/" + mime_type + ".png")
            .attr('title', iconFileTypes[mime_type]);
        } else {
          $details.find(".current_file_preview").hide()
            .find("img.preview").show().attr("src", "/images/mime_types/unknown.png")
            .attr('title', '');
        }
        var $img = $details.find(".current_file_preview").find("img.image_preview").clone(true);
        $img.removeClass('image_preview').addClass('image_cache').hide().attr('id', 'image_cache_' + data.id).appendTo($("body"));
      }
      $details.find(".current_file_preview img.locked").showIf($item.hasClass('locked'));
      var $file_details_link = $item.find(".attachment_url").clone().text("Click here for more details.");
      $details.find(".cant_download")
        .find(".attachment_url").remove().end()
        .append($file_details_link)
        .showIf($item.hasClass('locked'));
      $details.find(".download_item_link").showIf(!$item.hasClass('locked'));
      $details.find(".currently_locked").showIf($item.hasClass('currently_locked')).end()
        .find(".currently_locked .lock_until").showIf(data.unlock_at).end()
        .find(".currently_locked .lock_after").showIf(data.lock_at).end()
        .find(".lock_at").text(data.lock_at || "").end()
        .find(".unlock_at").text(data.unlock_at || "");
      $details.find(".current_file_name").text(data.name);
      $details.find(".current_file_size").text(data.size);
      url = $item.find(".download_url").attr('href');
    }
    $("#selection_details .download_item_link").attr('href', url);
  },
  deselectFolderItem: function(forceIt) {
    var formVisible = false;
    if(!forceIt) {
      $("#folder_content li.content_item.selected").each(function() {
        if($(this).find("form").length > 0) {
          formVisible = true;
          return false;
        }
      });
    }
    if(!formVisible) {
      $("#folder_content li.content_item.selected").removeClass('selected');
      $("#selection_details .details").hide();
    }
  },
  editFolder: function($folder) {
    files.hideEditFile();
    files.hideEditFolder();
    if($folder.find(".edit_item_link").css('display') == 'none') { return; }
    $("#folder_content .content_item.selected").removeClass('selected');
    $folder.addClass('selected');
    $folder.find(".name").hide().end()
      .find(".links").hide();
    var buttonMsg = "Save";
    if($folder.attr('id') == 'folder_new') {
      buttonMsg = "Add";
    }
    var $form = $("#edit_folder_form").clone(true);
    if($folder.attr('id') == 'folder_new') {
      $form.attr('method', 'POST').attr('action', $(".new_folder_url").attr('href'));
    } else {
      $form.attr('method', 'PUT').attr('action', $folder.find('.folder_url').attr('href'));
    }
    $form.find(".submit_button").text(buttonMsg);
    var data = $folder.getTemplateData({textValues: ['name']});
    data['folder[parent_folder_id]'] = files.folderObjects[currentFolder].id;
    $form.fillFormData(data, {object_name: 'folder'});
    $folder.append($form.show());
    $form.find(":text:first").focus().select();
  },
  hideEditFolder: function() {
    var $obj = $("#edit_folder_form").parents(".folder:first");
    $obj.find(".name").show().end()
      .find(".links").css('display', '')
      .children("a").css('display', '');//show();
    $("#content").append($("#edit_folder_form").hide());
    if($obj.attr('id') == 'folder_new') {
      $obj.remove();
    }
  },
  editFile: function($file, showUpload) {
    files.hideEditFile();
    files.hideEditFolder();
    if($file.find(".edit_item_link").css('display') == 'none') { return; }
    if(!showUpload) { showUpload = false; }
    files.deselectFolderItem(true);
    $file.addClass('selected').find(".name").hide().end()
      .find(".links").hide();
    var buttonMsg = "Save";
    if($file.attr('id') == 'file_new') {
      buttonMsg = "Add";
    }
    var $form = $("#edit_file_form").clone(true);
    $form.addClass('edit_file_form_clone');
    $form.find(".submit_button").text(buttonMsg);
    if(showUpload) {
      $form.find(".show_upload_link").hide().end()
        .find(".upload").show().end()
        .find(".file_name").hide().end()
        .find(".file_display_option").show();
    } else {
      $form.find(".show_upload_link").hide().end()
        .find(".upload").hide().end()
        .find(".file_name").show().end()
        .find(".file_display_option").hide();
    }
    var data = $file.getTemplateData({textValues: ['name']});
    data.display_name = data.name;
    data.folder_id = files.folderObjects[currentFolder].id;
    $form.find(".file_upload").change();
    $form.fillFormData(data, {object_name: 'attachment'});
    if($file.attr('id') == 'file_new') {
      $form.attr('method', 'POST').attr('action', $(".new_attachment_url").attr('href'));
      $form.attr('action', $(".json_upload_url").attr('href'));
    } else {
      $form.attr('method', 'PUT').attr('action', $file.find('.attachment_url').attr('href'));
    }
    $file.append($form.show());
    if(showUpload) {
      $form.find("input[type='file']").eq(0).focus().select();
    } else {
      $form.find("input[type='text']").eq(0).focus().select();
    }
  },
  hideEditFile: function() {
    var $form = $("#edit_file_form");
    var $obj = $form.parents(".file:first");
    $obj.find(".name").show().end()
      .find(".uploading_message").hide().end()
      .find(".links").css('display', '').end()
      .find(".file_display_option").show().end()
      .find(".file_name").hide();
    $("#content").append($form.hide());
    if($form.hasClass('edit_file_form_clone')) {
      $form.remove();
    }
    if($obj.attr('id') == 'file_new') {
      $obj.remove();
    }
  },
  draggable_options: {
    handle: '.name',
    helper: function() {
      var $result = $(this).clone().attr('id', 'file_drag');
      $result.addClass('file_drag');
      $result.find(".links").hide();
      return $result;  
    },
    start: function(event, ui) {
      files.selectFolderItem($(this));  
      $(this).addClass('file_drag');
      $("#file_drag").addClass('selected');
    },
    stop: function(event, ui) {
      $(this).removeClass('file_drag');
    },
    distance: 5
  },
  droppable_options: {
    accept: ".file_drag",
    hoverClass: "drop_target",
    tolerance: "pointer",
    drop: function(event, ui) {
      var folderName = files.getFolderName($(this));
      if($(this).parents("#folder_content").length > 0) {
        folderName = currentFolder;
        folderName += "/" + $(this).find(".name").text();
      }
      var $obj = $(ui.draggable);
      if($obj.hasClass('file')) {
        var $file = $(ui.draggable);
        files.moveFile($file, currentFolder, folderName);
      } else if($obj.hasClass('folder')) {
        var $folder = $(ui.draggable);
        files.moveFolder($folder, currentFolder, folderName);
      }
    }
  },
  lastClick: null,
  selectedItemClick: function() {
    var $obj = $("#folder_content .content_item.selected");
    if(!files.lastClick || $obj.length > 1 || files.lastClick[0] != $obj[0]) {
      return;
    }
    if($obj.hasClass('file')) {
      files.editFile($obj);
    } else {
      files.editFolder($obj);      
    }
  },
  checkFolderContent: function(loading) {
    var $content = $("#folder_content");
    var fileCount = $content.find(".content_item.file").length;
    var folderCount = $content.find(".content_item.folder").length;
    $content.find(".no_content_message").showIf($content.find(".content_item").length === 0);
    $content.find(".locked_content_message").hide();
    $(".current_file_count").text(loading ? "..." : fileCount);
    $(".current_folder_count").text( (loading || !folderCount) ? "" : ("and " + folderCount + " sub-folder" + ( (folderCount > 1)? "s": "") + " ") );
    $(".current_folder").text(files.folderObjects[currentFolder].name);
    if(loading) {
      $content.find(".no_content_message .message").text("Loading...");
    } else {
      $content.find(".no_content_message .message").text("Nothing in this folder...");
    }
  },
  deleteItem: function($obj) {
    files.selectFolderItem($obj);
    var itemFolder = currentFolder;
    if($obj.hasClass('file')) {
      files.hideEditFile();
      var name = $obj.find(".name").text();
      $obj.confirmDelete({
        url: $obj.find(".attachment_url").attr('href'),
        message: "Are you sure you want to delete the file: " + '\n\n' + name,
        success: function() {
          var id = $(this).attr('id');
          var cache = files.folderLookupCache[itemFolder];
          var newCache = [];
          for(var idx in cache) {
            var file = cache[idx];
            if("folder_file_" + file.attachment.id != id) {
              newCache.push(file);
            }
          }
          files.folderLookupCache[itemFolder] = newCache;
          $(this).fadeOut(function() {
            $(this).remove();
            files.checkFolderContent();
            files.deselectFolderItem();
          });
        }
      });
    } else {
      files.hideEditFolder();
      var name = $obj.find(".name").text();
      $obj.confirmDelete({
        url: $obj.find(".folder_url").attr('href'),
        message: "Are you sure you want to delete the folder:" + '\n\n' + name,
        success: function() {
          var name = $(this).find(".name").text();
          var folder_id = files.folderObjects[itemFolder + '/' + name].id;
          files.deleteFolderObject(itemFolder + '/' + name)
          $("#folder_" + folder_id).remove();
          $(this).fadeOut(function() {
            $(this).remove();
            files.deselectFolderItem();
            files.checkFolderContent();
          });
        }
      });
    }
  },
  updateQuota: function() {
    if($(".quota_details").length === 0) { return; }
    var url = $(".quota_url").attr('href');
    $.getJSON(url, function(data) {
      $(".quota_details").fillTemplateData({data: data});
      if(data.quota_full) {
        $(".quota_details").addClass('quota_full');
      }
    });
  }
};
$(document).ready(function(){
  files.processFolderObjects();
});
var fileUpload = {
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
    $file.find(".status").text("Queued");
  },
  fileQueueError: function(file, error, message) {
    var $file = fileUpload.initFile(file);
    $file.find(".status").text("Failed").end()
      .find(".cancel_upload_link").hide();
    $file.append(message);
  },
  initFile: function(file) {
    var $file = $("#file_upload_" + file.id);
    if($file.length === 0) {
      $file = $("#file_upload_blank").clone(true).attr('id', "file_upload_" + file.id);
      $("#file_uploads").append($file);
      $file.find(".progress_bar").progressbar();
      $file.click(function(event) {
        if($(this).find(".cancel_upload_link:visible").length === 0) {
          event.preventDefault();
          $(this).slideUp(function() {
            $(this).remove();
          });
        }
      });
      $file.find(".cancel_upload_link").click(function(event) {
        event.preventDefault();
        var id = ($(this).parents(".file_upload").attr('id') || "").substring(12);      
        swfUpload.cancelUpload(id, true)
      });
    }
    $file.find(".file_name").text(file.name);
    $file.slideDown('fast');
    return $file;
  },
  uploadStart: function(file) {
    var $file = fileUpload.initFile(file);
    this.addFileParam(file.id, 'file_extension', file.type);
    $file.find(".status").text("Uploading");
  },
  uploadProgress: function(file, bytesLoaded) {
    try {
      var percent = Math.ceil((bytesLoaded / file.size) * 100);
      $("#file_upload_" + file.id).find(".progress_bar").progressbar('value', percent);
      if (percent === 100) {
        $("#file_upload_" + file.id).find(".cancel_upload_link").hide().end()
          .find(".status").text("Uploading");
      } else {
        $("#file_upload_" + file.id).find(".status").text("Uploading");
      }
    } catch (ex) {
      this.debug(ex);
    }
  },
  uploadSuccess: function(file, serverData) {
    try {
      $("#file_upload_" + file.id).find(".cancel_upload_link").hide().end()
        .find(".status").text("Done uploading");
      var $file = $("#file_upload_" + file.id);
      setTimeout(function() {
        $file.slideUp(function() {
          $file.remove();
        });
      }, 5000);
      var data = eval("(" + serverData + ")");
      var attachment = data.attachment;
      files.addAttachment(attachment);
    } catch (ex) {
      this.debug(ex);
    }
  },
  uploadComplete: function(file) {
    try {
      /*  I want the next upload to continue automatically so I'll call startUpload here */
      if (this.getStats().files_queued > 0) {
        this.startUpload();
      } else {
        $("#file_uploads_spinner").slideUp();
        var $msg = $("#file_upload_blank").clone(true).removeAttr('id').empty();
        $msg.text("Finished uploading all files");
        $("#file_uploads").prepend($msg.slideDown('fast'));
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
        files.updateQuota();
        // All done!
      }
    } catch (ex) {
      this.debug(ex);
    }
  },
  uploadError: function(file, errorCode, message) {
    var imageName =  "error.gif";
    var progress;
    try {
      $("#file_upload_" + file.id).find(".cancel_upload_link").hide().end()
        .find(".status").text("Failed uploading");
      switch (errorCode) {
      case SWFUpload.UPLOAD_ERROR.FILE_CANCELLED:
        try {
          $("#file_upload_" + file.id).find(".status").text("Cancelled");
        }
        catch (ex1) {
          this.debug(ex1);
        }
        break;
      case SWFUpload.UPLOAD_ERROR.UPLOAD_STOPPED:
        try {
          $("#file_upload_" + file.id).find(".status").text("Stopped Uploading");
        }
        catch (ex2) {
          this.debug(ex2);
        }
      case SWFUpload.UPLOAD_ERROR.UPLOAD_LIMIT_EXCEEDED:
        imageName = "uploadlimit.gif";
        break;
      default:
        break;
      }

    } catch (ex3) {
      this.debug(ex3);
    }

  },
  addImage: function(src) {
    var newImg = document.createElement("img");
    newImg.style.margin = "5px";

    document.getElementById("thumbnails").appendChild(newImg);
    if (newImg.filters) {
      try {
        newImg.filters.item("DXImageTransform.Microsoft.Alpha").opacity = 0;
      } catch (e) {
        // If it is not set initially, the browser will throw an error.  This will set it if it is not set yet.
        newImg.style.filter = 'progid:DXImageTransform.Microsoft.Alpha(opacity=' + 0 + ')';
      }
    } else {
      newImg.style.opacity = 0;
    }

    newImg.onload = function () {
      $(newImg).fadeIn();
    };
    newImg.src = src;
  }
};
$(document).ready(function() {
  
  $("#view_options").accordion({
    header: ".header",
    fillSpace: true,
    active: false
  });
  $("#view_options").accordion('activate', 0);
  $(document).fragmentChange(function(event, hash) {
    var folder = hash.substring(1);
    if(files.folderObjects[folder]) {
      files.openFolder(folder);
    }
  });
  $("#folder_content").sortable({
    handle: '.move',
    axis: 'y',
    containment: 'parent',
    update: function(event, ui) {
      var $attachment = $(ui.item);
      while($attachment.next().hasClass('folder')) {
        $attachment.next().after($attachment);
      }
      var order = [];
      $("#folder_content .file").each(function() {
        var id = $(this).getTemplateData({textValues: ['id']}).id;
        order.push(id);
      });
      $("#folder_content").loadingImage();
      var data = {
        order: order.join(','),
        folder_id: files.folderObjects[currentFolder].id
      }
      var url = $(".reorder_attachments_url").attr('href');
      var folderName = currentFolder;
      $.ajaxJSON(url, 'POST', data, function(data) {
        $("#folder_content").loadingImage('remove');
        files.folderLookupCache[folderName] = data;
        if(currentFolder != folderName) { return; }
        $("#folder_content").sortable('refresh');
      }, function() {
        $("#folder_content").loadingImage('remove');
      });
    }
  });
  $("#folders").delegate('.folder_name', 'mousedown', function(event) {
    event.preventDefault();  
  }).delegate('.folder_name', 'dblclick', function(event) {
    event.preventDefault();
    event.stopPropagation();
    files.toggleSubfolder($(this).parent());
  }).delegate('.folder_name', 'click', function(event) {
    event.preventDefault();
    event.stopPropagation();
    files.selectFolder($(this).parent());
  });
  $("#folder_content").delegate('.attachment_url', 'mouseup', function(event) {
    event.preventDefault();
    if($.browser.msie) {
      event.stopPropagation();
    }
  });
  $("#folder_content").delegate('.content_item', 'click', function(event) {
    if($(event.target).hasClass('name')) {
      event.preventDefault();
      var $obj = $(this);
      if($obj.hasClass('selected')) {
        files.lastClick = $obj;
        setTimeout(files.selectedItemClick, 300);
      }
    } else if($(this).hasClass('selected') || $(this).find("form").length > 0) {
      return;
    } else if ($(event.target).parents(".links").length > 0) {
      return;
    }
    event.preventDefault();
    files.selectFolderItem($(this));
    if($(event.target).hasClass('name')) {
      if(!$obj.hasClass('draggable')) {
        $(event.target).dblclick();
      }
    }
  }).delegate('.content_item.file', 'dblclick', function(event) {
    event.preventDefault();
    files.lastClick = null;
    if($(this).hasClass('locked')) { return; }
    location.href = $(".download_item_link").attr('href');
  }).delegate('.content_item.folder', 'dblclick', function(event) {
    if($(this).find("form").length > 0) {
      return;
    }
    var $working_folder = $("#folders .selected:first").parent();
    if($working_folder.length === 0) {
      $working_folder = $("#folders");
    }
    files.toggleSubfolder($working_folder, true);
    var name = $.trim($(this).text());
    files.selectFolder($working_folder.find(".folder_list > .folder[title='" + name + "']"));
  }).delegate('.content_item.folder', 'mousedown', function(event) {
    if($(this).find("form").length > 0) {
      return;
    }
    event.preventDefault();
    event.stopPropagation();
  });
  $(".preview_item_link").click(function(event) {
    event.preventDefault();
    var $item = $(this).parents(".content_item");
    var data = $item.getTemplateData({textValues: ['name', 'document_id', 'access_key']});
    $("#preview_item_dialog").empty();
    var height = $(window).height() - 50;
    var width = Math.max(600, $(window).width() - 100);
    $("#preview_item_dialog").dialog('close').dialog({
      autoOpen: false,
      title: "Preview File: " + data.name,
      width: width,
      height: height,
      modal: true,
      close: function() {
      }
    }).dialog('open');
    var sd = scribd.Document.getDoc( data.document_id, data.access_key );

      $.each({
          'jsapi_version': 1,
          'disable_related_docs': true,
          'auto_size' : false,
          'height' : '100%'
        }, function(key, value){
          sd.addParam(key, value);
      });

      sd.write( 'preview_item_dialog' );
    files.currentScribdDoc = sd;
  });
  $(".lock_item_link").click(function(event) {
    var item_name = 'File';
    var item_type = 'attachment';
    var $form = $("#lock_attachment_form");
    var $item = $("#folder_content .content_item.selected");
    var url = $item.find(".attachment_url").attr('href');
    if($(this).parents("#folder_details").length > 0) {
      item_name = 'Folder';
      item_type = 'folder';
      $form = $("#lock_folder_form");
      url = $item.find(".folder_url").attr('href');
    }
    $form.attr('action', url);
    $("#lock_item_dialog form").hide();
    $form.show();
    var data = $item.getTemplateData({textValues: ['name', 'lock_at', 'unlock_at', 'last_lock_at', 'last_unlock_at']});
    data.lock_at = data.last_lock_at;
    data.unlock_at = data.last_unlock_at;
    data.locked = (!data.lock_at && !data.unlock_at) ? '1' : '0';
    $("#lock_item_dialog").fillTemplateData({data: {name: data.name}});
    $form.fillFormData(data, {
      object_name: item_type
    });
    $("#lock_item_dialog").dialog('close').dialog({
      autoOpen: true,
      modal: true,
      width: 350,
      overlay: {
        backgroundColor: "#000",
        opacity: 0.7
      },
      title: "Lock " + item_name
    }).dialog('open');
  });
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
      var attachment = data.attachment;
      var $attachment = $("#folder_file_" + attachment.id);
      $attachment.remove();
      if(!files.folderLookupCache[currentFolder]) {
        files.folderLookupCache[currentFolder] = [];
      }
      files.folderLookupCache[currentFolder].push(data);
      files.addAttachment(attachment);
      files.deselectFolderItem();
      files.selectFolderItem($("#folder_file_" + attachment.id));
      $("#lock_item_dialog").dialog('close');
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
      var folder = data.folder;
      var $folder = $("#folder_content_" + folder.id);
      $folder.remove();
      files.addFolder(folder);
      files.refreshFolder($("#folder_" + folder.id));
      files.deselectFolderItem();
      files.selectFolderItem($("#folder_content_" + folder.id));
      $("#lock_item_dialog").dialog('close');
    }
  });
  $(".unlock_item_link").click(function(event) {
    event.preventDefault();
    var item_name = 'File';
    var item_type = 'attachment';
    var $form = $("#lock_attachment_form");
    var $item = $("#folder_content .content_item.selected");
    var url = $item.find(".attachment_url").attr('href');
    if($(this).parents("#folder_details").length > 0) {
      item_name = 'Folder';
      item_type = 'folder';
      $form = $("#lock_folder_form");
      url = $item.find(".folder_url").attr('href');
    }
    $form.attr('action', url);
    $("#lock_item_dialog form").hide();
    $form.show();
    var data = {};
    data['[' + item_type + '][locked]'] = '';
    data['[' + item_type + '][lock_at]'] = '';
    data['[' + item_type + '][unlock_at]'] = '';
    $item.loadingImage();
    $.ajaxJSON(url, 'PUT', data, function(data) {
      $item.loadingImage('remove');
      $item.remove();
      if(item_type == 'attachment') {
        var attachment = data.attachment;
        if(!files.folderLookupCache[currentFolder]) {
          files.folderLookupCache[currentFolder] = [];
        }
        files.folderLookupCache[currentFolder].push(data);
        files.addAttachment(attachment);
        files.deselectFolderItem();
        files.selectFolderItem($("#folder_file_" + attachment.id));
      } else {
        var folder = data.folder;
        files.addFolder(folder);
        files.refreshFolder($("#folder_" + folder.id));
        files.deselectFolderItem();
        files.selectFolderItem($("#folder_content_" + folder.id));
      }
    }, function(data) {
      $item.loadingImage('remove');
    });
  });
  $(".datetime_field").datetime_field();
  $("#folder_content .content_item.file.draggable").draggable(files.draggable_options);
  $("#folder_content .content_item.folder.draggable").draggable(files.draggable_options);
  $("#edit_folder_form").formSubmit({
    processData: function(data) {
      var data = $(this).getFormData({object_name: "folder"});
      return data;
    },
    beforeSubmit: function(data) {
      var $folder = $(this).parents(".content_item.folder");
      $folder.loadingImage();
      var name = data.name;
      var oldName = $folder.find(".name").text();
      if(!oldName) { oldName = "__none__"; }
      var oldDirName = currentFolder + "/" + oldName;
      var newDirName = currentFolder + "/" + name;
      $folder.attr('id', 'folder_saving');
      $folder.data('folder_name', name);
      $folder.data('old_name', oldDirName);
      $folder.data('new_name', newDirName);
      $folder.attr('title', name).children('.name').text(name).show();
      files.hideEditFolder();
      return $folder;
    },
    success: function(data, $folder) {
      var folder = data.folder;
      $folder.loadingImage('remove');
      var oldDirName = $folder.data('old_name');
      var newDirName = folder.full_name;
      $folder.remove();
      files.addFolder(folder);
      files.renameFolder(oldDirName, newDirName);
      files.refreshFolder($("#folders .folder_name.selected").parent());
      if(oldDirName.match(/__none__/)) {
        $("#folder_content_" + folder.id).dblclick();
      }
    }
  });
  $("#edit_folder_form").delegate(".cancel_button", 'click', function(event) {
    event.preventDefault();
    files.hideEditFolder();
    files.checkFolderContent();
  });
  $("#file_browser").find(".folder .folder_name,.tag,#folder_content .content_item.folder").droppable(files.droppable_options);
  $("#edit_file_form .file_display_option").click(function(event) {
    event.preventDefault();
    var $form = $(this).parents("form");
    $(this).parents("form").find(".file_display_option").hide().end()
      .find(".file_name").val($form.find(".file_display_name").text() || "").show().focus().select();
  });
  $("#edit_file_form .file_upload").change(function() {
    var $form = $(this).parents("form");
    var $name = $form.find(".file_name");
    $form.find(".change_file_name_link").showIf($name.val() != "");
    if($name.filter(":visible").length === 0 || $.trim($name.val()) == "") {
      var name = $(this).val() || "";
      var names = name.split(/[\\\/]/);
      name = names[names.length - 1];
      $form.find(".file_display_name").text(name);
      $name.val(name);
      $form.find(".change_file_name_link").showIf($name.val() != "");
    }
  });
  $("#edit_file_form").formSubmit({
    fileUpload: function(data) {
      var fileUpload = ($(this).find(".upload").css('display') != 'none' && $(this).find(".file_upload").val());
      $(this).find(".uploading_message").find(".message").text(fileUpload ? "Uploading..." : "Updating...");
      return fileUpload;
    },
    beforeSubmit: function(data) {
      if($(this).parents(".file").attr('id') == 'file_new' && !data['attachment[uploaded_data]']) {
        $(this).errorBox("Please select a file to upload");
        return false;
      }
      $(this).find(".uploading_message").slideDown();
    },
    success: function(data) {
      var attachment = data.attachment;
      var $formAttachment = $(this).parents(".file");
      files.hideEditFile();
      $formAttachment.remove();
      if(!files.folderLookupCache[currentFolder]) {
        files.folderLookupCache[currentFolder] = [];
      }
      files.folderLookupCache[currentFolder].push(data);
      files.addAttachment(attachment);
      files.updateQuota();
    },
    error: function(data) {
      $(this).find(".uploading_message").slideUp();
    }
  });
  setInterval(files.updateQuota, 60000);
  $("#edit_file_form").delegate(".cancel_button", 'click', function(event) {
    event.preventDefault();
    files.hideEditFile();
    files.checkFolderContent();
  }).delegate('.show_upload_link', 'click', function(event) {
    event.preventDefault();
    $("#edit_file_form .upload").show();
    $(this).hide();
  });
  $("#edit_folder_form, #edit_file_form").delegate(':text', 'keydown', function(event) {
    if(event.keyCode == 27) {
      if($(this).parents("form:first").attr('id') == 'edit_folder_form') {
        files.hideEditFolder();
        files.checkFolderContent();
      } else {
        files.hideEditFile();
        files.checkFolderContent();
      }
    }
  })
  $("#tags").delegate('.tag', 'click', function(event) {
    event.preventDefault();
    files.selectTag($(this));
  })
  $(window).resize(function() {
    var windowHeight = $(window).height();
    var tableTop = $("#view_options").offset().top;
    var tableHeight = Math.max(windowHeight - tableTop, 200) - 10;
    $("#view_options,#folder_content").height(tableHeight).css('maxHeight', '');
    if($.browser.msie && navigator.appVersion.match('MSIE 6.0')) { return; }
    $("#view_options").accordion('resize');
  }).triggerHandler('resize');
  setTimeout(function() { $(window).triggerHandler('resize'); }, 1000);
  var uploadUrl = $("#file_uploads_url").attr('href');
  swfUpload = new SWFUpload({
    upload_url: uploadUrl,
    flash_url: "/flash/swf_upload/Flash/swfupload.swf",
    file_size_limit: "50 MB",
    file_queue_error_handler : fileUpload.fileQueueError,
    file_queued_handler: fileUpload.fileQueued,
    file_dialog_complete_handler : fileUpload.fileDialogComplete,
    upload_progress_handler : fileUpload.uploadProgress,
    upload_error_handler : fileUpload.uploadError,
    upload_start_handler: fileUpload.uploadStart,
    upload_success_handler : fileUpload.uploadSuccess,
    upload_complete_handler : fileUpload.uploadComplete,
    button_placeholder_id : "file_upload",
    button_width: 180,
    button_height: 25,
    button_text : '<span class="link">Add Multiple Files</span>',
    button_text_style : '.link { font-family: Arial, sans-serif; font-size: 15px; color: #333333; text-align: left;}',
    button_text_top_padding: 3,
    button_text_left_padding: 18,
    button_window_mode: SWFUpload.WINDOW_MODE.TRANSPARENT,
    button_cursor: SWFUpload.CURSOR.HAND,
    file_post_name: 'attachment_uploaded_data',
    use_query_string: true,
    post_params: {
      authenticity_token: $("#ajax_authenticity_token").text(),
      '_normandy_session': $("#file_uploads_session_id").text(),
      format: 'json'
    },
    http_success: [200,201]
  });
  setInterval(function() {
    try {
      if(currentFolder && files.folderObjects[currentFolder] && files.folderObjects[currentFolder].id) {
        swfUpload.addPostParam('attachment[folder_id]', files.folderObjects[currentFolder].id);
      }
    }catch(e) {}
  }, 500);
});
$(document).delegate('.add_folder_link', 'click', function(event) {
  event.preventDefault();
  if(currentFolder == "unfiled") { return; }
  var $folder = $("#folder_content_folder").clone(true);
  $folder.find(".edit_item_link").show();
  $folder.attr('id', 'folder_new');
  $("#folder_content").prepend($folder.show());
  files.editFolder($folder);
  files.checkFolderContent();
}).delegate('.add_file_link', 'click', function(event) {
  event.preventDefault();
  if($("#file_new:visible").length > 0) { return; }
  var $file = $("#folder_content_file").clone(true);
  $file.find(".edit_item_link").show();
  $file.attr('id', 'file_new');
  var $lastFolder = $("#folder_content .folder:last");
  if($lastFolder.length === 0) { 
    $("#folder_content").prepend($file.show());
  } else {
    $lastFolder.after($file.show());
  }
  files.editFile($file, true);
  files.checkFolderContent();
}).delegate('.delete_item_link', 'click', function(event) {
  event.preventDefault();
  var $obj = $(this).parents(".content_item");
  if($obj.length === 0) {
    $obj = $("#folder_content .content_item.selected");
  }
  files.deleteItem($obj);
}).delegate('.edit_item_link', 'click', function(event) {
  event.preventDefault();
  var $obj = $(this).parents(".content_item");
  if($obj.length === 0) {
    $obj = $("#folder_content .content_item.selected");
  }
  files.selectFolderItem($obj);
  if($obj.hasClass('file')) {
    var showUpload = $(this).hasClass('replace_file_link');
    files.editFile($obj, showUpload);
  } else {
    files.editFolder($obj);
  }
});
$(document).click(function(event) {
  var $target = $(event.target);
  if($target.closest("#sidebar").length === 0 && $target.closest("a").length === 0 && $target.closest(".content_item").length === 0) {
    files.deselectFolderItem();
  }
});
