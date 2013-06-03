/* jshint indent: 4 */

(function($) {

    // header rainbow

    $('#header').append('<div id="header-rainbow">');
    $('#topbar .logout').before('<li><a href="http://www.sfu.ca/canvas" target=_blank>Help</a></li>')
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

