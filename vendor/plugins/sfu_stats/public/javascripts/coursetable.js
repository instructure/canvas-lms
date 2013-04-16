/* jshint indent:4, camelcase:false, laxcomma:false */
(function() {
    define(['jquery', 'sfu_stats/vendor/jquery.dataTables'], function() {
        return function() {
            var tableOptions = {
                sAjaxSource: '/sfu/stats/courses/current.json',
                fnServerData: function(sSource, aoData, fnCallback) {
                    $.ajaxJSON(sSource, 'GET', {}, function(data) {
                        fnCallback(data);
                    });
                },
                bPaginate: false,
                bProcessing: true,
                bLengthChange: false,
                bInfo: true,
                bAutoWidth: false,
                aoColumnDefs: [
                    { bVisible: false, aTargets: [0] }
                ],
                aaSorting: [[3, 'asc'], [1, 'asc']],
                oLanguage: {
                    sInfo: "Showing _TOTAL_ courses",
                    sInfoFiltered: "(filtered from _MAX_ courses)",
                    sZeroRecords: "No matching courses found &ndash; try adjusting your filters."
                },
                sDom: 'irt'
            };
            var courseTable = $('#course_table table').dataTable(tableOptions).show();

            // widgets
            $('.sfu_stats_widget_header').on('click', function() {
                var widget = $(this).parent(),
                    collapsedClass = 'sfu_stats_widget_collapsed';
                widget.find('.sfu_stats_widget_body').slideToggle('fast');
                widget.toggleClass(collapsedClass);
            });

            $('.checkbox-workflow').on('change', function() {
                var filter = [];
                $('.checkbox-workflow:checked').each(function() {
                    filter.push(this.value);
                });
                courseTable.fnFilter(filter.join('|'), 3, true);
            });

            $('.checkbox-credit-only, .checkbox-exclude-webct').on('change', function() {
                var el = $(this);
                var checked = el.is(':checked');
                var data = el.data();
                var filter = checked ? data.filter_checked : (data.filter_unchecked || '');
                courseTable.fnFilter(filter, data.col, data.regex);
            });

            $('#course_filter_search input').on('keyup', function() {
                courseTable.fnFilter($(this).val());
            });

            $('#term_select').on('change', function() {
                var url = '/sfu/stats/courses/' + $(this).val() + '.json';
                courseTable.fnReloadAjax(url);
            });


            $('#course_filters input[type=checkbox]').trigger('change')
        };
    });
})();