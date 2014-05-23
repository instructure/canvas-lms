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


    utils.onPage(/^\/courses\/\d+\/users$/, function() {
        // remove everything except Contributor and Moderator roles from enrollment options
        function removeUnusedRoles(index) {
            var $this = $(this);
            var val = $this.val();
            if (!(val === '' || val === 'Contributor' || val === 'Moderator')) {
              $this.remove()
            }
        }

        utils.onElementRendered('#content>div', function() {
            $('select[name="enrollment_role"] option, #enrollment_type option').each(removeUnusedRoles);
        });
        utils.onElementRendered('#addUsers', function() {
            $('#addUsers').on('click', function(ev) {
                $('#enrollment_type option').each(removeUnusedRoles);
                $('#privileges').remove();
            });
        });


        // remove last activity column from roster table
        utils.onElementRendered('table.roster', function() {
            var $userTable = $('table.roster');
            $userTable.find('thead th').get(-1-1).remove();
            $userTable.find('tbody tr').each(function() {
                $(this).find('td').get(-1-1).remove();
            });
        });
    });

})(jQuery);