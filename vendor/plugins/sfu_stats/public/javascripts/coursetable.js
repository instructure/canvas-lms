/* jshint indent:4, camelcase:false, laxcomma:false */
(function() {
    define(['jquery', 'sfu_stats/vendor/jquery.dataTables'], function() {
        return function() {
            var cols = {
                id: 0,
                sis_source_id: 1,
                name: 2,
                course_code: 3,
                workflow_state: 4,
                account_id: 5
            };
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
                    { bVisible: false, aTargets: [cols.id, cols.sis_source_id, cols.account_id] },
                    {
                        mData: function(data) { return { id: data[cols.id], name: data[cols.name] }; },
                        mRender: function(data) {
                            return '<a href="/courses/' + data.id + '">' + data.name + '</a>';
                        },
                        aTargets: [cols.name]
                    }
                ],
                aaSorting: [[cols.workflow_state, 'asc'], [cols.name, 'asc']],
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
                    filter.push('^' + this.value);
                });
                courseTable.fnFilter(filter.join('|'), cols.workflow_state, true);
            });

            $('.checkbox-credit-only, .checkbox-exclude-webct').on('change', function() {
                var el = $(this);
                var checked = el.is(':checked');
                var data = el.data();
                var filter = checked ? data.filter_checked : (data.filter_unchecked || '');
                courseTable.fnFilter(filter, cols[data.col], data.regex);
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