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

// Scrolls the supplied object until its visible. Call from
// ("html,body") to scroll the window.

import $ from 'jquery'
import './vendor/jquery.scrollTo'
import './jquery.instructure_jquery_patches'

$.fn.scrollToVisible = function(obj) {
  var options = {};
  var $obj = $(obj);

  if ($obj.length === 0) { return; }
  var innerOffset   = $obj.offset(),
      width         = $obj.outerWidth(),
      height        = $obj.outerHeight(),
      top           = innerOffset.top,
      bottom        = top + height,
      left          = innerOffset.left,
      right         = left + width,
      currentTop    = (this.selector == "html,body" ? $.windowScrollTop() : this.scrollTop()),
      currentLeft   = this.scrollLeft(),
      currentHeight = this.outerHeight(),
      currentWidth  = this.outerWidth();

  if (this.selector != "html,body") {
    var outerOffset = $("body").offset();
    this.each(function() {
      try {
        outerOffset = $(this).offset();
        return false;
      } catch(e) {}
    });
    top    -= outerOffset.top;
    bottom -= outerOffset.top;
    left   -= outerOffset.left;
    right  -= outerOffset.left;
  }

  if (this[0].tagName == "HTML" || this[0].tagName == "BODY") {
    currentHeight = $(window).height();
    if($("#wizard_box:visible").length > 0) {
      currentHeight -= $("#wizard_box:visible").height();
    }
    currentWidth = $(window).width();
    top -= currentTop;
    left -= currentLeft;
    bottom -= currentTop;
    right -= currentLeft;
  }
  if (top < 0 || (currentHeight < height && bottom > currentHeight)) {
    options.scrollTop = top + currentTop;
  } else if (bottom > currentHeight) {
    options.scrollTop = bottom + currentTop - currentHeight + 20;
  }
  if (left < 0) {
    options.scrollLeft = left + currentLeft;
  } else if (right > currentWidth) {
    options.scrollLeft = right + currentLeft - currentWidth + 20;
  }
  if (options.scrollTop == 1) { options.scrollTop = 0; }
  if (options.scrollLeft == 1) { options.scrollLeft = 0; }
  
  this.scrollTop(options.scrollTop);
  this.scrollLeft(options.scrollLeft);
  
  return this;
};
