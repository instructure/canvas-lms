(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  this.AssignmentGroupWeightsDialog = (function() {
    function AssignmentGroupWeightsDialog(options) {
      this.afterSave = __bind(this.afterSave, this);
      this.save = __bind(this.save, this);
      this.calcTotal = __bind(this.calcTotal, this);
      this.update = __bind(this.update, this);
      this.render = __bind(this.render, this);      this.$dialog = $(Template('AssignmentGroupWeightsDialog'));
      this.$dialog.dialog({
        autoOpen: false,
        resizable: false,
        width: 350,
        buttons: [
          {
            text: this.$dialog.find('button[type=submit]').hide().text(),
            click: this.save
          }
        ]
      });
      this.$dialog.delegate('input', 'change keyup keydown input', this.calcTotal);
      this.$dialog.find('#group_weighting_scheme').change(__bind(function(event) {
        var disable;
        disable = !event.currentTarget.checked;
        this.$dialog.find('table').css('opacity', disable ? 0.5 : 1);
        return this.$dialog.find('.assignment_group_row input').attr('disabled', disable);
      }, this));
      this.$group_template = this.$dialog.find('.assignment_group_row.blank').removeClass('blank').detach().show();
      this.$groups_holder = this.$dialog.find('.groups_holder');
      this.update(options);
    }
    AssignmentGroupWeightsDialog.prototype.render = function() {
      var group, uniqueId, _i, _len, _ref;
      this.$groups_holder.empty();
      _ref = this.options.assignmentGroups;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        group = _ref[_i];
        uniqueId = "assignment_group_" + group.id + "_weight";
        this.$group_template.clone().data('assignment_group', group).find('label').attr('for', uniqueId).text(group.name).end().find('input').attr('id', uniqueId).val(group.group_weight).end().appendTo(this.$groups_holder);
      }
      this.$dialog.find('#group_weighting_scheme').prop('checked', this.options.context.group_weighting_scheme === 'percent').change();
      return this.calcTotal();
    };
    AssignmentGroupWeightsDialog.prototype.update = function(newOptions) {
      this.options = newOptions;
      return this.render();
    };
    AssignmentGroupWeightsDialog.prototype.calcTotal = function() {
      var total;
      total = 0;
      this.$dialog.find('.assignment_group_row input').each(function() {
        return total += Number($(this).val());
      });
      return this.$dialog.find('.total_weight').text(total);
    };
    AssignmentGroupWeightsDialog.prototype.save = function() {
      var courseUrl, newGroupWeightingScheme, promise, requests;
      courseUrl = "/courses/" + this.options.context.context_id;
      requests = [];
      newGroupWeightingScheme = this.$dialog.find('#group_weighting_scheme').is(':checked') ? 'percent' : 'equal';
      if (newGroupWeightingScheme !== this.options.context.group_weighting_scheme) {
        requests.push($.ajaxJSON(courseUrl, 'PUT', {
          'course[group_weighting_scheme]': newGroupWeightingScheme
        }, __bind(function(data) {
          return this.options.context.group_weighting_scheme = data.course.group_weighting_scheme;
        }, this)));
      }
      this.$dialog.find('.assignment_group_row').each(function(i, row) {
        var group, newWeight;
        group = $(row).data('assignment_group');
        newWeight = Number($(row).find('input').val());
        if (newWeight !== group.group_weight) {
          return requests.push($.ajaxJSON("" + courseUrl + "/assignments/" + group.id, 'PUT', {
            'assignment_group[group_weight]': newWeight
          }, function(data) {
            return $.extend(group, data.assignment_group);
          }));
        }
      });
      promise = $.when.apply($, requests).done(this.afterSave);
      return this.$dialog.disableWhileLoading(promise, {
        buttons: ['.ui-button-text']
      });
    };
    AssignmentGroupWeightsDialog.prototype.afterSave = function() {
      this.$dialog.dialog('close');
      this.render();
      return $.publish('assignment_group_weights_changed', this.options);
    };
    return AssignmentGroupWeightsDialog;
  })();
}).call(this);
