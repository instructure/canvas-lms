(function() {
  $(document).ready(function() {
    var has_user_notes, params;
    $.tablesorter.addParser({
      id: 'days_or_never',
      is: function() {
        return false;
      },
      format: function(s) {
        var str, val;
        str = $.trim(s);
        val = parseInt(str, 10) || 0;
        return -1 * (str === 'never' ? Number.MAX_VALUE : val);
      },
      type: 'number'
    });
    $.tablesorter.addParser({
      id: 'data-number',
      is: function() {
        return false;
      },
      format: function(s, table, td) {
        return $(td).attr('data-number');
      },
      type: 'number'
    });
    has_user_notes = $(".report").hasClass('has_user_notes');
    params = {
      headers: {
        0: {
          sorter: 'data-number'
        },
        1: {
          sorter: 'days_or_never'
        }
      }
    };
    if (has_user_notes) {
      params['headers'][2] = {
        sorter: 'days_or_never'
      };
    }
    params['headers'][4 + (has_user_notes != null ? has_user_notes : {
      1: 0
    })] = {
      sorter: 'data-number'
    };
    params['headers'][5 + (has_user_notes != null ? has_user_notes : {
      1: 0
    })] = {
      sorter: false
    };
    return $(".report").tablesorter(params);
  });
}).call(this);
