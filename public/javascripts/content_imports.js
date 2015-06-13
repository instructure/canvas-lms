define([
  'i18n!content_imports',
  'compiled/util/processMigrationItemSelections',
  'jquery' /* $ */,
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_date_and_time' /* dateString, date_field */,
  'jquery.instructure_forms' /* formSubmit, getFormData, validateForm */,
  'jquery.instructure_misc_plugins' /* showIf */,
  'compiled/jquery.rails_flash_notifications',
  'vendor/date' /* Date.parse */,
  'jqueryui/progressbar' /* /\.progressbar/ */
], function(I18n, processMigrationItemSelections, $) {

  $(function () {
    $(".date_field").date_field();
    var pendingPopulates = 0;
    var populateItem = function ($item, id, name, param_name) {
      pendingPopulates += 1;
      setTimeout(function () {
        if ($item != null) {
          var full_param_name = param_name + "[" + id + "]";
          $item.find(":checkbox:first")
            .attr('name', full_param_name)
            .attr('id', full_param_name.replace(/[\[\]]+/g, "_"));
          if (name != null) {
            $item.find("label:first")
              .text(name);
          }
          $item.find("label:first")
            .attr('for', full_param_name.replace(/[\[\]]+/g, "_"));
          $item.show();
        }
        pendingPopulates -= 1;
        if (pendingPopulates <= 0) {
          $("#copy_context_form_loading").hide();
          $("#copy_context_form").show();
        }
      });
    };
    $.ajaxJSON(location.href, 'GET', {}, function (data) {
      if (data.start_timestamp) {
        var date = $.dateString(data.start_timestamp);
        $('#copy_old_start_date').val(date);
      }
      if (data.end_timestamp) {
        var date = $.dateString(data.end_timestamp);
        $('#copy_old_end_date').val(date);
      }
      $("#copy_quizzes_list").showIf(data.assessments && data.assessments.length > 0);
      if (data.assessments && data.assessments) {
        for (var idx in data.assessments) {
          var quiz = data.assessments[idx];
          var $quiz = $("#copy_quizzes_list .quiz:first").clone(true);
          populateItem($quiz, quiz.assessment_id || quiz.migration_id, quiz.assessment_title || quiz.quiz_name, 'copy[quizzes]');
          $("#copy_quizzes_list ul.quizzes_list").append($quiz);
        }
      }
      $("#copy_assignments_list").showIf(data.assignments && data.assignments.length > 0);
      if (data.assignments) {
        for (var idx in data.assignments) {
          var assignment = data.assignments[idx];
          var $assignment = $("#copy_assignments_list .assignment:first").clone(true);
          populateItem($assignment, assignment.migration_id, assignment.title, 'copy[assignments]');
          $("#copy_assignments_list ul").append($assignment);
        }
      }
      $("#copy_announcements_list").showIf(data.announcements && data.announcements.length > 0);
      if (data.announcements) {
        for (var idx in data.announcements) {
          var announcement = data.announcements[idx];
          var $announcement = $("#copy_announcements_list .announcement:first").clone(true);
          populateItem($announcement, announcement.migration_id, announcement.title, 'copy[announcements]');
          $("#copy_announcements_list ul").append($announcement);
        }
      }
      $("#copy_events_list").showIf(data.calendar_events && data.calendar_events.length > 0);
      if (data.calendar_events) {
        for (var idx in data.calendar_events) {
          var event = data.calendar_events[idx];
          var $event = $("#copy_events_list .event:first").clone(true);
          populateItem($event, event.migration_id, event.title, 'copy[events]');
          $("#copy_events_list ul").append($event);
        }
      }
      $("#copy_modules_list").showIf(data.modules && data.modules.length > 0);
      if (data.modules) {
        for (var idx in data.modules) {
          var module = data.modules[idx];
          var $module = $("#copy_modules_list .module:first").clone(true);
          populateItem($module, module.migration_id, module.title, 'copy[modules]');
          $("#copy_modules_list ul").append($module);
        }
      }
      $("#copy_rubrics_list").showIf(data.rubrics && data.rubrics.length > 0);
      if (data.rubrics) {
        for (var idx in data.rubrics) {
          var rubric = data.rubrics[idx];
          var $rubric = $("#copy_rubrics_list .rubric:first").clone(true);
          populateItem($rubric, rubric.migration_id, rubric.title, 'copy[rubrics]');
          $("#copy_rubrics_list ul").append($rubric);
        }
      }
      $("#copy_groups_list").showIf(data.groups && data.groups.length > 0);
      if (data.groups) {
        for (var idx in data.groups) {
          var group = data.groups[idx];
          var $group = $("#copy_groups_list .group:first").clone(true);
          populateItem($group, group.migration_id, group.title, 'copy[groups]');
          $("#copy_groups_list ul").append($group);
        }
      }
      $("#copy_assignment_groups_list").showIf(data.assignment_groups && data.assignment_groups.length > 0);
      if (data.assignment_groups) {
        for (var idx in data.assignment_groups) {
          var assignment_group = data.assignment_groups[idx];
          var $assignment_group = $("#copy_assignment_groups_list .assignment_group:first").clone(true);
          populateItem($assignment_group, assignment_group.migration_id, assignment_group.title, 'copy[assignment_groups]');
          $("#copy_assignment_groups_list ul").append($assignment_group);
        }
      }
      $("#copy_wikis_list").showIf(data.wikis && data.wikis.length > 0);
      if (data.wikis) {
        for (var idx in data.wikis) {
          var wiki = data.wikis[idx];
          var $wiki = $("#copy_wikis_list .wiki:first").clone(true);
          populateItem($wiki, wiki.migration_id, wiki.title, 'copy[wikis]');
          $("#copy_wikis_list ul").append($wiki);
        }
      }
      $("#copy_external_tools_list").showIf(data.external_tools && data.external_tools.length > 0);
      if (data.external_tools) {
        for (var idx in data.external_tools) {
          var tool = data.external_tools[idx];
          var $tool = $("#copy_external_tools_list .external_tool:first").clone(true);
          populateItem($tool, tool.migration_id, tool.title, 'copy[external_tools]');
          $("#copy_external_tools_list ul").append($tool);
        }
      }
      var topic_count = 0;
      $("#copy_topics_list").showIf(data.discussion_topics && data.discussion_topics.length > 0);
      if (data.discussion_topics) {
        for (var idx in data.discussion_topics) {
          var topic = data.discussion_topics[idx];
          topic.entry_count = 0; //entryCount(topic);
          var $topic = $("#copy_topics_list .topic:first").clone(true);
          populateItem($topic, topic.migration_id, topic.title, 'copy[topics]');
          //$topic.find(".sub_entry_count").text(topic.migration_id);
          populateItem($topic.children("div"), topic.topic_id, null, 'copy[topic_entries]');
          $("#copy_topics_list ul").append($topic);
        }
      }
      var outline_count = 0;
      if (data.course_outline) {
        var checkItem = function (obj, root) {
          if (obj && obj.migration_id) {
            outline_count++;
            var $outline = $("#copy_outline_folders_list .outline_folder:first").clone(true);
            if (root) {
              obj.title = I18n.t('titles.home_page', "Home Page");
            }
            populateItem($outline, obj.migration_id, obj.title, 'copy[outline_folders]');
            $("#copy_outline_folders_list ul").append($outline);
          }
          for (var idx in obj.contents) {
            checkItem(obj.contents[idx]);
          }
        };
        checkItem(data.course_outline, true);
      }
      $("#copy_outline_folders_list").showIf(outline_count > 0);
      var file_count = 0;
      if (data.file_map) {
        var folders = {};
        var folderNames = [];
        for (var idx in data.file_map) {
          var file = data.file_map[idx];
          if (!file.is_folder) {
            var folder = file.path_name.split('/');
            var filename = folder.pop();
            folder = folder.join('/') || "";
            if (!folders[folder]) {
              var $folder = $("#copy_files_list .folder:first").clone(true);
              $folder.find("ul").empty();
              populateItem($folder, file.migration_id, folder || "/", 'copy[folders]');
              folderNames.push(folder);
              folders[folder] = $folder;
            }
            var $file = $("#copy_files_list .file:first").clone(true);
            populateItem($file, file.migration_id, filename, 'copy[files]');
            folders[folder].find("ul").append($file);
            file_count++;
          }
        }
        folderNames = folderNames.sort();
        for (var idx in folderNames) {
          var $folder = folders[folderNames[idx]];
          $("#copy_files_list").append($folder);
        }
      }
      populateItem(null, null, null, null);
      $("#copy_files_list").showIf(file_count > 0);
      $("#copy_context_form .course_name").text(data.name);
      $("#copy_everything").prop('checked', true).change();
    });
    $("#copy_context_form :checkbox").change(function () {
      if ($(this).hasClass('copy_all')) {
        $(this).parent().nextAll("ul").find(":checkbox:not(.secondary_checkbox)").prop('checked', $(this).prop('checked')).each(function () {
          $(this).triggerHandler('change');
        });
      } else if ($(this).hasClass('copy_everything')) {
        $("#copy_context_form :checkbox:not(.secondary_checkbox):not(.copy_everything):not(.shift_dates_checkbox)").prop('checked', $(this).prop('checked')).filter(":not(.copy_all)").each(function () {
          $(this).triggerHandler('change');
        });
      } else {
        $(this).parent().find(":checkbox.secondary_checkbox").prop('checked', $(this).prop('checked'));
        if (!$(this).prop('checked')) {
          $(this).parents("ul").each(function () {
            $(this).prevAll("h2,h3,h4").find(":checkbox").prop('checked', false);
          });
          $("#copy_everything").prop('checked', false);
        }
      }
    });
    $(".shift_dates_checkbox").change(
            function () {
              $(".shift_dates_settings").showIf($(this).prop('checked'));
            }).change();
    $(".add_substitution_link").click(function (event) {
      event.preventDefault();
      var $sub = $(".substitution_blank").clone(true).removeClass('substitution_blank');
      $(".substitutions").append($sub.hide());
      var $select = $(".weekday_select_blank").clone(true).removeClass('weekday_select_blank');
      $sub.find(".old_select").empty().append($select.clone(true));
      $sub.find(".new_select").empty().append($select);
      $sub.find(".old_select").children("select").change();
      $sub.slideDown();
    });
    $(".weekday_select").change(function () {
      if ($(this).parents(".old_select").length > 0) {
        var $select = $(this).parents(".substitution").find(".new_select").children("select");
        $select.attr('name', 'copy[day_substitutions][' + $(this).val() + ']');
      }
    });
    $(".delete_substitution_link").click(function (event) {
      event.preventDefault();
      $(this).parents(".substitution").slideUp(function () {
        $(this).remove();
      });
    });

    $(".copy_progress").progressbar();
    // todo change to formsubmit
    $("#copy_context_form").formSubmit({
      processData:processMigrationItemSelections,
      beforeSubmit:function (data) {
        setTimeout(function () {
          $("#copy_context_form").find(":checkbox,:text,select").attr('disabled', true);
        }, 1000);
        $("#copy_context_form .submit_button").text(I18n.t('messages.importing_button', "Importing... this could take a while")).attr('disabled', true);
        $(".progress_bar_holder").slideDown();
      },
      success:function (data) {
        var state = "nothing";
        var fakeTickCount = 0;
        var tick = function () {
          if (state == "nothing") {
            fakeTickCount++;
            var progress = ($(".copy_progress").progressbar('option', 'value') || 0) + 0.25;
            if (fakeTickCount < 10) {
              $(".copy_progress").progressbar('option', 'value', progress);
            }
            setTimeout(tick, 2000);
          } else {
            state = "nothing";
            fakeTickCount = 0;
            setTimeout(tick, 10000);
          }
        };
        var checkup = function () {
          var url = $("#copy_context_form").attr('action'); //location.href;
          var lastProgress = null;
          var waitTime = 1500;
          $.ajaxJSON(url, 'GET', {}, function (data) {
            state = "updating";
            var course_import = data.content_migration;
            var progress = 0;
            if (course_import) {
              progress = Math.max($(".copy_progress").progressbar('option', 'value') || 0, course_import.progress);
              if( course_import.workflow_state == "exported") {
                progress = 0;
              }
              $(".copy_progress").progressbar('option', 'value', progress);
            }
            if (course_import && course_import.workflow_state == 'imported') {
              $.flashMessage(I18n.t('messages.import_complete', "Import Complete!  Returning to the Course Page..."));
              location.href = $(".course_url").attr('href');
            } else if (course_import && course_import.workflow_state == 'failed') {
              var code = "ContentMigration:" + $(".content_migration_id:first").text() + ":" + course_import.progress;
              var message = I18n.t('errors.import_failed', "There was an error during your migration import.  Please notify your system administrator and give them the following code: \"%{code}\"", {code:code});
              $.flashError(message);
              $(".progress_message").text(message);
            } else {
              if (progress == lastProgress) {
                waitTime = Math.max(waitTime + 500, 30000);
              } else {
                waitTime = 1500;
              }
              lastProgress = progress;
              setTimeout(checkup, 1500);
            }
          }, function () {
            setTimeout(checkup, 3000);
          });
        };
        setTimeout(checkup, 2000);
        setTimeout(tick, 1000);
        return true;
      }
    });
  });
});
