/*
    sfu.js
    SFU-specific client-side modifications for Canvas

    SFU require.js modules are located in $CANVAS_ROOT/public/javascripts/sfu-modules

 */


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
            utils.onElementRendered(selector, cb, _attempts);
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
        '<option value="http://www.sfu.ca/techforum">Q&A Forum</option>',
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

    /*  Add copyright compliance notice to the publish course button
        When a course page loads, check to see if the course is unpublished.
        If so, first immediately disable the publish button to allow time for the bundle to be required async.
        Then load the CANVAS_ROOT/public/javascripts/sfu-modules/copyright_notice_modal_dialog bundle
        This bundle handles attaching a click handler to the submit button (and re-enabling it).
        The click handler renders the SFUCopyrightComplianceNoticeModalDialog react component.

        If the course is published, nothing happens.
    */
    utils.onPage(/^\/courses\/\d+$/, function() {
        var $publishButton = $('.btn-publish')
        if ($publishButton.length) {
            $publishButton.attr('disabled', true);
            require(['sfu-modules/copyright_notice_modal_dialog'], function(module) {
                module.attachClickHandlerTo(location.pathname.replace('/courses/', 'edit_course_'));
            });
        }
    });

    /*  Add PIA notice to Google Docs section on /courses/DDDDD/collaborations
        When the collaboration page loads, load the google_docs_pia_notice bundle
        In the bundle, check the current user's role within the current course and
        display the appropriate message.
    */
    utils.onPage(/^\/courses\/\d+\/collaborations\/?$/, function () {
        require(['sfu-modules/google_docs_pia_notice'], function(module) {
            module.showGoogleDocsWarning();
        });
    });

    // Fixes for Import Content page only
    utils.onPage(/courses\/\d+\/content_migrations/, function() {
        // The fixes are for elements that are dynamically generated when a specific XHR call completes
        $(document).ajaxComplete(function (event, XMLHttpRequest, ajaxOptions) {
            if (ajaxOptions.url && ajaxOptions.url.match(/users\/\d+\/manageable_courses/)) {
                // Alphabetize course drop-down list, by sorting <option>s inside each <optgroup>
                // NOTE: This is no longer needed when XHR results are pre-sorted by Canvas
                $('optgroup', $('#courseSelect')).each(function (i, termGroup) {
                    $('option', termGroup)
                        .sort(function (a, b) { return $(a).text().localeCompare($(b).text()); })
                        .appendTo(termGroup);
                });
                // END Alphabetize course drop-down list
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

    // CANVAS-246 Create button that links to the Start a New Ad Hoc Space form (only on these pages: / and /courses)
    utils.onPage(/^\/(courses)?$/, function () {
        // Add the button right after the existing Start a New Course button
        var addAdHocButton = function () {
            return; // TODO: Remove this line when Ad Hoc Spaces are ready
            var $courseButton = $('#start_new_course');
            var $adhocButton = $courseButton.clone();
            $adhocButton
                .text('Start a New Ad Hoc Space')
                .attr('id', 'start_new_adhoc')
                .attr('aria-controls', 'new_adhoc_form')
                .insertAfter($courseButton)
                .on('click', function () {
                    window.location = '/sfu/adhoc/new';
                });
        }

        // If the button is not there yet, it's likely still being loaded in the sidebar.
        // Wait for it to complete, and then add the button. This is meant for the home page.
        if ($('#start_new_course').length == 0) {
            $(document).ajaxComplete(function (event, XMLHttpRequest, ajaxOptions) {
                if (ajaxOptions.url && ajaxOptions.url.match(/dashboard-sidebar/)) {
                    addAdHocButton();
                }
            });
        } else {
            addAdHocButton();
        }
    });
    // END CANVAS-246

    // CANVAS-252 Manage user profile names
    utils.onPage(/^\/profile\/settings\/?$/, function () {
        $(document).ready(function () {
            var $fieldsToLock = $('.full_name.display_data, .sortable_name.display_data');
            var $helpText = $('.short_name').siblings('span.edit_or_show_data');

            // CANVAS-253 Temporarily make full/sortable names read-only
            $fieldsToLock.removeClass('display_data').addClass('edit_or_show_data');
            $fieldsToLock.siblings('input').remove();

            // CANVAS-254 Add verbiage about Display Name
            $helpText.append('<br />Changing this will only affect your display name within Canvas, ' +
                'and not in other systems (e.g. <a href="https://go.sfu.ca" target="_blank">goSFU</a>, ' +
                '<a href="https://myinfo.sfu.ca" target="_blank">myInfo</a>, etc.)');
        });
    });
    // END CANVAS-252


    // Add "Add People" button to Ad-Hoc Groups
    // We only want to add this button to groups in the ad-hoc group set
    utils.onPage(/^\/groups\/\d+\/users$/, function() {
        var groupId = /^\/groups\/(\d+)\/users$/.exec(window.location.pathname)[1];
        var buttonApiUrl = '/sfu/api/v1/adhoc_group_button/' + groupId;

        $.ajax({
            url: buttonApiUrl,
            success: function(html) {
                $('#right-side div').prepend(html);
                $('#addUsers').on('click', loadFrame);
            },
            error: function() { }
        });

        var loadFrame = function() {
            $('#addUsers').attr('disabled', 'true');
            var token = $('#addUsers').data('token');
            var iframe = $('<iframe />', {
                name: 'adhoc_group_users_frame',
                id:   'adhoc_group_users_frame',
                src: 'https://canvas-group.sfu.ca/' + groupId + '/users?server=' + window.location.hostname + '&token=' + token,
                style: 'width:100%;min-height:500px;border:none'
            });
            $('#content').empty().append(iframe);
        };

    });

    // Setup Backbone event handler that will be called when all the content DOM elements 
    // have been rendered. This will activate the accordion and tab components on the page.
    function setupAccordionAndTabActivation() {
        $.subscribe('userContent/change', function () {
            $("div.accordion").accordion({header: "h3"});
            $(".sfu-tabs").tabs();
        });
    }

    // On course and wiki pages, activate accordion and tab components, if they exist.
    utils.onPage(/^\/(courses|groups)\/\d+\/pages\/[A-Za-z0-9_\-+~<>]+$/, setupAccordionAndTabActivation);
    
    // A page designated as a front page has a different url.
    utils.onPage(/^\/(courses|groups)\/\d+\/wiki$/, setupAccordionAndTabActivation);

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

