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

var INST;
I18n.scoped('select_content_dialog', function(I18n) {
$(document).ready(function() {
  var external_services = null;
  var $dialog = $("#select_context_content_dialog");
  attachAddAssignment($("#assignments_select .module_item_select"));
  INST = INST || {};
  INST.selectContentDialog = function(options) {
    var for_modules = options.for_modules;
    var select_button_text = options.select_button_text || I18n.t('buttons.add_item', "Add Item");
    var holder_name = options.holder_name || "module";
    var dialog_title = options.dialog_title || I18n.t('titles.add_item_to_module', "Add Item to Module");
    var allow_external_urls = for_modules;
    $dialog.data('submitted_function', options.submit);
    $dialog.find(".context_module_content").showIf(for_modules);
    $dialog.find(".holder_name").text(holder_name);
    $dialog.find(".add_item_button").text(select_button_text);
    if(allow_external_urls && !external_services) {
      var $services = $("#content_tag_services").empty();
      $.getUserServices('BookmarkService', function(data) {
        for(var idx in data) {
          service = data[idx].user_service;
          $service = $("<a href='#' class='bookmark_service no-hover'/>");
          $service.addClass(service.service);
          $service.data('service', service);
          $service.attr('title', I18n.t('titles.find_links_using_service', 'Find links using %{service}', {service: service.service}));
          var $img = $("<img/>");
          $img.attr('src', '/images/' + service.service + '_small_icon.png');
          $service.append($img);
          $service.click(function(event) {
            event.preventDefault();
            $.findLinkForService($(this).data('service').service, function(data) {
              $("#content_tag_create_url").val(data.url);
              $("#content_tag_create_title").val(data.title);
            });
          });
          $services.append($service);
          $services.append("&nbsp;&nbsp;");
        }
      });
    }
    $("#select_context_content_dialog #external_urls_select :text").val("");
    $("#select_context_content_dialog #context_module_sub_headers_select :text").val("");
    $("#select_context_content_dialog").dialog('close').dialog({
      autoOpen: true,
      title: dialog_title,
      width: 400
    }).dialog('open');
    $("#select_context_content_dialog").dialog('option', 'title', dialog_title);
  }
  $("#select_context_content_dialog .cancel_button").click(function() {
    $("#select_context_content_dialog").dialog('close');
  });
  $("#select_context_content_dialog .item_title").keycodes('return', function() {
    $(this).parents(".module_item_option").find(".add_item_button").click();
  });
  $("#select_context_content_dialog .add_item_button").click(function() {
    var module_id = $("#select_context_content_dialog").getTemplateData({textValues: ['context_module_id']}).context_module_id;
    var item_type = $("#add_module_item_select").val();
    var submit = function(item_data) {
      $("#select_context_content_dialog").dialog('close');
      var submitted = $dialog.data('submitted_function');
      if(submitted && $.isFunction(submitted)) {
        submitted(item_data);
      }
    };
    if(item_type == 'external_url') {
      var item_data = {
        'item[type]': $("#add_module_item_select").val(),
        'item[id]': $("#select_context_content_dialog .module_item_option:visible:first .module_item_select").val(),
        'item[indent]': $("#content_tag_indent").val()
      }
      item_data['item[url]'] = $("#content_tag_create_url").val();
      item_data['item[title]'] = $("#content_tag_create_title").val();
      submit(item_data);   
    } else if(item_type == 'context_external_tool') {
      var item_data = {
        'item[type]': $("#add_module_item_select").val(),
        'item[id]': $("#external_urls_select .tools .tool.selected").data('id'),
        'item[new_tab]': $("#external_tool_create_new_tab").attr('checked') ? '1' : '0',
        'item[indent]': $("#content_tag_indent").val()
      }
      item_data['item[url]'] = $("#external_tool_create_url").val();
      item_data['item[title]'] = $("#external_tool_create_title").val();
      submit(item_data);   
    } else if(item_type == 'context_module_sub_header') {
      var item_data = {
        'item[type]': $("#add_module_item_select").val(),
        'item[id]': $("#select_context_content_dialog .module_item_option:visible:first .module_item_select").val(),
        'item[indent]': $("#content_tag_indent").val()
      }
      item_data['item[title]'] = $("#sub_header_title").val();
      submit(item_data);   
    } else {
      var $options = $("#select_context_content_dialog .module_item_option:visible:first .module_item_select option:selected");
      $options.each(function() {
        var $option = $(this);
        var item_data = {
          'item[type]': item_type,
          'item[id]': $option.val(),
          'item[title]': $option.text(),
          'item[indent]': $("#content_tag_indent").val()
        }
        if(item_data['item[id]'] == 'new') {
          $("#select_context_content_dialog").loadingImage();
          var url = $("#select_context_content_dialog .module_item_option:visible:first .new .add_item_url").attr('href');
          var data = $("#select_context_content_dialog .module_item_option:visible:first").getFormData();
          var callback = function(data) {
            $("#select_context_content_dialog").loadingImage('remove');
            var obj = data[item_data['item[type]']] // e.g. data['wiki_page'] for wiki pages
            item_data['item[id]'] = obj.id;
            item_data['item[title]'] = $("#select_context_content_dialog .module_item_option:visible:first .item_title").val();
            item_data['item[title]'] = item_data['item[title]'] || obj.display_name
            var $option = $(document.createElement('option'));
            $option.val(obj.id).text(item_data['item[title]']);
            $("#" + item_data['item[type]'] + "s_select").find(".module_item_select option:last").before($option);
            submit(item_data);
          };
          if(item_data['item[type]'] == 'attachment') {
            $.ajaxJSONFiles(url, 'POST', data, $("#module_attachment_uploaded_data"), function(data) {
              callback(data);
            }, function(data) {
              $("#select_context_content_dialog").loadingImage('remove');
              $("#select_context_content_dialog").errorBox(I18n.t('errors.failed_to_create_item', 'Failed to Create new Item'));
            });
          } else {
            $.ajaxJSON(url, 'POST', data, function(data) {
              callback(data);
            }, function(data) {
              $("#select_context_content_dialog").loadingImage('remove');
              $("#select_context_content_dialog").errorBox(I18n.t('errors.failed_to_create_item', 'Failed to Create new Item'));
            });
          }
        } else {
          submit(item_data);
        }
      });
    }
  });
  $("#context_external_tools_select .tools").delegate('.tool', 'click', function() {
    var $tool = $(this);
    if($(this).hasClass('selected')) { 
      $(this).removeClass('selected'); 
      return; 
    }
    $tool.parents(".tools").find(".tool.selected").removeClass('selected');
    $tool.addClass('selected');
    $("#external_tool_create_url").val($tool.data('url') || '');
    $("#context_external_tools_select .domain_message").showIf($tool.data('domain'))
      .find(".domain").text($tool.data('domain'));
    $("#external_tool_create_title").val($tool.data('name'));
  });
  var $tool_template = $("#context_external_tools_select .tools .tool:first").detach();
  $("#add_module_item_select").change(function() {
    $("#select_context_content_dialog .module_item_option").hide();
    $("#" + $(this).val() + "s_select").show().find(".module_item_select").change();
    if($(this).val() == 'context_external_tool') {
      var $select = $("#context_external_tools_select");
      if(!$select.hasClass('loaded')) {
        $select.find(".message").text("Loading...");
        var url = $("#select_context_content_dialog .external_tools_url").attr('href');
        $.ajaxJSON(url, 'GET', {}, function(data) {
          $select.find(".message").remove();
          $select.addClass('loaded');
          $select.find(".tools").empty();
          for(var idx in data) {
            var tool = data[idx];
            var $tool = $tool_template.clone(true);
            $tool.fillTemplateData({
              data: tool,
              dataValues: ['id', 'url', 'domain', 'name']
            });
            $select.find(".tools").append($tool.show());
          }
        }, function(data) {
          $select.find(".message").text(I18n.t('errors.loading_failed', "Loading Failed"));
        });
      }
    }
  }).change();
  $("#select_context_content_dialog .module_item_select").change(function() {
    if($(this).val() == "new") {
      $(this).parents(".module_item_option").find(".new").show().focus().select();
    } else {
      $(this).parents(".module_item_option").find(".new").hide();
    }
  }).change();
});
});
