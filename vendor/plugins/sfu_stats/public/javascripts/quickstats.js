/* jshint indent:4, camelcase:false, laxcomma:false */
(function() {
    define(['jquery'], function() {
        return function() {
            $('.enrollment_term_switcher select').on('change', function() {
                var el = $(this),
                    url = '/sfu/stats/enrollments/' + el.val() + '/' + toTitleCase(el.data('enrollmenttype')) + 'Enrollment.json',
                    totalOrUnique = el.data('totalorunique');

                $.getJSON(url, function(data) {
                    var key = totalOrUnique + '_enrollments_for_term';
                    el = el.parentsUntil('.stats_enrollment_box').prev()[0];
                    fancyCounter(el, parseInt(el.innerText.replace(/\D/g, ''), 10), parseInt(data[key], 10));
                });

            });

            function toTitleCase(str) { return str.replace(/\w\S*/g, function(txt){return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();}); }

            function fancyCounter(el, from, to) {
                $({countNum: from}).animate({countNum: to}, {
                    duration: 300,
                    easing:'linear',
                    step: function() {
                        el.innerText = numberWithCommas(Math.floor(this.countNum));
                    },
                    complete: function() {
                        el.innerText = numberWithCommas(this.countNum);
                    }
                });
            }

            function numberWithCommas(x) {
                return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
            }
        }
    });
})();