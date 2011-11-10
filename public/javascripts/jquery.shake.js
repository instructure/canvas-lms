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

// handles shake event in browsers that support the devicemotion event (eg: iOS)
// inspired by: https://github.com/shokai/js-iphone-shake-event

define(['jquery'], function($) {

$.fn.shake = function(callback, options) {
  if ('ondevicemotion' in window) {
    var opts = $.extend({ threshold: 18, interval: 2 }, options),
        lastShake = 0,
        xyz = {};

    $(window).bind('devicemotion', function(event){
      xyz = event.originalEvent.accelerationIncludingGravity;
    });

    setInterval(function(){
      if ( Math.abs(xyz.x) > opts.threshold ||
           Math.abs(xyz.y) > opts.threshold ||
           Math.abs(xyz.z) > opts.threshold ) {
        var now = (new Date())/1000;
        if (lastShake + opts.interval < now){
          lastShake = now;
          callback(xyz);
        }
      }
    }, 100);
  }
  return this;
};

});
