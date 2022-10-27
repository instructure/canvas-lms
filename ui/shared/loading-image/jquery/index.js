/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

// Shows an ajax-loading image on the given object.
$.fn.loadingImg = function (options) {
  if (!this || this.length === 0) {
    return this
  }
  const dir = window.getComputedStyle(this[0]).direction || 'ltr'

  const $obj = this.filter(':first')
  let list
  if (options === 'hide' || options === 'remove') {
    $obj.children('.loading_image').remove()
    list = $obj.data('loading_images') || []
    list.forEach(item => {
      if (item) {
        item.remove()
      }
    })
    $obj.data('loading_images', null)
    this.css('margin-inline-end', '')
    return this
  } else if (options === 'remove_once') {
    $obj.children('.loading_image').remove()
    list = $obj.data('loading_images') || []
    const img = list.pop()
    if (img) {
      img.remove()
    }
    $obj.data('loading_images', list)
    return this
  } else if (options === 'register_image' && arguments.length === 3) {
    $.fn.loadingImg.image_files[arguments[1]] = arguments[2]
    return this
  }
  options = $.extend({}, $.fn.loadingImg.defaults, options)
  let image = $.fn.loadingImg.image_files.normal
  if (options.image_size && $.fn.loadingImg.image_files[options.image_size]) {
    image = $.fn.loadingImg.image_files[options.image_size]
  }
  if (options.paddingTop) {
    options.vertical = options.paddingTop
  }
  let paddingTop = 0
  if (options.vertical) {
    if (options.vertical === 'top') {
      // nothing to do
    } else if (options.vertical === 'bottom') {
      paddingTop = $obj.outerHeight()
    } else if (options.vertical === 'middle') {
      paddingTop = $obj.outerHeight() / 2 - image.height / 2
    } else {
      paddingTop = parseInt(options.vertical, 10)
      if (Number.isNaN(Number(paddingTop))) {
        paddingTop = 0
      }
    }
  }
  let paddingLeft = 0
  if (options.horizontal) {
    if (options.horizontal === 'left') {
      // nothing to do
    } else if (options.horizontal === 'right') {
      paddingLeft = $obj.outerWidth() - image.width
    } else if (options.horizontal === 'right!') {
      paddingLeft = dir === 'ltr' ? $obj.outerWidth() + 5 : -5 - (image.width || 16)
      this.css({'margin-inline-end': '16px'})
    } else if (options.horizontal === 'middle') {
      paddingLeft = $obj.outerWidth() / 2 - image.width / 2
    } else {
      paddingLeft = parseInt(options.horizontal, 10)
      if (Number.isNaN(Number(paddingLeft))) {
        paddingLeft = 0
      }
    }
  }
  const zIndex = $obj.zIndex() + 1
  const $imageHolder = $(document.createElement('div')).addClass('loading_image_holder')
  const $image = $(document.createElement('img')).attr('src', image.url)
  $imageHolder.append($image)
  list = $obj.data('loading_images') || []
  list.push($imageHolder)
  $obj.data('loading_images', list)

  if (!$obj.css('position') || $obj.css('position') === 'static') {
    const offset = $obj.offset()
    let top = offset.top,
      left = offset.left
    if (options.vertical) {
      top += paddingTop
    }
    if (options.horizontal) {
      left += paddingLeft
    }
    $imageHolder.css({
      zIndex,
      position: 'absolute',
      top,
      left,
    })
    $('body').append($imageHolder)
  } else {
    $imageHolder.css({
      zIndex,
      position: 'absolute',
      top: paddingTop,
      left: paddingLeft,
    })
    $obj.append($imageHolder)
  }
  return $(this)
}
$.fn.loadingImg.defaults = {paddingTop: 0, image_size: 'normal', vertical: 0, horizontal: 0}
$.fn.loadingImg.image_files = {
  normal: {url: '/images/ajax-loader.gif', width: 32, height: 32},
  small: {url: '/images/ajax-loader-small.gif', width: 16, height: 16},
}
$.fn.loadingImage = $.fn.loadingImg
