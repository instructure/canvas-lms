define([
  'compiled/util/round',
  'i18n!grading_standards',
  'jsx/shared/helpers/numberHelper',
  'jquery' /* $ */,
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_forms' /* fillFormData, getFormData */,
  'jqueryui/dialog',
  'jquery.instructure_misc_plugins' /* ifExists, .dim, undim, confirmDelete */,
  'compiled/jquery.rails_flash_notifications',
  'jquery.templateData' /* fillTemplateData, getTemplateData */,
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */
], function (round, I18n, numberHelper, $) {
  function roundedNumber (val) {
    return I18n.n(round(val, round.DEFAULT));
  }

  $(document).ready(function() {
    $(".add_standard_link").click(function(event) {
      event.preventDefault();
      var $standard = $("#grading_standard_blank").clone(true).attr('id', 'grading_standard_new');
      $("#standards").append($standard.show());
      $standard.find(".edit_grading_standard_link").click();
    });
    $(".edit_letter_grades_link").click(function(event) {
      event.preventDefault();
      $("#edit_letter_grades_form").dialog({
        title: I18n.t('titles.grading_scheme_info', "View/Edit Grading Scheme"),
        width: 600,
        dialogClass: 'form-inline grading-standard-dialog',
        resizable: false,
        open: function () { $('.grading-standard-dialog').find('.ui-dialog-titlebar-close')[0].focus() },
        close: function() { $(event.target).focus() }
      });
    });
    $(".grading_standard .delete_grading_standard_link").click(function(event) {
      event.preventDefault();
      var $standard = $(this).parents(".grading_standard");
      var url = $standard.find(".update_grading_standard_url").attr('href');
      $standard.confirmDelete({
        url: url,
        message: I18n.t('confirm.delete_grading_scheme', "Are you sure you want to delete this grading scheme?"),
        success: function(data) {
          $(this).slideUp(function() {
            $(this).remove();
          });
        },
        error: function() {
          $.flashError(I18n.t('errors.cannot_delete_grading_scheme', "There was a problem deleting this grading scheme"));
        }
      });
    });
    $(".grading_standard .done_button").click(function(event) {
      event.preventDefault();
      $("#edit_letter_grades_form").dialog('close');
    });
    $(".grading_standard .remove_grading_standard_link").click(function(event) {
      event.preventDefault();
      var result = confirm(I18n.t('confirm.unlink_grading_scheme', "Are you sure you want to unlink this grading scheme?"));
      if(!result) { return false; }
      var $standard = $(this).parents(".grading_standard");
      $standard.dim();
      var put_data = {
        'assignment[grading_standard_id]': '',
        'assignment[grading_type]': 'points'
      };
      var url = $("#edit_assignment_form").attr('action');
      if($("#update_course_url").length) {
        put_data = {
          'course[grading_standard_id]': ''
        }
        url = $("#update_course_url").attr('href');
      } else if(url && url.match(/assignments$/)) {
        url = null;
      }
      function removed() {
        $("#edit_assignment_form .grading_standard_id").val("");
        $("#assignment_grading_type").val("points").change();
        $("#course_grading_standard_enabled").attr('checked', false).change();
        $("#course_form .grading_scheme_set").text(I18n.t('grading_scheme_not_set', "Not Set"));
        $standard.addClass('editing');
        $standard.find(".update_grading_standard_url").attr('href', $("#update_grading_standard_url").attr('href'));
        var data = $.parseJSON($("#default_grading_standard_data").val());
        var standard = {title: "", id: null, data: data};
        $standard.fillTemplateData({
          data: standard,
          id: 'grading_standard_blank',
          avoid: '.find_grading_standard',
          hrefValues: ['id']
        }).find(".edit_grading_standard_link").removeClass('read_only');
        $standard.triggerHandler('grading_standard_updated', standard);
        $("#edit_letter_grades_form").dialog('close');
        $standard.undim();
      }
      if(url) {
        $.ajaxJSON(url, 'PUT', put_data, removed, function() {
          $.flashError(I18n.t('errors.cannot_remove_grading_scheme', "There was a problem removing this grading scheme.  Please reload the page and try again."));
        });
      } else {
        removed();
      }
    });
    $(".grading_standard .edit_grading_standard_link").click(function(event) {
      event.preventDefault();
      var $standard = $(this).parents(".grading_standard");
      $standard.addClass('editing');
      $standard.find(".max_score_cell").attr('tabindex', '0');
      if($(this).hasClass('read_only')) {
        $standard.attr('id', 'grading_standard_blank');
      }
      $standard.find(".grading_standard_row").each(function() {
        var data = $(this).getTemplateData({textValues: ['min_score', 'name']});
        $(this).find(".standard_value").val(data.min_score).end()
          .find(".standard_name").val(data.name);
      });
      $("#standards").ifExists(function() {
        $("html,body").scrollTo($standard);
      });
      $standard.find(":text:first").blur().focus().select();
    });
    $(".grading_standard .grading_standard_brief").find(".collapse_data_link,.expand_data_link").click(function(event) {
      event.preventDefault();
      var $brief = $(this).parents(".grading_standard_brief");
      $brief.find(".collapse_data_link,.expand_data_link").toggle();
      $brief.find(".details").slideToggle();
    });
    $(".grading_standard_select").live('click', function(event) {
      event.preventDefault();
      var id = $(this).getTemplateData({textValues: ['id']}).id;
      $(".grading_standard .grading_standards_select .grading_standard_select").removeClass('selected_side_tab');
      $(this).addClass('selected_side_tab');
      $(".grading_standard .grading_standards .grading_standard_brief").hide();
      $("#grading_standard_brief_" + id).show();
    });
    $(".grading_standard").find(".find_grading_standard_link,.cancel_find_grading_standard_link").click(function(event) {
      event.preventDefault();
      $(this).parents(".grading_standard").find(".display_grading_standard,.find_grading_standard").toggle();
      var $find = $(this).parents(".grading_standard").find(".find_grading_standard:visible");
      if($find.length > 0 && !$find.hasClass('loaded')) {
        $find.find(".loading_message").text(I18n.t('status.loading_grading_standards', "Loading Grading Standards..."));
        var url = $find.find(".grading_standards_url").attr('href');
        $.ajaxJSON(url, 'GET', {}, function(data) {
          if(data.length === 0) {
            $find.find(".loading_message").text(I18n.t('no_grading_standards', "No grading schemes found"));
          } else {
            $find.find(".loading_message").remove();
            for(var idx in data) {
              var standard = data[idx].grading_standard;
              standard.user_name = standard.display_name;
              var $standard_select = $find.find(".grading_standards_select .grading_standard_select.blank:first").clone(true);
              $standard_select.fillTemplateData({
                data: standard
              }).data('context_code', standard.context_code).removeClass('blank');
              $find.find(".grading_standards_select").append($standard_select.show());
              var $standard = $find.find(".grading_standard_brief.blank:first").clone(true);
              $standard.fillTemplateData({
                data: standard,
                id: 'grading_standard_brief_' + standard.id
              }).data('context_code', standard.context_code);
              $standard.removeClass('blank');
              for(var jdx = 0; jdx < standard.data.length; jdx++) {
                var row = {
                  name: standard.data[jdx][0],
                  value: jdx === 0 ? roundedNumber(100) : '< ' + roundedNumber(standard.data[jdx - 1][1] * 100),
                  next_value: roundedNumber(standard.data[jdx][1] * 100)
                };
                var $row = $standard.find(".details_row.blank:first").clone(true);
                $row.removeClass('blank');
                $row.fillTemplateData({data: row});
                $standard.find(".details > table").append($row.show());
              }
              $find.find(".grading_standards").append($standard);
            }
            $find.find(".grading_standards_select .grading_standard_select:visible:first a:first").click();
          }
          $find.addClass('loaded');
          $find.find(".grading_standards_holder").slideDown();
        }, function(data) {
          $find.find(".loading_message").text(I18n.t('errors.cannot_load_grading_standards', "Loading Grading Standards Failed.  Please Try Again"));
        });
      }
    });
    $(".grading_standard .grading_standard_brief .select_grading_standard_link").click(function(event) {
      event.preventDefault();
      var $brief = $(this).parents(".grading_standard_brief");
      var brief = $brief.getTemplateData({textValues: ['id', 'title'], dataValues: ['context_code']});
      var id = brief.id;
      var title = brief.title;
      var data = [];
      $(this).parents(".grading_standard_brief").find(".details_row:not(.blank)").each(function() {
        var name = $(this).find(".name").text();
        var val = numberHelper.parse($(this).find('.next_value').text()) / 100.0;
        if(isNaN(val)) { val = ""; }
        data.push([name, val]);
      });
      $(this).parents(".grading_standard").triggerHandler('grading_standard_updated', {
        id: id,
        data: data,
        title: title
      });
      var current_context_code = $("#edit_letter_grades_form").data().context_code;
      $(this).parents(".grading_standard").find(".edit_grading_standard_link").toggleClass('read_only', current_context_code != brief.context_code);
      $(this).parents(".find_grading_standard").find(".cancel_find_grading_standard_link").click();
    });
    $(".grading_standard .cancel_button").click(function(event) {
      $(this).parents(".grading_standard").removeClass('editing')
        .find(".insert_grading_standard").hide();
      var $standard = $(this).parents(".grading_standard");
      $standard.find(".max_score_cell").removeAttr('tabindex');
      $standard.find(".to_add").remove();
      $standard.find(".to_delete").removeClass('to_delete').show();
      if($standard.attr('id') == 'grading_standard_new') {
        $standard.remove();
      }
    });
    $(".grading_standard").bind('grading_standard_updated', function(event, standard) {
      var $standard = $(this);
      $standard.addClass('editing');
      $standard.find(".update_grading_standard_url").attr('href', $("#update_grading_standard_url").attr('href'));
      $standard.fillTemplateData({
        data: standard,
        id: 'grading_standard_' + (standard.id || 'blank'),
        avoid: '.find_grading_standard',
        hrefValues: ['id']
      }).fillFormData(standard, {object_name: 'grading_standard'});
      var $link = $standard.find(".insert_grading_standard:first").clone(true);
      var $row = $standard.find(".grading_standard_row:first").clone(true).removeClass('blank');
      var $table = $standard.find(".grading_standard_data");
      var $thead = $table.find('thead');
      $table.empty();
      $table.append($thead);
      $table.append($link.clone(true).show());
      for(var idx in standard.data) {
        var $row_instance = $row.clone(true);
        var row = standard.data[idx];
        $row_instance.removeClass('to_delete').removeClass('to_add');
        $row_instance.find(".standard_name").val(row[0]).attr('name', 'grading_standard[standard_data][scheme_'+idx+'][name]').end()
          .find('.standard_value')
            .val(I18n.n(round((row[1] * 100), 2)))
            .attr('name', 'grading_standard[standard_data][scheme_' + idx + '][value]');
        $table.append($row_instance.show());
        $table.append($link.clone(true).show());
      }
      $table.find(":text:first").blur();
      $table.append($row.hide());
      $table.append($link.hide());
      $standard.find(".grading_standard_row").each(function() {
        $(this).find(".name").text($(this).find(".standard_name").val()).end()
          .find(".min_score").text($(this).find(".standard_value").val()).end()
          .find(".max_score").text($(this).find(".edit_max_score").text());
      });
      $standard.removeClass('editing');
      $standard.find(".insert_grading_standard").hide();
      if(standard.id) {
        $standard.find(".remove_grading_standard_link").removeClass('read_only');
        var put_data = {
          'assignment[grading_standard_id]': standard.id,
          'assignment[grading_type]': 'letter_grade'
        };
        var url = $("#edit_assignment_form").attr('action');
        $("input.grading_standard_id, ").val(standard.id);
        if($("#update_course_url").length) {
          put_data = {
            'course[grading_standard_id]': standard.id
          }
          url = $("#update_course_url").attr('href');
        } else if(url && url.match(/assignments$/)) {
          url = null;
        }
        if(url) {
          $.ajaxJSON(url, 'PUT', put_data, function(data) {
            $("#course_form .grading_scheme_set").text((data && data.course && data.course.grading_standard_title) || I18n.t('grading_scheme_currently_set', "Currently Set"));
          }, function() {});
        }
      } else {
        $standard.find(".remove_grading_standard_link").addClass('read_only');
      }
    });
    $(".grading_standard .save_button").click(function(event) {
      var $standard = $(this).parents(".grading_standard");
      var url = $("#edit_letter_grades_form .create_grading_standard_url,#create_grading_standard_url").attr('href');
      var method = 'POST';
      if($standard.attr('id') != 'grading_standard_blank' && $standard.attr('id') != 'grading_standard_new') {
        url = $(this).parents(".grading_standard").find(".update_grading_standard_url").attr('href');
        method = 'PUT';
      }
      var data = $standard.find(".standard_title,.grading_standard_row:visible").getFormData();
      Object.keys(data).forEach(function (key) {
        var parsedValue;
        if (/^grading_standard\[.*\]\[value\]$/.test(key)) {
          parsedValue = numberHelper.parse(data[key]);
          if (!isNaN(parsedValue)) {
            data[key] = parsedValue;
          }
        }
      });
      $standard.find("button").attr('disabled', true).filter(".save_button").text(I18n.t('status.saving', "Saving..."));
      $.ajaxJSON(url, method, data, function(data) {
        var standard = data.grading_standard;
        $standard.find("button").attr('disabled', false).filter(".save_button").text(I18n.t('buttons.save', "Save"));
        $standard.triggerHandler('grading_standard_updated', standard);
      }, function() {
        $standard.find("button").attr('disabled', false).filter(".save_button").text(I18n.t('errors.save_failed', "Save Failed"));
      });
    });
    $(".grading_standard thead").mouseover(function(event) {
      if(!$(this).parents(".grading_standard").hasClass('editing')) { return; }
      $(this).parents(".grading_standard").find(".insert_grading_standard").hide();
      $(this).parents(".grading_standard").find(".insert_grading_standard:first").show();
    });
    $(".grading_standard .grading_standard_row").mouseover(function(event) {
      if(!$(this).parents(".grading_standard").hasClass('editing')) { return; }
      $(this).parents(".grading_standard").find(".insert_grading_standard").hide();
      var y = event.pageY;
      var offset = $(this).offset();
      var height = $(this).height();
      if(y > offset.top + (height / 2)) {
        $(this).next(".insert_grading_standard").show();
      } else {
        $(this).prev(".insert_grading_standard").show();
      }
    });
    $(".grading_standard *").focus(function(event) {
      $(this).trigger('mouseover');
      if ($(this).hasClass('delete_row_link')) {
        $(this).parents(".grading_standard_row").nextAll('.grading_standard_row').first().trigger('mouseover');
      }
    });
    $(".grading_standard .insert_grading_standard_link").click(function(event) {
      event.preventDefault();
      if($(this).parents(".grading_standard").find(".grading_standard_row").length > 40) { return; }
      var $standard = $(this).parents(".grading_standard");
      var $row = $standard.find(".grading_standard_row:first").clone(true).removeClass('blank');
      var $link = $standard.find(".insert_grading_standard:first").clone(true);
      var temp_id = null;
      while(!temp_id || $(".standard_name[name='grading_standard[standard_data][scheme_" + temp_id + "][name]']").length > 0) {
        temp_id = Math.round(Math.random() * 10000);
      }
      $row.find(".standard_name").val("-").attr('name', 'grading_standard[standard_data][scheme_' + temp_id + '][name]');
      $row.find(".standard_value").attr('name', 'grading_standard[standard_data][scheme_' + temp_id + '][value]');
      $(this).parents(".insert_grading_standard").after($row.show());
      $row.after($link);
      $standard.find(":text:first").blur();
      $row.find(":text:first").focus().select();
      $row.addClass('to_add');
    });
    $(".grading_standard .delete_row_link").click(function(event) {
      event.preventDefault();
      if($(this).parents(".grading_standard").find(".grading_standard_row:visible").length < 2) { return; }
      var $standard = $(this).parents(".grading_standard_row");
      if($standard.prev(".insert_grading_standard").length > 0) {
        $standard.prev(".insert_grading_standard").remove();
      } else {
        $standard.next(".insert_grading_standard").remove();
      }
      $standard.fadeOut(function() {
        $(this).addClass('to_delete');
        // force refresh in case the deletion requires other changes
        $(".grading_standard input[type='text']:first").triggerHandler('change');
      });
    });
    $(".grading_standard input[type='text']").bind('blur change', function() {
      var $standard = $(this).parents(".grading_standard");
      var val = numberHelper.parse($(this).parents('.grading_standard_row').find('.standard_value').val());
      val = round(val,2);
      $(this).parents('.grading_standard_row').find('.standard_value').val(I18n.n(val));
      if(isNaN(val)) { val = null; }
      var lastVal = val || 100;
      var prevVal = val || 0;
      var $list = $standard.find(".grading_standard_row:not(.blank,.to_delete)");
      for(var idx = $list.index($(this).parents(".grading_standard_row")) + 1; idx < $list.length; idx++) {
        var $row = $list.eq(idx);
        var points = numberHelper.parse($row.find('.standard_value').val());
        if(isNaN(points)) { points = null; }
        if(idx == $list.length - 1) {
          points = 0;
        } else if (!points || points > lastVal - 0.1) {
          points = parseInt(lastVal) - 1;
        }
        $row.find('.standard_value').val(I18n.n(points));
        lastVal = points;
      }
      for(var idx = $list.index($(this).parents(".grading_standard_row")) - 1; idx  >= 0; idx--) {
        var $row = $list.eq(idx);
        var points = numberHelper.parse($row.find('.standard_value').val());
        if(isNaN(points)) { points = null; }
        if(idx == $list.length - 1) {
          points = 0;
        }
        else if(!points || points < prevVal + 0.1) {
          points = parseInt(prevVal) + 1;
        }
        prevVal = points;
        $row.find('.standard_value').val(I18n.n(points));
      }
      lastVal = 100;
      $list.each(function(idx) {
        var points = numberHelper.parse($(this).find('.standard_value').val());
        var idx = $list.index(this);
        if(isNaN(points)) { points = null; }
        if(idx == $list.length - 1) {
          points = 0;
        }
        else if(!points || points > lastVal - 0.1) {
          points = parseInt(lastVal) - 1;
        }
        $(this).find('.standard_value').val(I18n.n(points));
        lastVal = points;
      });
      prevVal = 0;
      for(var idx = $list.length - 1; idx  >= 0; idx--) {
        var $row = $list.eq(idx);
        var points = numberHelper.parse($row.find('.standard_value').val());
        if(isNaN(points)) { points = null; }
        if(idx == $list.length - 1) {
          points = 0;
        }
        else if((!points || points < prevVal + 0.1)&& points != 0) {
          points = parseInt(prevVal) + 1;
        }
        prevVal = points;
        $row.find('.standard_value').val(I18n.n(points));
      }
      $list.each(function(idx) {
        var $prev = $list.eq(idx - 1);
        var min_score = 0;
        if($prev && $prev.length > 0) {
          min_score = numberHelper.parse($prev.find('.standard_value').val());
          if(isNaN(min_score)) { min_score = 0; }
          $(this).find('.edit_max_score').text('< ' + I18n.n(min_score));
        }
      });
      $list.filter(':first').find('.edit_max_score').text(I18n.n(100));
      $list.find('.max_score_cell').each(function() {
        if (!$(this).data('label')) {
          $(this).data('label', $(this).attr('aria-label'));
        }
        var label = $(this).data('label');
        $(this).attr('aria-label', label + ' ' + $(this).find('.edit_max_score').text() + '%');
      });
    });
  });
});
