/* jshint indent:4, camelcase:false, laxcomma:false */
(function() {
    define(['jquery', 'vendor/jquery.spin'], function() {
        var enrollmentCache = {};
        return function() {
            $('.enrollment_term_switcher select').on('change', function() {
                var el = $(this),
                    term = el.val(),
                    url = '/sfu/stats/enrollments/' + term + '.json',
                    totalOrUnique = el.data('totalorunique'),
                    enrollmentType = toTitleCase(el.data('enrollmenttype')) + 'Enrollment',
                    target = el.parentsUntil('.stats_enrollment_box').prev()[0],
                    targetText = $(target).text(),
                    spinnerContainer = el.parent().find('.spinner_container'),
                    spinnerOpts = {
                        lines: 11,
                        length: 1,
                        width: 2,
                        radius: 5,
                        corners: 1,
                        rotate: 0,
                        direction: 1,
                        color: '#000',
                        speed: 1,
                        trail: 60,
                        shadow: false,
                        hwaccel: false,
                        className: 'spinner',
                        zIndex: 2e9,
                        top: 'auto',
                        left: 'auto'
                    };

                if (enrollmentCache.hasOwnProperty(term)) {
                    var data = enrollmentCache[term];
                    fancyCounter(target, parseInt(targetText.replace(/\D/g, ''), 10), parseInt(data[totalOrUnique][enrollmentType], 10));
                } else {

                    spinnerContainer.spin(spinnerOpts);
                    $.getJSON(url, function(data) {
                        spinnerContainer.spin(false);
                        enrollmentCache[term] = data;
                        fancyCounter(target, parseInt(targetText.replace(/\D/g, ''), 10), parseInt(data[totalOrUnique][enrollmentType], 10));
                    });
                }
            });

            function toTitleCase(str) { return str.replace(/\w\S*/g, function(txt){return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();}); }

            function fancyCounter(el, from, to) {
                $({countNum: from}).animate({countNum: to}, {
                    duration: 300,
                    easing:'linear',
                    step: function() {
                        $(el).text(numberWithCommas(Math.floor(this.countNum)));
                    },
                    complete: function() {
                        $(el).text(numberWithCommas(this.countNum));
                    }
                });
            }

            function numberWithCommas(x) {
                return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
            }
        }
    });
})();