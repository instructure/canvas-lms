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

require([
  'INST' /* INST */,
  'i18n!learning_outcome',
  'jquery' /* $ */,
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_date_and_time' /* parseFromISO */,
  'jquery.instructure_jquery_patches' /* /\.dialog/ */,
  'jquery.instructure_misc_helpers' /* /\$\.underscore/, /\$\.titleize/ */,
  'jquery.instructure_misc_plugins' /* confirmDelete */,
  'jquery.loadingImg' /* loadingImage */,
  'jquery.templateData' /* fillTemplateData, getTemplateData */,
  'vendor/jquery.pageless' /* pageless */,
  'jqueryui/sortable' /* /\.sortable/ */
], function(INST, I18n, $) {

  $(document).ready(function() {
    $('#outcome_results').pageless({
      totalPages: parseInt($("#outcome_results_total_pages").text(), 10) || 1,
      url: $(".outcome_results_url").attr('href'),
      loaderMsg: I18n.t("loading_more_results", "Loading more results"),
      scrape: function(data) {
        if(typeof(data) == 'string') {
          try {
            data = $.parseJSON(data) || [];
          } catch(e) {
            data = [];
          }
        }
        for(var idx in data) {
          var result = data[idx].learning_outcome_result;
          var $result = $("#result_blank").clone(true).attr('id', 'result_' + result.id);
          result.assessed_at_formatted = $.parseFromISO(result.assessed_at).datetime_formatted;
          $result.toggleClass('mastery_result', !!result.mastery);
          $result.fillTemplateData({data: result, except: ['mastery'], hrefValues: ['id', 'user_id']});
          $("#outcome_results_list").append($result);
          $result.show();
        }
        return "";
      }
    });
    $(".delete_alignment_link").click(function(event) {
      event.preventDefault();
      $(this).parents(".alignment").confirmDelete({
        url: $(this).attr('href'),
        message: I18n.t("remove_outcome_alignment", "Are you sure you want to remove this alignment?"),
        success: function(data) {
          $(this).slideUp(function() {
            $(this).remove();
          });
        }
      });
    });
    $("#alignments.orderable").sortable({
      axis: 'y',
      handle: '.move_alignment_link',
      update: function(event, ui) {
        var ids = [];
        $("#alignments .alignment").each(function() {
          ids.push($(this).getTemplateData({textValues: ['id']}).id);
        });
        var url = $("#outcome_urls .reorder_alignments_url:last").attr('href');
        $.ajaxJSON(url, 'POST', {order: ids.join(",")}, function(data) {
        }, function() { });
      }
    });
    var addAlignment = function(data) {
      data.title = data['item[title]'] || data.title;
      var $alignment = $("#alginment_" + data.id);
      if($alignment.length === 0) {
        $alignment = $("#alignment_blank").clone(true).removeAttr('id');
      }
      $alignment.addClass($.underscore(data.content_type));
      var desc = $.titleize(data.content_type) || "Alignment";
      $alignment.find(".type_icon").attr('alt', desc).attr('title', desc);
      $alignment.attr('id', 'alignment_' + (data.id || "new"));
      var hrefValues = ['user_id'];
      if(data.id) { hrefValues = ['user_id', 'id']; }
      $alignment.fillTemplateData({
        data: data,
        hrefValues: hrefValues
      });
      $("#alignments").append($alignment.show());
      return $alignment;
    };
    $(".add_outcome_alignment_link").live('click', function(event) {
      event.preventDefault();
      if(INST && INST.selectContentDialog) {
        var options = {for_modules: false};
        options.select_button_text = I18n.t("align_item", "Align Item");
        options.holder_name = I18n.t("this_outcome", "this Outcome");
        options.dialog_title = I18n.t("align_to_outcome", "Align Item to this Outcome");
        options.submit = function(item_data) {
          var $item = addAlignment(item_data);
          var url = $("#outcome_urls .align_url").attr('href');
          item_data['asset_string'] = item_data['item[type]'] + "_" + item_data['item[id]'];
          $item.loadingImage({image_size: 'small'});
          $.ajaxJSON(url, 'POST', item_data, function(data) {
            $item.loadingImage('remove');
            $item.remove();
            addAlignment(data.content_tag);
            $("#alignments.orderable").sortable('refresh');
          });
        };
        INST.selectContentDialog(options);
      }
    });
    $("#artifacts li").live('mouseover', function() {
      $(".hover_alignment,.hover_artifact").removeClass('hover_alignment').removeClass('hover_artifact');
      $(this).addClass('hover_artifact');
    });
    $("#alignments li").live('mouseover', function() {
      $(".hover_alignment,.hover_artifact").removeClass('hover_alignment').removeClass('hover_artifact');
      $(this).addClass('hover_alignment');
    });
  });
});
