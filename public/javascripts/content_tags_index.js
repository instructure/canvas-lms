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
  'i18n!content_tags',
  'jquery' /* $ */,
  'jquery.instructure_forms' /* formSubmit, fillFormData */,
  'jqueryui/dialog',
  'jquery.instructure_misc_helpers' /* replaceTags */,
  'jquery.instructure_misc_plugins' /* confirmDelete, fragmentChange */,
  'jquery.loadingImg' /* loadingImage */,
  'jquery.templateData' /* getTemplateData */,
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */,
  'jqueryui/accordion' /* /\.accordion\(/ */
], function(I18n, $) {

  var contentTags = {
    currentHover: null,
    hoverCount: -1,
    checkForHover: function() {
      if(contentTags.hoverCount >= 0) {
        if(contentTags.currentHover == null) {
          contentTags.hoverCount = -1;
          return;
        }
        contentTags.hoverCount++;
        if(contentTags.hoverCount > 4) {
          contentTags.currentHover.click();
        }
      }
    }
  };
  $(document).ready(function() {
    $("#tags .tag_name").click(function(event) {
      $("#tags .tag_name.selected").removeClass('selected');
      $(this).parents(".tag_list").scrollTo($(this));
      $(this).addClass('selected');
      event.preventDefault();
      var name = $(this).getTemplateData({textValues: ['name']}).name.toLowerCase().replace(/\s/g, "_");
      $("#pages_for_tags").find(".page").hide();
      var $tags = $("#pages_for_tags").find(".page.tag_named_" + name);
      var group_id = $(this).parents(".context_tags").attr('id');
      if(group_id != "tags_for_all") {
        $tags = $tags.filter("." + group_id.replace(/^tags_for/, "page_for"));
      }
      var found_urls = {};
      $tags.each(function() {
        found_urls[$(this).find(".title").attr('href') + "::" + $(this).find(".title").text()] = true;
        $(this).show();
      });
    });
    $("#tags").accordion({
      header: ".header",
      fillSpace: true,
      alwaysOpen: true
    }).bind('accordionchange', function(event, ui) {
      $("#pages_for_tags .page").hide();
      $(ui.newContent).filter(":first").click();
    });
    $("#tags_for_all .tag_list .tag_name:first").click();
    $(".content_tags_description_link").click(function(event) {
      event.preventDefault();
      $("#content_tags_details_dialog").dialog({
        title: "What Are Content Tags?"
      });
    });
    $(".page").click(function(event) {
      if($(this).hasClass('selected')) { return; }
      if($(event.target).closest("a").length > 0) { return; }
      event.preventDefault();
      $("#pages_for_tags .page.selected").removeClass('selected')
        .find(".comments").slideUp();
      $(this).addClass('selected')
        .find(".comments").slideDown();
    });
    $(".page").hover(function() {
      contentTags.currentHover = $(this);
      contentTags.hoverCount = 0;
    }, function() {
      if(contentTags.currentHover && contentTags.currentHover[0] == $(this)[0]) {
        contentTags.currentHover = null;
        contentTags.hoverCount = -1;
      }
    });
    setInterval(contentTags.checkForHover, 200);
    $(".page .delete_page_link").click(function(event) {
      event.preventDefault();
      $(this).parents(".page").confirmDelete({
        message: I18n.t('prompts.delete_tag', "Are you sure you want to delete this tag?"),
        url: $(this).attr('href'),
        success: function() {
          $(this).slideUp(function() {
            $(this).remove();
          });
        }
      });
    });
    $(".add_external_tag_link").click(function(event) {
      event.preventDefault();
      $("#external_tag_dialog").dialog({
        title: I18n.t('titles.tag_external_web_page', "Tag External Web Page"),
        width: 400,
        open: function() {
          var data = {
            url: "http://",
            title: I18n.t('defaults.page_title', "Page Title"),
            comments: I18n.t('defaults.comments', "Comments")
          };
          $(this).fillFormData(data, {object_name: 'tag'});
          $(this).find(":text:visible:first").focus().select();
        }
      }).dialog('open');
    });
    $("#add_external_tag_form").formSubmit({
      beforeSubmit: function(data) {
        $(this).loadingImage();
      },
      success: function(data) {
        $(this).loadingImage('remove');
        $("#external_tag_dialog").dialog('close');
        for(var idx in data) {
          var tag = data[idx];
          $(document).triggerHandler('tag_added', tag);
        }
      }
    });
    $(document).bind('tag_added', function(event, tag) {
      var $context = $("#tags_for_" + tag.context_type.toLowerCase() + "_" + tag.context_id);
      var $match_context = addTagToContext($context, tag);
      var $match_all = addTagToContext($("#tags_for_all"), tag);
      var $page = $("#page_blank").clone(true).removeAttr('id');
      $page.find(".title").attr('href', tag.url).text(tag.title);
      $page.find(".comments").text(tag.comments);
      $page.find(".delete_page_link").attr('href', $.replaceTags($page.find(".delete_page_link").attr('href'), 'id', tag.id));
      $page.addClass('page_for_' + tag.context_type.toLowerCase() + "_" + tag.context_id)
        .addClass('tag_named_' + tag.tag.toLowerCase().replace(/ /g, "_"));
      $("#pages_for_tags").prepend($page);
      $("#content_tags_description").hide();
      $("#content_tags_table").show();
      $("#personal_tags_message").hide();
      $match_context.filter(":visible").click();
      $match_all.filter(":visible").click();
      $(window).triggerHandler('resize');
    });
    $(document).fragmentChange(function(event, hash) {
      hash = hash || "";
      var tag = hash.substring(1);
      $(".ui-accordion-content-active").find(".tag_name." + tag).click();
    });
    $(window).resize(function() {
      var windowHeight = $(window).height();
      var tableTop = $("#tags").offset().top;
      var tableHeight = Math.max(windowHeight - tableTop, 200) - 10;
      $("#tags,#pages_for_tags").height(tableHeight);
      if($.browser.msie && navigator.appVersion.match('MSIE 6.0')) { return; }
      $("#tags").accordion('resize');
    }).triggerHandler('resize');
  });
  function addTagToContext($context, tag) {
    var $match = null;
    $context.find(".tag_list .tag_name").each(function() {
      var name = $(this).find(".name").text();
      if(name == tag.tag) {
        $match = $(this);
      } else if(tag.tag > name) {
        $match = $("#tag_name_blank").clone(true).removeAttr('id');
        $match.find(".name").text(tag.tag);
        $(this).before($match);
      }
      if($match) { return false; }
    });
    if($match == null) {
      var $match = $("#tag_name_blank").clone(true).removeAttr('id');
      $match.find(".name").text(tag.tag);
      $context.find(".tag_list").append($match);
    }
    return $match;
  }
});
