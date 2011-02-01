/*
* jquery-google-analytics plugin
*
* A jQuery plugin that makes it easier to implement Google Analytics tracking,
* including event and link tracking.
*
* Adds the following methods to jQuery:
*   - $.trackPage() - Adds Google Analytics tracking on the page from which
*     it's called.
*   - $.trackEvent() - Tracks an event using the given parameters.
*   - $('a').track() - Adds event tracking to element(s).
*   - $.timePageLoad() - Measures the time it takes  an event using the given parameters.
*
* Features:
*   - Improves page load time by loading Google Analytics code without blocking.
*   - Easy and extensible event and link tracking plugin for jQuery and Google Analytics
*   - Automatic internal/external link detection. Default behavior is to skip
*     tracking of internal links.
*   - Enforces that tracking event handler is added to an element only once.
*   - Configurable: custom event tracking, skip internal links, metadata
*     extraction using callbacks.
*
* Copyright (c) 2008-09 Christian Hellsten
*
* Plugin homepage:
*   http://aktagon.com/projects/jquery/google-analytics/
*   http://github.com/christianhellsten/jquery-google-analytics/
*
* Examples:
*   http://aktagon.com/projects/jquery/google-analytics/examples/
*   http://code.google.com/apis/analytics/docs/eventTrackerGuide.html
*
* Repository:
*   git://github.com/christianhellsten/jquery-google-analytics.git
*
* Version 1.1.2
*
* Tested with:
*   - Mac: Firefox 3, Safari 3
*   - Linux: Firefox 3
*   - Windows: Firefox 3, Internet Explorer 6
*
* Licensed under the MIT license:
* http://www.opensource.org/licenses/mit-license.php
*
* Credits:
*   - http://google.com/analytics
*   - http://lyncd.com: 
*       Idea for trackPage method came from this blog post: http://lyncd.com/2009/03/better-google-analytics-javascript/
*/
(function($, INST, undefined) {

  var pageTracker;
  
  var analyticsIsReady = false;
  var toDoWhenReady = [];

  $(function(){
    $(document).bind('analyticsReady', function(){
      analyticsIsReady = true;
      $.each(toDoWhenReady, function(){
        this[0].call(window, this[1]);
      });
    });
  });

  var whenReady = $.whenAnalyticsReady = function(fn){
    var args = Array.prototype.slice.call(arguments, 1);
    if (analyticsIsReady) {
      fn.call(this, args);
    } else {
      toDoWhenReady.push([fn, args]);
    }
  }
  

  /**
   * Enables Google Analytics tracking on the page from which it's called. 
   *
   * Usage:
   *  <script type="text/javascript">
   *    $.trackPage('UA-xxx-xxx', options);
   *  </script>
   *
   * Parameters:
   *   account_id - Your Google Analytics account ID.
   *   options - An object containing one or more optional parameters:
   *     - onload - boolean - If false, the Google Analytics code is loaded
   *       when this method is called instead of on window.onload.
   *     - status_code - The HTTP status code of the current server response.
   *       If this is set to something other than 200 then the page is tracked
   *       as an error page. For more details: http://www.google.com/support/analytics/bin/answer.py?hl=en&answer=86927
   *     - callback  - function to be executed after the Google Analytics code is laoded and initialized
   *
   */
  $.trackPage = function(account_id, options) {
    var host = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
    var script;

    // Use default options, if necessary
    var settings = $.extend({}, {onload: true, status_code: 200}, options);
    var src  = host + 'google-analytics.com/ga.js';

    function init_analytics() {
      if (typeof _gat != undefined) {
        // debug('Google Analytics loaded');

        pageTracker = _gat._getTracker(account_id);
        if (typeof settings.domainName != 'undefined') {
          pageTracker._setDomainName(settings.domainName);
        }
        
        

        if(!settings.status_code || settings.status_code == 200) {
          pageTracker._trackPageview();
          $(document).trigger('analyticsReady');
        } else {
          debug('Tracking error ' + settings.status_code);
          pageTracker._trackPageview("/" + settings.status_code + 
            ".html?page=" + document.location.pathname + document.location.search + 
            "&from=" + document.referrer +
            "&error_id=" + (settings.error_id || "unknown")
          );
        }
        if($.isFunction(settings.callback)){
          settings.callback();
        }
      }
      else { 
        throw "_gat is undefined"; // setInterval loading?
      }
    }

    var load_script = function() {
      $.ajax({
        type: "GET",
        url: src,
        success: function() {          
          init_analytics(); 
        },
        dataType: "script",
        cache: true // We want the cached version
      });
    };
    
    // Enable tracking when called or on page load?
    if(settings.onload == true || settings.onload == null) {
      $(window).load(load_script);
    } else {
      load_script();
    }
  };
  
  $.setTrackingVar = function(arg) {
    whenReady(function(){
      pageTracker._setVar(arg)
    });
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
   *  skip_internal - optional boolean value. If true then internal links are not tracked.
   *
   */
  $.trackEvent = function(category, action, label, value) {
    whenReady(function(){
      pageTracker._trackEvent(category, action, label, value);
    });
  };

  /**
   * simultates tracking a page view. Usage:
   *
   * $.trackPageView("/path/to/url/to/track")
   *
   */
  $.trackPageview = function(url) {
    whenReady(function(){
      pageTracker._trackPageview(url)
    });
  };
  
  /**
   * Adds click tracking to elements. Usage:
   *
   *  $('a').track()
   *
   */
  $.fn.track = function(options) {
    // Add event handler to all matching elements
    return this.each(function() {
      var element = $(this);

      // Prevent an element from being tracked multiple times.
      if (element.hasClass('tracked')) {
        return false;
      } else {
        element.addClass('tracked');
      } 

      // Use default options, if necessary
      var settings = $.extend({}, $.fn.track.defaults, options);

      // Merge custom options with defaults.
      var category = evaluate(element, settings.category);
      var action   = evaluate(element, settings.action);
      var label    = evaluate(element, settings.label);
      var value    = evaluate(element, settings.value);
      var event_name = evaluate(element, settings.event_name);
      
      var message = "category:'" + category + "' action:'" + action + "' label:'" + label + "' value:'" + value + "'";
      
      debug('Tracking ' + event_name + ' ' + message);

      // Bind the event to this element.
      element.bind(event_name + '.track', function() {       
        // Should we skip internal links? REFACTOR
        var skip = settings.skip_internal && (element[0].hostname == location.hostname);
      
        if(!skip) {
          $.trackEvent(category, action, label, value);
          debug('Tracked ' + message);
        } else {
          debug('Skipped ' + message);
        }

        return true;
      });
    });
    
    /**
     * Checks whether a setting value is a string or a function.
     * 
     * If second parameter is a string: returns the value of the second parameter.
     * If the second parameter is a function: passes the element to the function and returns function's return value.
     */
    function evaluate(element, text_or_function) {
      if(typeof text_or_function == 'function') {
        text_or_function = text_or_function(element);
      }
      return text_or_function;
    }
  };

  /**
   * Prints to Firebug console, if available. To enable:
   *   $.fn.track.defaults.debug = true;
   */
  function debug(message) {
    if (typeof console != 'undefined' && typeof console.debug != 'undefined' && $.fn.track.defaults.debug) {
      console.debug(message);
    }
  }

  /**
   * Default (overridable) settings.
   */
  $.fn.track.defaults = {
    category      : function(element) { return (element[0].hostname == location.hostname) ? 'internal':'external'; },
    action        : 'click',
    label         : function(element) { return element.attr('href'); },
    value         : null,
    skip_internal : true,
    event_name    : 'click',
    debug         : true
  };
  
  // this next part is the only part that is Instructure specific
  if (INST.environment == "production" && INST.googleAnalyticsAccount) {
    $.trackPage(INST.googleAnalyticsAccount, {
      status_code: INST.http_status,
      error_id: INST.error_id,
      domainName: document.location.hostname
    }); 
  }
  
})(jQuery, INST);


