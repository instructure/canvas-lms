/* jshint indent: 4 */

(function($) {

    var utils = {

        onPage: function(regex, fn) {
          if (location.pathname.match(regex)) fn();
        },

        hasAnyRole: function(/*roles, cb*/) {
          var roles = [].slice.call(arguments, 0);
          var cb = roles.pop();
          for (var i = 0; i < arguments.length; i++) {
            if (ENV.current_user_roles.indexOf(arguments[i]) !== -1) {
              return cb(true);
            }
          }
          return cb(false);
        },

        isUser: function(id, cb) {
          cb(ENV.current_user_id == id);
        },

        onElementRendered: function(selector, cb, _attempts) {
          var el = $(selector);
          _attempts = ++_attempts || 1;
          if (el.length) return cb(el);
          if (_attempts == 60) return;
          setTimeout(function() {
            onElementRendered(selector, cb, _attempts);
          }, 250);
        }

    }


    // header rainbow
    $('#header').append('<div id="header-rainbow">');

    // help links
    var helpHtml = [
        '<li>',
        '<select class="sfu_help_links">',
        '<option value="">Help</option>',
        '<option value="https://canvas.sfu.ca/courses/14504">Help for Students</option>',
        '<option value="https://canvas.sfu.ca/courses/14686">Help for Instructors</option>',
        '</li>'
    ].join('');
    $('#topbar .logout').before(helpHtml);
    $('#topbar .sfu_help_links').on('change', function(ev) {
        if (this.value) {
            window.location = this.value;
        }
    });

    // sfu logo in footer
    $('footer').html('<a href="http://www.sfu.ca/canvas"><img alt="SFU Canvas" src="/sfu/images/sfu-logo.png" width="250" height="38"></a>').show();

    // handle no-user case
    if ($('#header').hasClass('no-user')) {
        // add in a dummy #menu div
        $('#header-inner').append('<div id="menu" style="height:41px"></div>');
        // remove the register link
        $('#header.no-user a[href="/register"]').parent().remove()
    }

    // hijack Start New Course button (CANVAS-192)
    // first, cache the original event handler and disable it
    function hijackStartNewCourseButton() {
        if (!jQuery._data(document, "events")) {
            // bit of a hack for IE which seems to randomly not have the events
            // loaded by the time this script loads
            window.setTimeout(hijackStartNewCourseButton, 100);
        } else {
            var eventlist = jQuery._data( document, "events" ).click,
                targetSelector = '.element_toggler[aria-controls]',
                origHandler, e;
            // cache the handler
            for (var i = 0; i < eventlist.length; i++) {
                e = eventlist[i];
                if (e.selector === targetSelector) {
                    origHandler = e.handler;
                }
            }
            if (origHandler) {
                // remove the handler, and add our own
                $(document).off('click change', targetSelector).on('click change', targetSelector, function(event) {
                    if (this.id === 'start_new_course') {
                        event.stopImmediatePropagation();
                        window.location = '/sfu/course/new';
                    } else {
                        origHandler.call(this, event);
                    }
                });
            }
        }
    }
    $(document).ready(function() {
        hijackStartNewCourseButton();
    });

    // END CANVAS-192

    // FIX (temporary) for no-flash browsers to upload files using the Files tool
    var hasFlash = false;
    try {
        if (new ActiveXObject('ShockwaveFlash.ShockwaveFlash')) hasFlash = true;
    } catch(e) {
        if (navigator.mimeTypes ["application/x-shockwave-flash"] != undefined) hasFlash = true;
    }
    if (!hasFlash) {
        // remove the invisible element that is blocking the "Add File" link
        $('#swfupload_holder').hide();
    }
    // END no-flash upload FIX

    // Add copyright compliance notice under the Publish Course button
    utils.onPage(/^\/courses\/\d+$/, function() {
        // The Publish Course button ID attribute contains the course ID
        var $publishButton = $('#' + location.pathname.replace('/courses/', 'edit_course_'));
        var $readMoreLink = $('<a href="/sfu/copyright/disclaimer" class="element_toggler" aria-controls="copyright_dialog" target="_blank">Read more.</a>');
        var $disclaimer = $('<iframe src="/sfu/copyright/disclaimer" seamless="seamless" width="100%" height="100%">').css('border', 'none');
        $("<p>I confirm that the use of copyright protected materials in this course complies with <em>Canada's Copyright Act and SFU Policy R30.04 - Copyright Compliance and Administration</em>. </p>")
            .append($readMoreLink)
            .insertAfter($publishButton);
        // Use a modal dialog to display the full disclaimer
        $('<form id="copyright_dialog" title="Copyright Disclaimer">')
            .attr('data-turn-into-dialog', '{"width":600,"height":500,"modal":true}')
            .append($disclaimer)
            .hide()
            .appendTo('body');
    });

    // Alphabetize course drop-down list (Import Content page only)
    // NOTE: This is no longer needed when XHR results are pre-sorted by Canvas
    utils.onPage(/courses\/\d+\/content_migrations/, function() {
        $(document).ajaxComplete(function (event, XMLHttpRequest, ajaxOptions) {
            // Sort <option>s inside each <optgroup> when the relevant XHR call completes
            if (ajaxOptions.url && ajaxOptions.url.match(/users\/\d+\/manageable_courses/)) {
                $('optgroup', $('#courseSelect')).each(function (i, termGroup) {
                    $('option', termGroup)
                        .sort(function (a, b) { return $(a).text().localeCompare($(b).text()); })
                        .appendTo(termGroup);
                });
            }
        });
    });

    // Fix for the new conversations page - toolbar renders underneath the rainbow bar
    utils.onPage(/conversations/, function() {
        // are we on the new conversations page?
        if (ENV.CONVERSATIONS && (ENV.CONVERSATIONS.ATTACHMENTS_FOLDER_ID && !ENV.hasOwnProperty('CONTEXT_ACTION_SOURCE'))) {
            jQuery('div#main').css('top', '92px');
        }
    });
})(jQuery);

// google analytics
if (window.location.hostname && 'canvas.sfu.ca' === window.location.hostname) {
    var _gaq = _gaq || [];
    _gaq.push(['_setAccount', 'UA-36473171-1']);
    _gaq.push(['_trackPageview']);

    (function() {
        var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
        ga.src = ('https:' === document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
        var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
    })();
}

