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

// tinymce doesn't like its plugins being async,
// all dependencies must export to window

define([
  'compiled/editor/stocktiny',
  'i18n!editor',
  'jquery',
  'str/htmlEscape',
  'jquery.instructure_jquery_patches',
  'jquery.instructure_misc_helpers'
], function(tinymce, I18n, $, htmlEscape) {

  var $box, $editor, $userURL, $altText, $actions, $flickrLink;

  var initted = false;

  var TRANSLATIONS = {
    click_to_embed: I18n.t('click_to_embed', 'Click to embed the image'),
    instructions: INST.htmlEscape(I18n.t('instructions', "Paste or type the URL of the image you'd like to embed:")),
    url: INST.htmlEscape(I18n.t('url', 'URL:')),
    alt_text: INST.htmlEscape(I18n.t('alt_text', 'Alternate Text:')),
    search_flickr: I18n.t('search_flickr', 'Search flickr creative commons'),
    loading: I18n.t('loading', 'Loading...'),
    embed_external: I18n.t('embed_external', 'Embed External Image'),
    embed_image: INST.htmlEscape(I18n.t('embed_image', 'Embed Image')),
    image_not_found: I18n.t('image_not_found', 'Image not found, please try a new URL')
  };

  function initShared () {
    $box = $('<div/>', {html: TRANSLATIONS.instructions + "<form id='instructure_embed_prompt_form' style='margin-top: 5px;'><table class='formtable'><tr><td>"+ TRANSLATIONS.url +"</td><td><input type='text' class='prompt' style='width: 250px;' value='http://'/></td></tr><tr><td class='nobr'>"+TRANSLATIONS.alt_text+"</td><td><input type='text' class='alt_text' style='width: 150px;' value=''/></td></tr><tr><td colspan='2' style='text-align: right;'><input type='submit' value='Embed Image'/></td></tr></table></form><div class='actions'></div>"}).hide();
    $altText = $box.find('.alt_text');
    $actions = $box.find('.actions');
    $userURL = $box.find('.prompt');
    $flickrLink = $('<a/>', {
      'class': 'flickr_search_link',
      text: TRANSLATIONS.search_flickr,
      href: '#'
    });

    $userURL.bind('keyup', validateURL);
    $actions.delegate('.embed_image_link', 'click', embedURLImage);
    $flickrLink.click(flickrLinkClickHandler);
    $box.append($flickrLink).find('#instructure_embed_prompt_form').submit(embedURLImage);
    $('body').append($box);
    $box.dialog({
      autoOpen: false,
      width: 425,
      title: TRANSLATIONS.embed_external,
      open: function () {
        $userURL.select();
      }
    });
    initted = true;
  }

  function flickrLinkClickHandler (event) {
    event.preventDefault();
    $box.dialog('close');
    $.findImageForService('flickr_creative_commons', function (data) {
      var title = INST.htmlEscape(data.title),
          html = '<a href="' + data.link_url + '"><img src="' + data.image_url + '" title="' + title + '"alt="' + title + '" style="max-width: 500; max-height: 500"></a>';
      $box.dialog('close');
      $editor.editorBox('insert_code', html);
    });
  }

  function embedURLImage (event) {
    var alt = INST.htmlEscape($altText.val() || ''),
        text = INST.htmlEscape($userURL.val());

    event.preventDefault();
    $editor.editorBox('insert_code', "<img src='" + text + "' alt='" + alt + "'/>");
    $box.dialog('close');
  }

  function validateURL (event) {
    var val = $userURL.val();
    return (val.match(/\.(gif|png|jpg|jpeg)$/)) ? getImage(val) : invalidURL();
  }

  function invalidURL () {
    $actions.empty();
  }

  function getImage (val) {
    var $div = $('<div/>'),
        $img = $('<img/>');

    $div.css('textAlign', 'center').text(TRANSLATIONS.loading);
    $actions.empty();
    $actions.append($div);
    $img.attr({
      src: val,
      title: TRANSLATIONS.click_to_embed
    })
    .addClass('embed_image_link')
    .css('cursor', 'pointer')
    .bind({
      load: function () {
        var img = $img[0];
        $img.height(img.height < 200 ? img.height : 100);
        $div.empty().append($img);
      },
      error: function () {
        $div.text(TRANSLATIONS.image_not_found);
      }
    });
  }

  tinymce.create('tinymce.plugins.InstructureEmbed', {
    init: function (editor, url) {
      var thisEditor = $('#' + editor.id);

      editor.addCommand('instructureEmbed', function (search) {
        if (!initted) initShared();
        $editor = thisEditor; // set shared $editor so images are pasted into the correct editor
        $box.dialog('open');

        if (search === 'flickr') $flickrLink.click();
      });

      editor.addButton('instructure_embed', {
        title: TRANSLATIONS.embed_image,
        cmd: 'instructureEmbed',
        image: url + '/img/button.gif'
      });
    },

    getInfo: function () {
      return {
        longname: 'InstructureEmbed',
        author: 'Brian Whitmer',
        authorurl: 'http://www.instructure.com',
        infourl: 'http://www.instructure.com',
        version: tinymce.majorVersion + '.' + tinymce.minorVersion
      };
    }
  });

  tinymce.PluginManager.add('instructure_embed', tinymce.plugins.InstructureEmbed);
});

