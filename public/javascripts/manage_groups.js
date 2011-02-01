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

var contextGroups = {
  autoLoadGroupThreshold: 15,
  studentGroupsCategoryName: $.encodeToHex('Student Groups'),
  
  loadMembersForGroup: function($group) {
    var url = $("#manage_group_urls .list_users_url").attr('href');
    var id = $group.getTemplateData({textValues: ['group_id']}).group_id;
    url = $.replaceTags(url, "id", id)
    
    $group.find(".load_members_link").hide();
    $group.find(".loading_members").show();
    
    $.ajaxJSON(url, "GET", null, function(data) {
      // remove existing students from group (this should have returned everyone)
      $group.find(".student").remove();
      
      // create new entries for everyone we got back, and insert them into the list.
      // TODO: we should presort the list and give an "append" option to insertIntoGroup.
      // Right now it takes O(n^2) to insert students, which can be painful in a large list.
      var user_template = $(".user_template");
      for (var i = 0; i < data.length; i++) {
        var user_info = data[i];
        var user_el = user_template.clone();
        user_el.removeClass('user_template');
        user_el.addClass('user_id_' + user_info['user_id']);
        user_el.fillTemplateData({ data: user_info });
        
        contextGroups.insertIntoGroup(user_el, $group);
        
        $group.find(".user_count_hidden").text("0");
        $(window).triggerHandler('resize');
        contextGroups.updateCategoryCounts($group.parents(".group_category"));
      }
      $group.find(".loading_members").hide();
    });
  },
  
  // 0 means to reload the current page, whatever it is
  // < 0 means to only load that page if no other page is loaded
  loadUnassignedMembersPage: function($group, page) {
    if (page < 0 && $group.data("page_loaded")) { return; }
    page = Math.abs(page);
    
    if (page == 0) {
      page = $group.data("page_loaded") || 1;
    }
    
    // This is lots of duplicated code from above, with tweaks. TODO: Refactor
    var category = $group.closest(".group_category").find(".category_name").first().text();
    var url = $("#manage_group_urls .list_unassigned_users_url").attr('href');
    url += "?category=" + encodeURIComponent(category) + "&page=" + page;
    
    $group.find(".load_members_link").hide();
    $group.find(".loading_members").text("Loading...");
    $group.find(".loading_members").show();
    
    $.ajaxJSON(url, "GET", null, function(data) {
      $group.data("page_loaded", page);
      $group.find(".user_count").text(data['total_entries']);
      $group.find(".user_count_label").text(data['total_entries'] == 1 ? 'student' : 'students');
      $group.find(".user_count_hidden").text(data['total_entries'] - data['users'].length);
      $group.find(".group_user_count").show();
      $group.find(".student").remove();
      
      var user_template = $(".user_template");
      var users = data['users'];
      for (var i = 0; i < users.length; i++) {
        var user_info = users[i];
        var user_el = user_template.clone();
        user_el.removeClass('user_template');
        user_el.addClass('user_id_' + user_info['user_id']);
        user_el.fillTemplateData({ data: user_info });
        
        contextGroups.insertIntoGroup(user_el, $group);
      }
      
      $group.find(".loading_members").html(data['pagination_html']);
      $group.find(".unassigned_members_pagination a").click(function(event) {
        event.preventDefault();
        var page_regex = /page=(\d+)/
        match = page_regex.exec($(this).attr('href'))
        if (match.length >= 1) {
          var link_page = match[1];
          contextGroups.loadUnassignedMembersPage($(this).closest(".group_blank").first(), link_page)
        }
      });
      
      $(window).triggerHandler('resize');
    })
  },
  
  moveToGroup: function($student, $group) {
    if ($student.parents(".group")[0] == $group[0]) { return; }
    var id = $group.getTemplateData({textValues: ['group_id']}).group_id;
    var user_id = $student.getTemplateData({textValues: ['user_id']}).user_id;
    var $original_group = $student.parents(".group");
    var url = $("#manage_group_urls .add_user_url").attr('href');
    method = "POST";
    if(!id || id.length == 0) {
      url = $("#manage_group_urls .remove_user_url").attr('href');
      method = "DELETE";
      id = $original_group.getTemplateData({textValues: ['group_id']}).group_id;
    }
    url = $.replaceTags(url, "id", id);
    var data = {
      user_id: user_id
    }
    $student.remove();
    
    var $student_instances = $student;
    contextGroups.insertIntoGroup($student, $group);
    if(($group.parents(".group_category").attr('id') == contextGroups.studentGroupsCategoryName) &&
        ($group.get(0) !== $group.parents(".group_category").find(".group_blank").get(0))) {
      var $s = $student.clone();
      $student_instances = $student_instances.add($s);
      contextGroups.insertIntoGroup($s, $original_group);
    }
    $student = $student_instances;
    $student.addClass('event_pending');
    contextGroups.updateCategoryCounts($group.parents(".group_category"));
    $.ajaxJSON(url, method, data, function(data) {
      var category_id = $.encodeToHex($group.parents(".group_category").getTemplateData({textValues: ['category_name']}).category_name);
      $(".student.user_" + user_id).each(function() {
        var $span = $(this).find("." + category_id + "_group_id");
        if(!$span || $span.length == 0) {
          $span = $(document.createElement('span'));
          $span.addClass(category_id + '_group_id');
          $(this).find(".data").append($span);
        }
        $span.text(data.group_membership.group_id || "");
      });
      
      $student.removeClass('event_pending');
      contextGroups.updateCategoryCounts($group.parents(".group_category"));
      
      var unassigned_group = $group.parents(".group_category").find(".group_blank");
      var students_visible = unassigned_group.find(".student_list .student").length;
      var students_hidden = parseInt(unassigned_group.find(".user_count_hidden").text());
      
      if (students_visible <= 5 && students_hidden > 0) {
        contextGroups.loadUnassignedMembersPage(unassigned_group, 0);
      }
    });
  },
  
  insertIntoGroup: function($student, $group) {
    var $before = null;
    var data = $student.getTemplateData({textValues: ['name', 'user_id']})
    var student_name = data.name;
    
    // don't insert users into a group they're already in
    if ($group.find(".student_list .user_id_" + data.user_id).length > 0) { return; }
    
    $group.find(".student.user_" + data.user_id).remove();
    $group.find(".student_list .student").each(function() {
      var compare_name = $(this).getTemplateData({textValues: ['name']}).name;
      if(compare_name > student_name) {
        $before = $(this);
        return false;
      }
    });
    if(!$before) {
      $group.find(".student_list").append($student);
    } else {
      $before.before($student);
    }
    $student.draggable({
      helper: function() {
        var $helper = $(this).clone().css('cursor', 'pointer');//.css({position: 'absolute'}).appendTo($(this).parents(".group_category"));
        $helper.addClass('dragging');
        $helper.width($(this).width());
        $(this).parents(".group_category").append($helper);
        return $helper;
      }
    });
  },
  
  updateCategoryCounts: function($category) {
    $category.find(".group").each(function() {
      var userCount = $(this).find(".student_list .student").length + parseInt($(this).find(".user_count_hidden").text());
      $(this).find(".user_count").text(userCount);
      $(this).find(".user_count_label").text(userCount == 1 ? 'student' : 'students');
    });
    
    var groupCount = $category.find(".group:not(.group_blank)").length;
    var groupCountLabel = groupCount == 1 ? 'Group' : 'Groups';
    $category.find(".group_count").text(groupCount + ' ' + groupCountLabel);
    
    $category.find(".group").each(function() {
      $(this).find(".expand_collapse_links").showIf($(this).find(".student_list li").length > 0);
    });
  },
  
  populateCategory: function(panel) {
    var $category = $(panel);
    
    // Start loading groups that have < X members automatically
    $category.find(".group").each(function() {
      var members = parseInt($(this).find(".user_count_hidden").text());
      if (members < contextGroups.autoLoadGroupThreshold && members > 0) {
        contextGroups.loadMembersForGroup($(this));
      }
    })
    
    // -1 means to load page 1, but only if there aren't any other pages loaded (for switching between tabs)
    contextGroups.loadUnassignedMembersPage($category.find(".group_blank"), -1);
  },
  
  addGroupToSidebar: function(group) {
    if($("#sidebar_group_" + group.id).length > 0) {
      return;
    }
    var $category = $("#sidebar_category_" + $.encodeToHex(group.category));
    if($category.length == 0) {
      $category = $("#sidebar_category_blank").clone(true);
      $category.find("ul").empty();
      $category.fillTemplateData({
        data: group,
        id: 'sidebar_category_' + $.encodeToHex(group.category)
      });
      $(".sidebar_category:last").after($category.show());
    }
    var $group = $("#sidebar_group_blank").clone(true);
    $group.fillTemplateData({
      data: group,
      hrefValues: ['id'],
      id: 'sidebar_group_' + group.id
    });
    $category.find("ul").append($group.show());
    $("#category_header").show();
  },
  
  droppable_options: {
    accept: '.student',
    hoverClass: 'hover',
    tolerance: 'pointer',
    drop: function(event, ui) {
      $(".group_category > .student").remove();
      contextGroups.moveToGroup($(ui.draggable), $(this));
    }
  }
}

var addGroupCategory;

$(document).ready(function() {
  $("li.student").live('mousedown', function(event) { event.preventDefault(); return false; });
  $("#group_tabs").tabs();
  $("#group_tabs").bind('tabsselect', function(event, ui) {
    contextGroups.populateCategory(ui.panel);
  });
  $(".group").filter(function(){ return $(this).parents("#category_template").length == 0;}).droppable(contextGroups.droppable_options);
  $(".add_group_link").click(function(event) {
    event.preventDefault();
    var $category = $(this).parents(".group_category");
    var $group = $("#category_template").find(".group_blank").clone(true);
    $group.removeAttr('id');
    $group.find(".student_list").empty();
    $group.removeClass('group_blank');
    $group.find(".load-more").hide();
    $group.find(".name").text("Group Name");
    $category.find(".clearer").before($group.show());
    $group.find(".edit_group_link").click();
  });
  $("#edit_group_form").formSubmit({
    object_name: "group",
    processData: function(data) {
      data['group[category]'] = $(this).parents(".group_category").getTemplateData({textValues: ['category_name']}).category_name;
      return data;
    },
    beforeSubmit: function(data) {
      var $group = $(this).parents(".group");
      $(this).remove();
      $group.removeClass('editing');
      $group.loadingImage();
      $group.fillTemplateData({
        data: data,
        avoid: '.student_list'
      });
      return $group;
    },
    success: function(data, $group) {
      var group = data.group || data.course_assigned_group;
      $group.loadingImage('remove');
      $group.droppable(contextGroups.droppable_options);
      $group.find(".name.blank_name").hide().end()
        .find(".group_name").show();
      $group.find(".group_user_count").show();
      group.group_id = group.id;
      $group.fillTemplateData({
        id: 'group_' + group.id,
        data: group,
        avoid: '.student_list',
        hrefValues: ['id']
      });
      contextGroups.addGroupToSidebar(group)
      contextGroups.updateCategoryCounts($group.parents(".group_category"));
    }
  });
  $(".edit_group_link").click(function(event) {
    event.preventDefault();
    var $group = $(this).parents(".group");
    var data = $group.getTemplateData({textValues: ['name', 'max_membership']});
    var $form = $("#edit_group_form").clone(true);
    $form.fillFormData(data, {
      object_name: 'group'
    });
    $group.addClass('editing');
    $group.prepend($form.show());
    $form.find(":input:visible:first").focus().select();
    if($group.attr('id')) {
      $form.attr('method', 'PUT').attr('action', $group.find(".edit_group_link").attr('href'));
    } else {
      $form.attr('method', 'POST').attr('action', $("#manage_group_urls .add_group_url").attr('href'));
    }
    if($group.length > 0) {
      $group.parents(".group_category").scrollTo($group);
    }
  });
  $("#edit_group_form .cancel_button").click(function() {
    var $group = $(this).parents(".group");
    $(this).parents(".group").removeClass('editing');
    $(this).parents("form").remove();
    if(!$group.attr('id')) {
      $group.remove();
    }
  });
  $(".delete_category_link").click(function(event) {
    event.preventDefault();
    var index = $("#group_tabs").tabs('option', 'selected')
    if(index == -1) {
      index = $("#category_list li").index($("#category_list li.ui-tabs-selected"));
    }
    $(this).parents(".group_category").confirmDelete({
      url: $(this).attr('href'),
      message: "Are you sure you want to remove this set of groups?",
      success: function() {
        $("#group_tabs").tabs('remove', index);
        $("#group_tabs").showIf($("#category_list li").length > 0);
        var category_name = $(this).getTemplateData({textValues: ['category_name']}).category_name;
        $("#sidebar_category_" + $.encodeToHex(category_name)).slideUp(function() {
          $(this).remove();
        });
        $("#no_groups_message").showIf($("#category_list li").length == 0);
      }
    });
  });
  $(".add_category_link").click(function(event) {
    event.preventDefault();
    addGroupCategory(function(data) {
      $("#group_tabs").show();
      $("#no_groups_message").hide();
      var $category = $("#category_template").clone(true).removeAttr('id');
      var $group_template = $("#category_template").find(".group_blank");
      $category.find(".group").droppable(contextGroups.droppable_options);
      var category = {};
      for(var idx in data) {
        var group = data[idx].group || data[idx].course_assigned_group;
        group.group_id = group.id;
        category.category_name = group.category;
        $group = $group_template.clone(true).removeClass('group_blank');
        $group.attr('id', 'group_' + group.id);
        if (!group.users || group.users.length == 0) {
          $group.find(".load-more").hide();
        }
        $group.droppable(contextGroups.droppable_options);
        group.user_count = group.users.length;
        group.user_count_hidden = group.users.length;
        $group.fillTemplateData({
          id: 'group_' + group.id,
          data: group,
          avoid: '.student_list',
          hrefValues: ['id']
        });
        $category.find(".clearer").before($group);
        contextGroups.addGroupToSidebar(group)
        
        if (group.users) {
          var category_id = $.encodeToHex(group.category);
          for(var jdx in group.users) {
            var user = group.users[jdx].user;
            var $span = $(document.createElement('span')).addClass(category_id + "_group_id");
            $span.text(group.id);
            $(".student.user_" + user.id).find(".data").append($span);
          }
        }
        
        $group.find(".name.blank_name").hide().end()
          .find(".group_name").show();
        $group.find(".group_user_count").show();
      }
      $category.fillTemplateData({
        data: category,
        hrefValues: ['category_name']
      });
      var name = $(this).data('category_name');
      var id = $.encodeToHex(name);
      $category.attr('id', id);
      $category.find(".category_name").text(name);
      
      var newIndex = $("#group_tabs").tabs('length');
      if ($("li.category").last().find("a").attr('href') == '#' + contextGroups.studentGroupsCategoryName) {
        newIndex -= 1;
      }
      $("#group_tabs").append($category);
      $("#group_tabs").tabs('add', '#' + id, name, newIndex);
      $("#group_tabs").tabs('select', newIndex);
      contextGroups.populateCategory($category);
      contextGroups.updateCategoryCounts($category);
      $(window).triggerHandler('resize');
    });
  });
  $(".load_members_link").click(function(event) {
    event.preventDefault();
    contextGroups.loadMembersForGroup($(this).parents(".group"));
  });
  $(".delete_group_link").click(function(event) {
    event.preventDefault();
    $(this).parents(".group").confirmDelete({
      message: "Are you sure you want to delete this group?",
      url: $(this).attr('href'),
      success: function() {
        var $blank_category = $(this).parents(".group_category").find(".group_blank");
        var group_id = $(this).getTemplateData({textValues: ['group_id']}).group_id;
        $("#sidebar_group_" + group_id).slideUp(function() {
          $(this).remove();
        });
        $(this).slideUp(function() {
          var $category = $(this).parents(".group_category");
          if ($category.attr('id') != contextGroups.studentGroupsCategoryName) {
            $(this).find(".student").each(function() {
              contextGroups.insertIntoGroup($(this), $blank_category);
            });
          }
          $(this).remove();
          contextGroups.updateCategoryCounts($category);
        });
      }
    });
  });
  $(".assign_students_link").click(function(event) {
    event.preventDefault();
    var result = confirm("This will randomly assign all unassigned students evenly among the existing student groups");
    if(!result) {
      return;
    }
    var $groups = $(this).parents(".group_category").find(".group:not(.group_blank)");
    $groups.each(function() {
      $(this).data('student_count', $(this).find(".student").length);
    });
    var students = []
    $(this).parents(".group_category").find(".group_blank").find(".student").each(function() {
      students.push($(this));
    });
    students.sort(function(a,b) { return Math.random() - 0.5; });
    $.each(students, function() {
      var min = -1;
      var $lowest = null;
      $groups.each(function() {
        if(min == -1 || $(this).data('student_count') < min) {
          min = $(this).data('student_count');
          $lowest = $(this);
        }
      });
      if($lowest) {
        contextGroups.moveToGroup($(this), $lowest);
        $lowest.data('student_count', $lowest.data('student_count') + 1);
      }
    });
  });
  contextGroups.populateCategory($("#group_tabs .group_category:first"));
  $(window).resize(function() {
    if($(".group_category:visible:first").length == 0) { return; }
    var top = $(".group_category:visible:first").offset().top;
    var height = $(window).height();
    $(".group_category").height(height - top - 40);
    var $cat = $(".group_category:visible:first");
    var catTop = $cat.offset().top;
    var leftTop = $cat.find(".left_side").offset().top;
    $(".group_category").find(".right_side,.left_side").height(height - top - 40 - (leftTop - catTop) + 10);
  }).triggerHandler('resize');
  $(".group_category .group").find(".expand_group_link").click(function(event) {
    event.preventDefault();
    $(this).hide()
      .parents(".group").find(".student_list").slideDown().end()
      .find(".load-more").slideDown().end()
      .find(".collapse_group_link").show();
  }).end().find(".collapse_group_link").click(function(event) {
    event.preventDefault();
    $(this).hide()
      .parents(".group").find(".student_list").slideUp().end()
      .find(".load-more").slideUp().end()
      .find(".expand_group_link").show();
  });
  $(".group_category").find(".expand_groups_link").click(function(event) {
    event.preventDefault();
    $(this).parents(".group_category").find(".expand_group_link").click();
  });
  $(".group_category").find(".collapse_groups_link").click(function(event) {
    event.preventDefault();
    $(this).parents(".group_category").find(".collapse_group_link").click();
  });
  $(".group").hover(function() {
    $(this).addClass('group-hover');
  }, function() {
    $(this).removeClass('group-hover');
  });
  $(".group_category").each(function() {
    contextGroups.updateCategoryCounts($(this));
  });
  $("#tabs_loading_wrapper").show();
});