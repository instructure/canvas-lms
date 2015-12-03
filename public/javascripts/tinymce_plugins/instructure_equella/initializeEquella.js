define([
  'jquery',
  'jqueryui/dialog'
], function($) {

  return function(ed) {
    var $box = $("#equella_dialog");
    var url = $("#equella_endpoint_url").attr('href');
    var action = $.trim($("#equella_action").text() || "") || "selectOrAdd";
    var callback_url = $("#equella_callback_url").attr('href');
    var cancel_url = $("#equella_cancel_url").attr('href');
    if(!url || !callback_url || !cancel_url) {
      alert("Equella is not properly configured for this account, please notify your system administrator.");
      return;
    }
    var frameHeight = Math.max(Math.min($(window).height() - 100, 550), 100);
    if(!$box.length) {
      var boxHtml = '<div id="equella_dialog" style="padding: 0; overflow-y: hidden;"/>'
      var teaserAndIframeHtml = $.raw("<div class='teaser' style='width: 800px; margin-bottom: 10px; display: none;'></div>") +
        $.raw("<iframe style='background: url(/images/ajax-loader-medium-444.gif) no-repeat left top; width: 800px; height: ") +
        $.raw(frameHeight) +
        $.raw("px; border: 0;' src='about:blank' borderstyle='0'/>")
      $box = $(boxHtml)
        .hide()
        .html(teaserAndIframeHtml)
        .appendTo('body')
        .dialog({
          autoOpen: false,
          width: 'auto',
          resizable: true,
          resizeStart: function(){
            $(this).find('iframe').each(function(){
              $('<div class="fix_for_resizing_over_iframe" style="background: #fff;"></div>')
                .css({
                  width: this.offsetWidth+"px", height: this.offsetHeight+"px",
                  position: "absolute", opacity: "0.001", zIndex: 10000000
                })
                .css($(this).offset())
                .appendTo("body");
            });
          },
          resizeStop: function(){
            $(".fix_for_resizing_over_iframe").remove();
          },
          resize: function(){
            $(this).find('iframe').add('.fix_for_resizing_over_iframe').height($(this).height()).width($(this).width());
          },
          close: function() {
            $box.find("iframe").attr('src', 'about:blank');
          },
          title: "Embed content from Equella"
        })
        .bind('equella_ready', function(event, data) {
          var clickedEditor = $box.data('editor') || ed;
          var selectedContent = ed.selection.getContent();
          if(selectedContent) { // selected content
            ed.execCommand('mceInsertLink', false, {title: data.name, href: data.url, 'class': 'equella_content_link'});
          } else { // no selected content
            var $link = $("<div><a/></div>");
            $link.find("a")
              .attr('title', data.name)
              .attr('href', data.url)
              .attr('class', 'equella_content_link')
              .text(data.name)
            ed.execCommand('mceInsertContent', false, $link.html());
          }
          $("#equella_dialog").dialog('close');
        });
    }
    var teaserHtml = $("#equella_teaser").html();
    $box.find(".teaser").hide();
    if(teaserHtml) {
      $box.find(".teaser").html(teaserHtml).show();
    }
    var full_url = url;
    full_url = full_url + "?method=lms&returnprefix=eq_&action=" + action;
    full_url = full_url + "&returnurl=" + encodeURIComponent(callback_url);
    full_url = full_url + "&cancelurl=" + encodeURIComponent(cancel_url);
    $box.data('editor', ed);
    $box.dialog('close').dialog('open');
    $box.find("iframe").attr('src', full_url);
  }
})