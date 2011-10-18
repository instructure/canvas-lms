(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  I18n.scoped('AssignmentMuter', function(I18n) {
    return this.AssignmentMuter = (function() {
      function AssignmentMuter($link, assignment, url) {
        this.$link = $link;
        this.assignment = assignment;
        this.url = url;
        this.confirmUnmute = __bind(this.confirmUnmute, this);
        this.afterUpdate = __bind(this.afterUpdate, this);
        this.showDialog = __bind(this.showDialog, this);
        this.updateLink = __bind(this.updateLink, this);
        this.$link = $(this.$link);
        this.updateLink();
        this.$link.click(__bind(function(event) {
          event.preventDefault();
          if (this.assignment.muted) {
            return this.confirmUnmute();
          } else {
            return this.showDialog();
          }
        }, this));
      }
      AssignmentMuter.prototype.updateLink = function() {
        return this.$link.text(this.assignment.muted ? I18n.t('unmute_assignment', 'Unmute Assignment') : I18n.t('mute_assignment', 'Mute Assignment'));
      };
      AssignmentMuter.prototype.showDialog = function() {
        return this.$dialog = $(Template('mute_dialog')).dialog({
          buttons: [
            {
              text: I18n.t('mute_assignment', 'Mute Assignment'),
              'data-text-while-loading': I18n.t('muting_assignment', 'Muting Assignment...'),
              click: __bind(function() {
                return this.$dialog.disableWhileLoading($.ajaxJSON(this.url, 'put', {
                  status: true
                }, this.afterUpdate));
              }, this)
            }
          ],
          close: __bind(function() {
            return this.$dialog.remove();
          }, this),
          resizable: false,
          width: 400
        });
      };
      AssignmentMuter.prototype.afterUpdate = function(serverResponse) {
        this.assignment.muted = serverResponse.assignment.muted;
        this.updateLink();
        this.$dialog.dialog('close');
        return $.publish('assignment_muting_toggled', [this.assignment]);
      };
      AssignmentMuter.prototype.confirmUnmute = function() {
        return this.$dialog = $('<div />').text(I18n.t('unmute_dialog', "This assignment is currently muted. That means students can't see their grades and feedback. Would you like to unmute now?")).dialog({
          buttons: [
            {
              text: I18n.t('unmute_button', 'Unmute Assignment'),
              'data-text-while-loading': I18n.t('unmuting_assignment', 'Unmuting Assignment...'),
              click: __bind(function() {
                return this.$dialog.disableWhileLoading($.ajaxJSON(this.url, 'put', {
                  status: false
                }, this.afterUpdate));
              }, this)
            }
          ],
          close: __bind(function() {
            return this.$dialog.remove();
          }, this),
          resizable: false,
          title: I18n.t("unmute_assignment", "Unmute Assignment"),
          width: 400
        });
      };
      return AssignmentMuter;
    })();
  });
}).call(this);
