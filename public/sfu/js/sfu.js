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

