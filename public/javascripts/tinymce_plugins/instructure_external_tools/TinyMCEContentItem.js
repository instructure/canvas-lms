/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
  var LTI_MIME_TYPES = [ 'application/vnd.ims.lti.v1.ltilink', 'application/vnd.ims.lti.v1.launch+json'];

  function exportPropsToSelf(properties, keyMethod) {
    keyMethod = keyMethod || Object.keys;

    function _propMethod(prop) {
      return {
          configurable: true,
          get: function (){
            return properties[prop]
          }
        }
    }

    var keys = keyMethod(properties),
      keyLength = keys.length,
      prop;

    while(keyLength--) {
      prop = keys[keyLength];
      Object.defineProperty(this, prop, _propMethod(prop));
    }
  }

  function ContentItem(properties){
    exportPropsToSelf.call(this, properties);
  }

  function linkText (tinyMCEContentItem) {
    const editorSelection = window.tinyMCE && window.tinyMCE.activeEditor.selection;
    const selectedText = editorSelection && editorSelection.getContent();
    return selectedText ||
           (tinyMCEContentItem.text && tinyMCEContentItem.text.trim()) ||
           (tinyMCEContentItem.title && tinyMCEContentItem.title.trim());
  }

  ContentItem.fromJSON = function (obj) {
    return new ContentItem(obj)
  };

  var TinyMCEPayloadGenerators = {
    iframe: function (tinyMCEContentItem){
      return $("<div/>").append($("<iframe/>", {
        src: tinyMCEContentItem.url,
        title: tinyMCEContentItem.title,
        allowfullscreen: 'true',
        webkitallowfullscreen: 'true',
        mozallowfullscreen: 'true'
      }).css({
        width: tinyMCEContentItem.placementAdvice.displayWidth,
        height: tinyMCEContentItem.placementAdvice.displayHeight
      }).attr({
        width: tinyMCEContentItem.placementAdvice.displayWidth,
        height: tinyMCEContentItem.placementAdvice.displayHeight
      })).html();
    },

    embed: function (tinyMCEContentItem){
      return $("<div/>").append($("<img/>", {
        src: tinyMCEContentItem.url,
        alt: tinyMCEContentItem.text
      }).css({
        width: tinyMCEContentItem.placementAdvice.displayWidth,
        height: tinyMCEContentItem.placementAdvice.displayHeight
      })).html();
    },

    text: function (tinyMCEContentItem){
      return tinyMCEContentItem.text
    },

    link: function (tinyMCEContentItem) {
      var $linkContainer = $("<div/>"),
        $link = $("<a/>", {
          href: tinyMCEContentItem.url,
          title: tinyMCEContentItem.title,
          target: tinyMCEContentItem.linkTarget
        });

      if(tinyMCEContentItem.linkClassName){
        $link.addClass(tinyMCEContentItem.linkClassName);
      }

      $linkContainer.append($link);
      if(!!tinyMCEContentItem.thumbnail) {
        $link.append($("<img />", {
          src: tinyMCEContentItem.thumbnail['@id'],
          height: tinyMCEContentItem.thumbnail.height || 48,
          width: tinyMCEContentItem.thumbnail.width || 48,
          alt: tinyMCEContentItem.text
        }))
      } else if (window.tinyMCE.activeEditor.selection.getContent()) {
          $link[0].innerHTML = linkText(tinyMCEContentItem);
      } else {
        // don't inject tool provided content into the page HTML
        $link.text(linkText(tinyMCEContentItem));
      }

      return $linkContainer.html();
    }
  };

  function TinyMCEContentItem(contentItem) {
    this.contentItem = contentItem;
    var decorate = function (prop, getFunc){
      Object.defineProperty(this, prop, {
        get: getFunc.bind(this)
      });
    }.bind(this);

    exportPropsToSelf.call(this, contentItem, Object.getOwnPropertyNames);

    decorate('isLTI', function (){
      return !!~LTI_MIME_TYPES.indexOf(this.mediaType);
    });

    decorate('isOverriddenForThumbnail', function (){
      return this.isLTI && this.thumbnail && this.placementAdvice.presentationDocumentTarget === 'iframe';
    });

    decorate('isImage', function (){
      return this.mediaType && this.mediaType.indexOf('image') == 0;
    });

    decorate('linkClassName', function (){
      return this.isOverriddenForThumbnail ? "lti-thumbnail-launch" : ""
    });

    decorate('url', function (){
      return (this.isLTI ? this.canvasURL : this.contentItem.url).replace(/^(data:text\/html|javascript:)/, "#$1");
    });

    decorate('linkTarget', function (){
      if(this.isOverriddenForThumbnail) {
        return JSON.stringify(this.placementAdvice);
      }

      return this.placementAdvice.presentationDocumentTarget.toLowerCase() == 'window' ? '_blank' : null;
    });

    decorate('docTarget', function (){
      if(this.placementAdvice.presentationDocumentTarget == 'embed' && !this.isImage) {
        return 'text';
      } else if (this.isOverriddenForThumbnail) {
        return 'link';
      }

      return this.placementAdvice.presentationDocumentTarget.toLowerCase();
    });


    decorate('codePayload', function (){
      switch(this.docTarget) {
        case 'iframe':
          return TinyMCEPayloadGenerators.iframe(this);

        case 'embed':
          return TinyMCEPayloadGenerators.embed(this);

        case 'text':
          return TinyMCEPayloadGenerators.text(this);

        default:
          return TinyMCEPayloadGenerators.link(this);
      }
    });
  }

  TinyMCEContentItem.ContentItem = ContentItem;
  TinyMCEContentItem.fromJSON = function (data){
    var contentItem = ContentItem.fromJSON(data);
    return new TinyMCEContentItem(contentItem);
  }

  export default TinyMCEContentItem;
