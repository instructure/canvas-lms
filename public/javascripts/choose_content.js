define([
  'jquery' /* $ */,
  'i18n!content_imports',
  'compiled/util/processMigrationItemSelections',
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_date_and_time' /* date_field */,
  'jquery.instructure_forms' /* formSubmit */,
  'jqueryui/dialog',
  'jquery.instructure_misc_plugins' /* .dim, showIf */,
  'compiled/jquery.rails_flash_notifications',
  'jqueryui/autocomplete' /* /\.autocomplete/ */,
  'jqueryui/progressbar' /* /\.progressbar/ */
], function($, I18n, processMigrationItemSelections){

  $(function () {
    var $frame = $("<iframe id='copy_course_target' name='copy_course_target' src='about:blank'/>");
    $("body").append($frame.hide());
    $("#copy_context_form").attr('target', 'copy_course_target');
    $(".copy_progress").progressbar();

    var checkup = function (url) {
      $.ajaxJSON(url, 'GET', {}, function (data) {
        if (data && data.workflow_state) {
          $(".copy_progress").progressbar('option', 'value', data.progress);
        }
        if (data && (data.workflow_state == 'completed' || data.workflow_state == 'imported')) {
          window.location = ENV.COPY_COURSE_FINISH_URL + "?content_migration_id=" + data.id;
        } else if (data && data.workflow_state == 'failed') {
          var message = I18n.t('errors.failed', "Course Import failed with the following error:") + " \"import_" + data.id + "\"";
          $.flashError(message);
          $(".progress_bar_holder").after("<b>" + message + "</b>");
        } else {
          setTimeout(function () {
            checkup(url);
          }, 1500);
        }
      }, function () {
        setTimeout(function () {
          checkup(url);
        }, 3000);
      });
    };

    $("#copy_context_form").formSubmit({
      processData:processMigrationItemSelections,
      beforeSubmit:function (data) {
        $("#copy_context_form .submit_button").text(I18n.t('messages.copying', "Copying... this will take a few minutes")).attr('disabled', true);
        $(".progress_bar_holder").show();
      },
      success:function (data) {
        setTimeout(function () {
          checkup(data.status_url);
        }, 5000);
      }
    });

    $("#copy_entries_dialog button").click(function () {
      var $checkbox = $("#copy_all_discussion_topics");
      var include_secondaries = $(this).hasClass('include');
      if (include_secondaries) {
        $checkbox.parent().next("ul").find(":checkbox:not(.secondary_checkbox)").prop('checked', $checkbox.prop('checked')).each(function () {
          $(this).triggerHandler('change', true);
        });
      } else {
        $checkbox.parent().next("ul").find(":checkbox:not(.secondary_checkbox)").prop('checked', $checkbox.prop('checked'));
      }
      $("#copy_entries_dialog").dialog('close');
    });

    var checkEverything = function (checked) {
      $("#copy_context_form :checkbox:not(.secondary_checkbox):not(.copy_everything):not(.skip_on_everything):not(.shift_dates_checkbox)")
              .prop('checked', checked)
              .filter(":not(.copy_all)")
              .each(function () {
        $(this).triggerHandler('change');
      });
    };

    var itemSelectionsFetchDfd;
    var $itemSelectionsDiv = $("#item_selections");

    $("#copy_context_form").delegate(':checkbox', 'change', function (event, force_secondaries) {
      if (!$(this).attr('checked')) {
        force_secondaries = true;
      }
      if ($(this).hasClass('copy_all')) {
        $(this).parent().next("ul").find(":checkbox:not(.secondary_checkbox)").prop('checked', $(this).prop('checked')).each(function () {
          $(this).triggerHandler('change');
        });
        $('#copy_everything').attr('checked', false);
      } else if ($(this).hasClass('copy_everything')) {
        if ($(this).prop('checked')) {
          $itemSelectionsDiv.hide();
        } else {
          var url = ENV.CONTENT_SELECT_URL;
          itemSelectionsFetchDfd = itemSelectionsFetchDfd || $.ajaxJSON(url, 'GET', {}, function (data) {
            if (data) {
              $itemSelectionsDiv.find('.content_list').html(data.selection_list);
              checkEverything(false);
            }
          });
          $itemSelectionsDiv.show().disableWhileLoading(itemSelectionsFetchDfd);
        }
      } else {
        $(this).parent().find(":checkbox.secondary_checkbox" + (force_secondaries ? '' : ':not(.skip)')).attr('checked', $(this).attr('checked'));
        if ($(this).hasClass('secondary_checkbox') && $(this).attr('checked')) {
          $(this).parents("li").children(":checkbox").attr('checked', true);
        }
        if (!$(this).attr('checked')) {
          $(this).parents("ul").each(function () {
            $(this).prev("h2,h3,h4").find(":checkbox").attr('checked', false);
          });
          if (!$(this).is('#copy_shift_dates')) {
            $('#copy_everything').attr('checked', false);
          }
        }
      }
    });

    $("#check_everything").click(function (event) {
      event.preventDefault();
      checkEverything(true);
    });

    $("#uncheck_everything").click(function (event) {
      event.preventDefault();
      checkEverything(false);
    });

    $(".shift_dates_checkbox").change(
            function () {
              $(".shift_dates_settings").showIf($(this).attr('checked'));
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
    $("#copy_context_form .copy_all").each(function () {
      $(this).triggerHandler('change');
    });
    $(".date_field").date_field();
  });
});
