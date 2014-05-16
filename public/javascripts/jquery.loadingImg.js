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

define(['jquery'], function($){

  // Shows an ajax-loading image on the given object.
  $.fn.loadingImg = function(options) {
    if(!this || this.length === 0) {
      return this;
    }
    var $obj = this.filter(":first");
    var list;
    if(options === "hide" || options === "remove") {
      $obj.children(".loading_image").remove();
      list = $obj.data('loading_images') || [];
      list.forEach(function(item) {
        if(item) {
          item.remove();
        }
      });
      $obj.data('loading_images', null);
      return this;
    } else if(options === "remove_once") {
      $obj.children(".loading_image").remove();
      list = $obj.data('loading_images') || [];
      var img = list.pop();
      if(img) { img.remove(); }
      $obj.data('loading_images', list);
      return this;
    } else if (options == "register_image" && arguments.length == 3) {
      $.fn.loadingImg.image_files[arguments[1]] = arguments[2];
    }
    options = $.extend({}, $.fn.loadingImg.defaults, options);
    var image = $.fn.loadingImg.image_files['normal'];
    if(options.image_size && $.fn.loadingImg.image_files[options.image_size]) {
      image = $.fn.loadingImg.image_files[options.image_size];
    }
    if(options.paddingTop) {
      options.vertical = options.paddingTop;
    }
    var paddingTop = 0;
    if(options.vertical) {
      if(options.vertical == "top") {
      } else if(options.vertical == "bottom") {
        paddingTop = $obj.outerHeight();
      } else if(options.vertical == "middle")  {
        paddingTop = ($obj.outerHeight() / 2) - (image.height / 2);
      } else {
        paddingTop = parseInt(options.vertical, 10);
        if(isNaN(paddingTop)) {
          paddingTop = 0;
        }
      }
    }
    var paddingLeft = 0;
    if(options.horizontal) {
      if(options.horizontal == "left") {
      } else if(options.horizontal == "right") {
        paddingLeft = $obj.outerWidth() - image.width;
      } else if(options.horizontal == "middle")  {
        paddingLeft = ($obj.outerWidth() / 2) - (image.width / 2);
      } else {
        paddingLeft = parseInt(options.horizontal, 10);
        if(isNaN(paddingLeft)) {
          paddingLeft = 0;
        }
      }
    }
    var zIndex = $obj.zIndex() + 1;
    var $imageHolder = $(document.createElement('div')).addClass('loading_image_holder');
    var $image = $(document.createElement('img')).attr('src', image.url);
    $imageHolder.append($image);
    list = $obj.data('loading_images') || [];
    list.push($imageHolder);
    $obj.data('loading_images', list);

    if(!$obj.css('position') || $obj.css('position') == "static") {
      var offset = $obj.offset();
      var top = offset.top, left = offset.left;
      if(options.vertical) {
        top += paddingTop;
      }
      if(options.horizontal) {
        left += paddingLeft;
      }
      $imageHolder.css({
        zIndex: zIndex,
        position: "absolute",
        top: top,
        left: left
      });
      $("body").append($imageHolder);
    } else {
      $imageHolder.css({
        zIndex: zIndex,
        position: "absolute",
        top: paddingTop,
        left: paddingLeft
      });
      $obj.append($imageHolder);
    }
    return $(this);
  };
  $.fn.loadingImg.defaults = {paddingTop: 0, image_size: 'normal', vertical: 0, horizontal: 0};
  $.fn.loadingImg.image_files = {
    normal: {url: '/images/ajax-loader.gif', width: 32, height: 32},
    small: {url: '/images/ajax-loader-small.gif', width: 16, height: 16}
  };
  $.fn.loadingImage = $.fn.loadingImg;
  
});
