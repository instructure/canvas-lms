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

import INST from 'INST'
import $ from 'jquery'

  // requires INST global
  window._gaq = window._gaq || [];
  var asyncScriptInserted = false;

  /**
   * Enables Google Analytics tracking on the page from which it's called.
   *
   * Usage:
   *  $.trackPage('UA-xxx-xxx', options);
   *
   * Parameters:
   *   account_id - Your Google Analytics account ID.
   *   options - An object containing one or more optional parameters:
   *     - status_code - The HTTP status code of the current server response.
   *       If this is set to something other than 200 then the page is tracked
   *       as an error page. For more details: http://antezeta.com/news/404-errors-google-analytics
   *
   */
  $.trackPage = function(account_id, options) {

    if (!asyncScriptInserted) {
      asyncScriptInserted = true;

      // insert ga.js async
      var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
      ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
      var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
    }

    options = $.extend({status_code: 200}, options);
    window._gaq.push(['_setAccount', account_id]);
    if (options.domain) {
      window._gaq.push(['_setDomainName', options.domain]);
    }
    if (ENV.ga_page_title) {
      window._gaq.push(['_set', 'title', ENV.ga_page_title]);
    }
    window._gaq.push(['_trackPageview']);
    window._gaq.push(['_trackPageLoadTime']);
    if (options.status_code != 200) {
      window._gaq.push(['_trackEvent', 'Errors', options.status_code, 'page: ' + document.location.pathname + document.location.search + ' ref: ' + document.referrer, options.error_id ]);
    }
  };

  // see: http://code.google.com//apis/analytics/docs/gaJS/gaJSApiBasicConfiguration.html#_gat.GA_Tracker_._setCustomVar
  $.setTrackingVar = function() {
    var args = Array.prototype.slice.call( arguments, 0 );
    args.unshift('_setCustomVar');
    window._gaq.push.apply(window._gaq, args);
  };

  /**
   * Tracks an event using the given parameters.
   *
   * The trackEvent method takes four arguments:
   *
   *  category - required string used to group events
   *  action - required string used to define event type, eg. click, download
   *  label - optional label to attach to event, eg. buy
   *  value - optional numerical value to attach to event, eg. price
   *
   * see: http://code.google.com/apis/analytics/docs/tracking/eventTrackerGuide.html
   */
  $.trackEvent = function(category, action, label, value) {
    window._gaq.push(['_trackEvent', category, action, label, value]);
  };

  /**
   * simultates tracking a page view. Usage:
   *
   * $.trackPageView("/path/to/url/to/track")
   *
   * see: http://code.google.com//apis/analytics/docs/gaJS/gaJSApiBasicConfiguration.html#_gat.GA_Tracker_._trackPageview
   */
  $.trackPageview = function(url) {
    window._gaq.push(['_trackPageview', url]);
  };

  // this next part is the only part that is Instructure specific
  if (INST && INST.googleAnalyticsAccount) {
    $.trackPage(INST.googleAnalyticsAccount, {
      status_code: INST.http_status,
      error_id: INST.error_id,
      domainName: document.location.hostname
    });
  }

  export default {
    trackPage: $.trackPage,
    setTrackingVar: $.setTrackingVar,
    trackEvent: $.trackEvent,
    trackPageView: $.trackPageView
  };


