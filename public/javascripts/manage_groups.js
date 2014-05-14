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
  'i18n!groups',
  'jquery' /* $ */,
  'underscore',
  'compiled/fn/preventDefault',
  'compiled/views/MessageStudentsDialog',
  'jqueryui/draggable' /* /\.draggable/ */,
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_forms' /* formSubmit, fillFormData, formErrors */,
  'jqueryui/dialog',
  'jquery.instructure_misc_helpers' /* replaceTags */,
  'jquery.instructure_misc_plugins' /* confirmDelete, showIf */,
  'jquery.loadingImg' /* loadingImage */,
  'compiled/jquery.rails_flash_notifications',
  'jquery.templateData' /* fillTemplateData, getTemplateData */,
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */,
  'jqueryui/droppable' /* /\.droppable/ */,
  'jqueryui/tabs' /* /\.tabs/ */
], function(I18n, $, _, preventDefault, MessageStudentsDialog) {

  window.contextGroups = {
    autoLoadGroupThreshold: 15,
    paginationSize: 15,

    populateUserElement: function($user, data) {
      if (data.sections) {
        data.section_id = _(data.sections).pluck('section_id').join(",");
        data.section_code = _(data.sections).pluck('section_code').join(", ");
      }

      $user.removeClass('user_template');
      $user.addClass('user_id_' + data.user_id);
      $user.fillTemplateData({ data: data });
    },

    loadMembersForGroup: function($group) {
      var url = ENV.list_users_url;
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
        var $user_template = $(".user_template");
        for (var i = 0; i < data.length; i++) {
          var $user = $user_template.clone();
          contextGroups.populateUserElement($user, data[i]);
          contextGroups.insertIntoGroup($user, $group);

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

      var students_visible = $group.find(".student_list .student").length;
      var students_hidden = parseInt($group.find(".user_count_hidden").text());
      var total_students = students_visible + students_hidden;

      // ensure we don't try to go to a page that won't have any students on it
      if (total_students > 0) {
        page = Math.min(page, Math.floor((total_students - 1) / contextGroups.paginationSize) + 1);
      }

      // This is lots of duplicated code from above, with tweaks. TODO: Refactor
      var category_id = $group.closest(".group_category").data('category_id');
      var url = ENV.list_unassigned_users_url;
      url += "?category_id=" + category_id + "&page=" + page;

      $group.find(".load_members_link").hide();
      $group.find(".loading_members").show();

      $.ajaxJSON(url, "GET", null, function(data) {
        $group.data("page_loaded", page);
        $group.find(".user_count").text(I18n.t('category.student', 'student', {count: data['total_entries']}));
        $group.find(".user_count_hidden").text(data['total_entries'] - data['users'].length);
        $group.find(".group_user_count").show();
        $group.find(".student").remove();
        $group.find(".student_links").showIf(data['total_entries'] > 0);

        var $user_template = $(".user_template");
        var users = data['users'];
        for (var i = 0; i < users.length; i++) {
          var $user = $user_template.clone();
          contextGroups.populateUserElement($user, users[i]);
          contextGroups.insertIntoGroup($user, $group);
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
      var url = ENV.add_user_url;
      var data = {};
      var method;
      if (id) {
        method = "POST";
        data.user_id = user_id;
      } else {
        method = "DELETE";
        url = $.replaceTags(ENV.remove_user_url, "user_id", user_id);
        id = $original_group.getTemplateData({textValues: ['group_id']}).group_id;
      }
      url = $.replaceTags(url, "id", id);
      $student.remove();

      var $student_instances = $student;
      contextGroups.insertIntoGroup($student, $group);
      $category = $group.parents(".group_category")
      if($category.hasClass('student_organized') && !$group.hasClass('group_blank')) {
        var $s = $student.clone();
        $student_instances = $student_instances.add($s);
        contextGroups.insertIntoGroup($s, $original_group);
      }
      $student = $student_instances;
      $student.addClass('event_pending');
      contextGroups.updateCategoryCounts($group.parents(".group_category"));
      $.ajaxJSON(url, method, data, function(data) {
        var category_id = $group.parents(".group_category").data('category_id');
        $(".student.user_" + user_id).each(function() {
          var $span = $(this).find(".category_" + category_id + "_group_id");
          if(!$span || $span.length == 0) {
            $span = $(document.createElement('span'));
            $span.addClass('category_' + category_id + '_group_id');
            $(this).find(".data").append($span);
          }
          $span.text(data.group_membership.group_id || "");
        });

        $student.removeClass('event_pending');
        contextGroups.updateCategoryCounts($group.parents(".group_category"));

        var groups = $($original_group);
        groups = groups.add($group);
        contextGroups.updateCategoryHeterogeneity($group.parents(".group_category"), groups);

        var unassigned_group = $group.parents(".group_category").find(".group_blank");
        var students_visible = unassigned_group.find(".student_list .student").length;
        var students_hidden = parseInt(unassigned_group.find(".user_count_hidden").text());

        if (students_visible <= 5 && students_hidden > 0) {
          contextGroups.loadUnassignedMembersPage(unassigned_group, 0);
        }
      },
      function(data) {
        // move failed, undo it
        $student.remove();
        $student = $student.first();
        contextGroups.insertIntoGroup($student, $original_group);
        $student.removeClass('event_pending');
        contextGroups.updateCategoryCounts($category);

        var message;
        if (data.errors && data.errors.user_id) {
          // attempted group membership claims the user was unacceptable for
          // some reason (probably section).
          message = data.errors.user_id[0].message;
        } else if (data.errors && data.errors.group_id) {
          message = data.errors.group_id[0].message;
        } else {
          message = I18n.t('errors.unknown', 'An unexpected error occurred.');
        }
        $.flashError(message);
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
        var $this = $(this);
        var userCount = $this.find(".student_list .student").length + parseInt($this.find(".user_count_hidden").text());
        $this.find(".user_count").text(I18n.t('category.student', 'student', {count: userCount}));
        $this.find(".student_links").showIf(userCount > 0);
      });

      var groupCount = $category.find(".group:not(.group_blank)").length;
      $category.find(".group_count").text(I18n.t('group', 'Group', {count: groupCount}));

      $category.find(".group").each(function() {
        $(this).find(".expand_collapse_links").showIf($(this).find(".student_list li").length > 0);
      });
    },

    updateCategoryHeterogeneity: function($category, groups) {
      // check if any of the provided groups are heterogenous now (skipping the
      // "unassigned" group should it be involved).
      var heterogenous = false;
      groups.each(function() {
        var section_id_counts = {};
        $section_ids = $(this).find(".student_list .student .section_id");
        if (!$(this).hasClass('group_blank') && $section_ids.length > 0 && $section_ids.text()) {
          $section_ids.each(function() {
            var section_ids = $(this).text().split(",");
            for (var i = 0; i < section_ids.length; i++) {
              if (!section_id_counts[section_ids[i]]) {
                section_id_counts[section_ids[i]] = 0;
              }
              section_id_counts[section_ids[i]] += 1;
            }
          });

          var found = true;
          for (var section_id in section_id_counts) {
            if (section_id_counts[section_id] === $section_ids.length) {
              found = false;
            }
          }
          heterogenous = heterogenous || found;
        }
      });
      $category.find('.heterogenous').text(heterogenous ? 'true' : 'false');
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
      if ($category.length) {
        contextGroups.loadUnassignedMembersPage($category.find(".group_blank"), -1);
      }
    },

    updateCategory: function($category, category) {
      // update name in $category, tab, and sidebar
      $category.find('.category_name').text(category.name);
      $($category.data('tab_link')).text(category.name);
      $('#sidebar_category_' + category.id + ' .category').text(category.name);

      // put self_signup value in $category template data, and toggle
      // appropriate self signup text
      $category.find('.self_signup').text(category.self_signup || '');
      $category.find('.self_signup_text').showIf(category.self_signup);
      $category.find('.restricted_self_signup_text').showIf(category.self_signup === 'restricted');
      $category.find('.assign_students_link').showIf(category.self_signup !== 'restricted');
      $category.find('.group_limit_blurb').showIf(category.group_limit);
      $category.find('.group_limit, .group_limit_text').text(category.group_limit || '');
      $category.find('.students_link_separator').showIf(category.self_signup && category.self_signup !== 'restricted');
      $category.find('.message_students_link').showIf(category.self_signup);
    },

    addGroupToSidebar: function(group) {
      if($("#sidebar_group_" + group.id).length > 0) {
        return;
      }
      var $category = $("#sidebar_category_" + group.group_category_id);
      if($category.length == 0) {
        $category = $("#sidebar_category_blank").clone(true);
        $category.find("ul").empty();
        $category.fillTemplateData({
          data: group,
          id: 'sidebar_category_' + group.group_category_id
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
      $group.find(".student_links").remove();
      $group.find(".student_list").empty();
      $group.removeClass('group_blank');
      $group.find(".load-more").hide();
      $group.find(".name").text(I18n.t('group_name', "Group Name"));
      $category.find(".clearer").before($group.show());
      $group.find(".edit_group_link").click();
    });
    $("#edit_group_form").formSubmit({
      object_name: "group",
      processData: function(data) {
        data['group[group_category_id]'] = $(this).parents(".group_category").data('category_id');
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
        $group.loadingImage('remove');
        $group.droppable(contextGroups.droppable_options);
        $group.find(".name.blank_name").hide().end()
          .find(".group_name").show();
        $group.find(".group_user_count").show();
        data.group_id = data.id;
        $group.fillTemplateData({
          id: 'group_' + data.id,
          data: data,
          avoid: '.student_list',
          hrefValues: ['id']
        });
        contextGroups.addGroupToSidebar(data)
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
        $form.attr('method', 'POST').attr('action', ENV.add_group_url);
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
    $("#edit_category_form").formSubmit({
      object_name: "category",
      property_validations: {
        'name': function(val, data) {
          var $category = $(this).parents('.group_category');
          var original_name = $category.find('.category_name:first').text();
          if (original_name.toLowerCase() == val.toLowerCase()) {
            return;
          }
          var found = false;
          $("#category_list .category").each(function() {
            if($(this).text().toLowerCase() == val.toLowerCase()) {
              found = true;
              return false;
            }
          });
          if(found) {
            return I18n.t('errors.category_in_use', "\"%{category_name}\" is already in use", {category_name: val});
          }
        },
        'group_limit': function(val, data) {
          if (parseInt(val) <= 1) {
            return I18n.t('errors.group_limit', 'Group limit must be blank or greater than 1')
          }
          return false;
        }
      },
      beforeSubmit: function(data) {
        var $category = $(this).parents(".group_category");
        var tab_index = $("#group_tabs").tabs('option', 'selected');
        var tab_link = $($('#category_list .category')[tab_index]).find('a');
        $category.data('tab_link', tab_link);
        $(this).find("button").attr('disabled', true);
        $(this).find(".submit_button").text(I18n.t('status.updating', "Updating..."));
        $(this).loadingImage();
        return $category;
      },
      success: function(data, $category) {
        contextGroups.updateCategory($category, data.group_category);
        $(this).loadingImage('remove');
        $(this).remove();
        $category.removeClass('editing');
      },
      error: function(data) {
        $(this).loadingImage('remove');
        $(this).find("button").attr('disabled', false);
        $(this).find(".submit_button").text(I18n.t('errors.update_failed', "Update Failed, Try Again"));
        $(this).formErrors(data);
      }
    });
    $(".edit_category_link").click(function(event) {
      event.preventDefault();
      var $category = $(this).parents(".group_category");
      var $form = $("#edit_category_form").clone(true);

      // fill out form given the current category values
      var data = $category.getTemplateData({textValues: ['category_name', 'self_signup', 'heterogenous', 'group_limit']});
      var form_data = {
        name: data.category_name,
        enable_self_signup: data.self_signup !== null && data.self_signup !== '',
        restrict_self_signup: data.self_signup == 'restricted',
        group_limit: data.group_limit
      };
      $form.fillFormData(form_data, { object_name: 'category' });
      $form.find("#category_restrict_self_signup").prop('disabled', !form_data.enable_self_signup || data.heterogenous == 'true');
      $form.find("#group_structure_self_signup_subcontainer").showIf( $form.find('#category_enable_self_signup').is(':checked') );

      $category.addClass('editing');
      $category.prepend($form.show());
      $form.find(":input:visible:first").focus().select();
      $form.attr('method', 'PUT').attr('action', $category.find(".edit_category_link").attr('href'));
      $category.scrollTo($form.find(":input:visible:first"));
    });
    $("#edit_category_form .cancel_button").click(function() {
      var $category = $(this).parents(".group_category");
      $category.removeClass('editing');
      $(this).parents("form").remove();
    });
    $(".delete_category_link").click(function(event) {
      event.preventDefault();
      var index = $("#group_tabs").tabs('option', 'selected')
      if(index == -1) {
        index = $("#category_list li").index($("#category_list li.ui-tabs-selected"));
      }
      var $category = $(this).parents(".group_category");
      var url = $.replaceTags($(this).attr('href'), "category_id", $category.data('category_id'))
      $category.confirmDelete({
        url: url,
        message: I18n.t('confirm.remove_category', "Are you sure you want to remove this set of groups?"),
        success: function() {
          categories_remaining = $("#category_list li").length;
          $("#group_tabs").tabs('remove', index);
          $("#group_tabs").showIf(categories_remaining > 0);
          var category_id = $(this).data('category_id');
          if (categories_remaining > 0) {
            if (index > categories_remaining) {
              index = categories_remaining;
            }
            $("#group_tabs").tabs('select', index);
          }
          $("#sidebar_category_" + category_id).slideUp(function() {
            $(this).remove();
          });
          $("#no_groups_message").showIf(categories_remaining == 0);
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
        var group_category = data[0].group_category;
        var groups = data[1];
        for(var idx in groups) {
          var group = groups[idx].group || groups[idx].course_assigned_group;

          group.group_id = group.id;
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
            for(var jdx in group.users) {
              var user = group.users[jdx].user;
              var $span = $(document.createElement('span')).addClass('category_' + group_category.id + "_group_id");
              $span.text(group.id);
              $(".student.user_" + user.id).find(".data").append($span);
            }
          }

          $group.find(".name.blank_name").hide().end()
            .find(".group_name").show();
          $group.find(".group_user_count").show();
        }
        $category.fillTemplateData({
          data: {
            category_id: group_category.id,
            category_name: group_category.name,
            self_signup: group_category.self_signup
          },
          hrefValues: ['category_id']
        });
        $category.attr('id', 'category_' + group_category.id);
        $category.data('category_id', group_category.id);
        $category.find('.self_signup_text').showIf(group_category.self_signup);
        $category.find('.restricted_self_signup_text').showIf(group_category.self_signup == 'restricted');
        $category.find('.assign_students_link').showIf(group_category.self_signup !== 'restricted');
        $category.find('.students_link_separator').showIf(group_category.self_signup && group_category.self_signup !== 'restricted');
        $category.find('.message_students_link').showIf(group_category.self_signup);

        var newIndex = $("#group_tabs").tabs('length');
        if ($("li.category").last().hasClass('student_organized')) {
          newIndex -= 1;
        }
        $("#group_tabs").append($category);
        $("#group_tabs").tabs('add', '#category_' + group_category.id, group_category.name, newIndex);
        $("#group_tabs").tabs('select', newIndex);
        contextGroups.populateCategory($category);
        contextGroups.updateCategory($category, group_category);
        contextGroups.updateCategoryCounts($category);
        $(window).triggerHandler('resize');
      });
    });
    $("#add_category_form").formSubmit({
      property_validations: {
        'category[name]': function(val, data) {
          var found = false;
          $("#category_list .category").each(function() {
            if($(this).text().toLowerCase() == val.toLowerCase()) {
              found = true;
              return false;
            }
          });
          if(found) {
            return I18n.t('errors.category_in_use', "\"%{category_name}\" is already in use", {category_name: val});
          }
        },
        'category[group_limit]': function(val, data) {
          if (parseInt(val) <= 1) {
            return I18n.t('errors.group_limit', 'Group limit must be blank or greater than 1')
          }
          return false;
        }
      },
      beforeSubmit: function(data) {
        $(this).loadingImage();
        $(this).data('category_name', data['category[name]']);
        $(this).find("button").attr('disabled', true);
        $(this).find(".submit_button").text(I18n.t('status.creating_groups', "Creating Category..."));
      },
      success: function(data) {
        $(this).loadingImage('remove');
        var callbacks = $(this).data('callbacks') || [];
        for(var idx in callbacks) {
          var callback = callbacks[idx];
          if(callback && $.isFunction(callback)) {
            callback.call(this, data);
          }
        }
        $(this).data('callbacks', [])
        $(this).find("button").attr('disabled', false);
        $(this).find(".submit_button").text(I18n.t('button.create_category', "Create Category"));
        $(this).dialog('close');
      },
      error: function(data) {
        $(this).loadingImage('remove');
        $(this).find("button").attr('disabled', false);
        $(this).find(".submit_button").text(I18n.t('errors.creating_category_failed', "Category Creation Failed, Try Again"));
        $(this).formErrors(data);
      }
    });
    $("#add_category_form .cancel_button").click(function() {
      $("#add_category_form").dialog('close');
    });
    $("#add_category_form #category_enable_self_signup").change(function() {
      var self_signup = $(this).prop('checked')
      $("#add_category_form #category_restrict_self_signup").prop('disabled', !self_signup);
      $("#add_category_form #group_structure_standard_subcontainer").showIf(!self_signup);
      $("#add_category_form #group_structure_self_signup_subcontainer").showIf(self_signup);
      if (!self_signup) {
        $("#add_category_form #category_restrict_self_signup").prop('checked', false);
      }
    });
    $("#edit_category_form #category_enable_self_signup").change(function() {
      var self_signup = $(this).prop('checked');
      var heterogenous = $(this).parents('.group_category').find('.heterogenous').text() == 'true';
      var disable_restrict = !self_signup || heterogenous;
      $("#edit_category_form #category_restrict_self_signup").prop('disabled', disable_restrict);
      $("#edit_category_form #group_structure_self_signup_subcontainer").showIf(self_signup);
      if (disable_restrict) {
        $("#edit_category_form #category_restrict_self_signup").prop('checked', false);
      }
    });
    $(".load_members_link").click(function(event) {
      event.preventDefault();
      contextGroups.loadMembersForGroup($(this).parents(".group"));
    });
    $(".delete_group_link").click(function(event) {
      event.preventDefault();
      $(this).parents(".group").confirmDelete({
        message: I18n.t('confirm.delete_group', "Are you sure you want to delete this group?"),
        url: $(this).attr('href'),
        success: function() {
          var $blank_category = $(this).parents(".group_category").find(".group_blank");
          var group_id = $(this).getTemplateData({textValues: ['group_id']}).group_id;
          $("#sidebar_group_" + group_id).slideUp(function() {
            $(this).remove();
          });
          $(this).slideUp(function() {
            var $category = $(this).parents(".group_category");
            if (!$category.hasClass('student_organized')) {
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

      // confirm before proceeding
      var result = confirm(I18n.t('confirm.assign_students', "This will randomly assign all unassigned students as evenly as possible among the existing student groups"));
      if (!result) { return; }

      // indicate 'working' in visual state
      var $category = $(this).parents(".group_category");
      var $unassigned = $category.find(".group_blank");
      $unassigned.find(".assign_students_link").hide();
      $unassigned.find(".loading_members").text(I18n.t('status.assigning_students', "Assigning Students..."));
      $unassigned.find(".loading_members").show();

      // perform ajax request to do the assignment server side
      var url = ENV.assign_unassigned_users_url;
      url = $.replaceTags(url, "category_id", $category.data('category_id'));
      $.ajaxJSON(url, "POST", {'sync': true}, function(data) {
        if (!data.length) {
          // reset visual state
          $unassigned.find(".assign_students_link").show();
          $unassigned.find(".loading_members").hide();
          $(window).triggerHandler('resize');
          $.flashError(I18n.t('notices.no_students_assigned', "Nothing to do."));
          return;
        }
        var user_template = $(".user_template");
        for (var i = 0; i < data.length; i++) {
          var group = data[i];
          var $group = $category.find('#group_' + group.id);
          for (var j = 0; j < group.new_members.length; j++) {
            var user = group.new_members[j];

            // remove existing user element, if any
            $category.find('.user_id_' + user.user_id).remove();

            // create new user element and place it in the right group
            var $user = user_template.clone();
            contextGroups.populateUserElement($user, user);
            contextGroups.insertIntoGroup($user, $group);
          }
        }

        // update visual state
        contextGroups.updateCategoryCounts($category);
        $unassigned.find(".assign_students_link").show();
        $unassigned.find(".loading_members").hide();
        $(window).triggerHandler('resize');
        $.flashMessage(I18n.t('notices.students_assigned', "Students assigned to groups."));
      }, function(data) {
        // reset visual state
        $unassigned.find(".assign_students_link").show();
        $unassigned.find(".loading_members").hide();
        $(window).triggerHandler('resize');
      });
    });
    $(".self_signup_help_link").click(function(event) {
      event.preventDefault();
      $("#self_signup_help_dialog").dialog({
        title: I18n.t('titles.self_signup_help', "Self Sign-Up Groups"),
        width: 400
      });
    });
    $("#category_split_groups").on('click', function() {
      $("#category_split_group_count").val("1");
    });
    $("#category_no_groups").on('click', function() {
      $("#category_split_group_count").val("");
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


    function loadUnassignedStudentsFor(categoryId) {
      var $studentsDfrd = $.Deferred();
      var students = [];
      var baseUrl = ENV.list_unassigned_users_url + "?no_html=1&category_id=" + categoryId + "&per_page=100&page=";

      var fetch = function(url) {
        $.ajaxJSON(url, 'GET', null, function(data) {
          _.each(data.users, function(user) {
            students.push({id: user.user_id, short_name: user.display_name});
          });
          if (data.next_page)
            fetch(baseUrl + data.next_page);
          else
            $studentsDfrd.resolve(students);
        }, function() { $studentsDfrd.reject(); });
      };

      fetch(baseUrl + "1");
      return $studentsDfrd;
    }

    $(".message_students_link").click(preventDefault(function() {
      // jQuery sadness until we rewrite public/javascripts/manage_groups.js :(
      var $category = $(this).closest('.group_category');
      var categoryName = $category.find('.category_name').first().text();
      var categoryId = $category.data('category_id');

      loadUnassignedStudentsFor(categoryId).then(function(students) {
        var dialog = new MessageStudentsDialog({
          context: categoryName,
          recipientGroups: [
            {name: I18n.t('students_who_have_not_joined_a_group', 'Students who have not joined a group'), recipients: students}
          ]});
        dialog.open();
      });
    }));
  });
});

