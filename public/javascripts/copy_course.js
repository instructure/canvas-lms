define([
  'jquery' /* $ */,
  'i18n!content_imports',
  'compiled/util/processItemSelections',
  'use!underscore',
  'compiled/xhr/RemoteSelect',
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_date_and_time' /* date_field */,
  'jquery.instructure_forms' /* formSubmit */,
  'jquery.instructure_jquery_patches' /* /\.dialog/ */,
  'jquery.instructure_misc_plugins' /* .dim, showIf */,
  'jquery.rails_flash_notifications' /* flashError */,
  'jqueryui/autocomplete' /* /\.autocomplete/ */,
  'jqueryui/progressbar' /* /\.progressbar/ */
], function($, I18n, processItemSelections, _, RemoteSelect){

  $(function () {
    var $frame = $("<iframe id='copy_course_target' name='copy_course_target' src='about:blank'/>"),
        $select = $('#copy_from_course'),
        remoteSelect,
        currentCourseId = parseInt(window.location.pathname.split('/')[2]);
    $("body").append($frame.hide());
    $("#copy_context_form").attr('target', 'copy_course_target');
    $(".copy_progress").progressbar();

    if ($select.length) {
      remoteSelect = new RemoteSelect($('#copy_from_course'), {
        formatter: _.bind(function(courses) {
          /**
           * let's start by saying that this function is really long. for that,
           * I apologize. my hope is that most formatters won't have to be this
           * long or unwieldy. with that out of the way, let's begin.
           */

          // start by sorting by date, newest to oldest. this ensures that our
          // terms are displayed newest to oldest.
          courses = courses.sort(function(a, b) {
            return new Date(b.enrollment_start).getTime() - new Date(a.enrollment_start).getTime();
          });

          var terms,
              termMap   = _.groupBy(courses, function(course) { return course.term + ' (' + course.account_name + ')'; }),
              termNames = _.chain(termMap).keys().reduce(function(h, termName) {
                var strippedTermName = termName.replace(/\([^\)]+\)$/, '').trim();
                h[strippedTermName] = h[strippedTermName] || {count: 0, termNames: []};
                h[strippedTermName].count = h[strippedTermName].count + 1;
                h[strippedTermName].termNames.push(termName);
                return h;
              }, {}).value();

          // for each term/account pair, format the courses for display in
          // the <select> and reject the current course. also sort by course
          // course name inside each account.
          terms = _.reduce(termMap, function(memo, v, k) {
            memo[k] = _.chain(v).reject(function(c) {
              return c.id == currentCourseId;
            }).map(function(c) {
              return { label: c.label, value: c.id };
            }).sortBy(function(c) { return c.label }).value();

            return memo;
          }, {});

          // before we return our list of terms and courses, make another loop
          // through them to see if we can strip the account name off of any
          // terms that don't have duplicate names across accounts.
          return _.reduce(terms, function(memo, courses, term) {
            var strippedTermName = term.replace(/\([^\)]+\)$/, '').trim(),
                key = termNames[strippedTermName].count === 1 ?
                  strippedTermName :
                  term;
            memo[key] = courses;
            return memo;
          }, {});
        }, this),
        url: '/users/' + ENV.current_user_id + '/manageable_courses'
      });
      remoteSelect.currentRequest.success(function(data) {
        if (data.length >= 500) {
          $('#select-course-row').hide();
        }
      });
    }

    $('#include_concluded_courses').change(function(e) {
      var el = $(e.currentTarget);
      if (el.prop('checked')) {
        remoteSelect.makeRequest({ 'include[]': 'concluded' });
      } else {
        remoteSelect.makeRequest();
      }
    });

    var checkup = function (url) {
      $.ajaxJSON(url, 'GET', {}, function (data) {
        if (data && data.workflow_state) {
          $(".copy_progress").progressbar('option', 'value', data.progress);
        }
        if (data && data.workflow_state == 'completed') {
          location.href = location.href + "&import_id=" + data.id;
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
      processData:processItemSelections,
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
      var $checkbox = $("#copy_all_topics");
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
    $("#copy_context_form :checkbox").bind('change', function (event, force_secondaries) {
      if (!$(this).attr('checked')) {
        force_secondaries = true;
      }
      if ($(this).hasClass('copy_all')) {
        if ($(this).is('#copy_all_topics') && $(this).attr('checked')) {
          $("#copy_entries_dialog").dialog('close').dialog({
            autoOpen:false,
            title:I18n.t('titles.copy_discussion_replies', "Copy Discussion Replies?"),
            width:370
          }).dialog('open');
        } else {
          $(this).parent().next("ul").find(":checkbox:not(.secondary_checkbox)").prop('checked', $(this).prop('checked')).each(function () {
            $(this).triggerHandler('change');
          });
          $('#copy_everything').attr('checked', false);
        }
      } else if ($(this).hasClass('copy_everything')) {
        $("#copy_context_form :checkbox:not(.secondary_checkbox):not(.copy_everything):not(.skip_on_everything):not(.shift_dates_checkbox)").prop('checked', $(this).prop('checked')).filter(":not(.copy_all)").each(function () {
          $(this).triggerHandler('change');
        });
        $("#copy_all_topics").prop('checked', $(this).prop('checked')).triggerHandler('change');
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
    $("#copy_from_course").change(
            function () {
              var select = $("#copy_from_course")[0];
              var idx = select.selectedIndex;
              var name = select.options[idx].innerHTML;
              var id = select.options[idx].value;
              if (id != "none") {
                $("#course_autocomplete_name_holder").show();
                $("#course_autocomplete_name").text(name);
                $("#course_autocomplete_id").val(id);
                $("#course_autocomplete_id_lookup").val("");
              }
            }).change();
    if ($("#course_autocomplete_id_lookup:visible").length > 0) {
      var autocompleteCache = {},
          lastAutocompleteRequest;

      $("#course_autocomplete_id_lookup").autocomplete({
        source : function(request, response) {
          var src = '/users/' + ENV.current_user_id + '/manageable_courses',
              params = { term: request.term },
              includeConcluded = $('#include_concluded_courses').prop('checked'),
              cacheKey = request.term;

          if (includeConcluded) {
            params['include[]'] = 'concluded';
            cacheKey += '|concluded';
          }

          if (cacheKey in autocompleteCache) {
            response(autocompleteCache[cacheKey]);
            return;
          }

          lastAutocompleteRequest = $.getJSON(src, params, function(data, status, xhr) {
            autocompleteCache[cacheKey] = data;
            if (lastAutocompleteRequest === xhr) { response(data); }
          });
        },
        select:function (event, ui) {
          $("#course_autocomplete_name_holder").show();
          $("#course_autocomplete_name").text(ui.item.label);
          $("#course_autocomplete_id").val(ui.item.id);
          $("#copy_from_course").val("none");
        }
      });
    }
  });
});
