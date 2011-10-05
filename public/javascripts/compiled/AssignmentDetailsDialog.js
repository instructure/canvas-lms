(function() {
  var __hasProp = Object.prototype.hasOwnProperty;
  I18n.scoped('AssignmentDetailsDialog', function(I18n) {
    return this.AssignmentDetailsDialog = (function() {
      function AssignmentDetailsDialog(assignment, gradebook) {
        var idx, locals, scores, student, tally, totalWidth, width;
        this.assignment = assignment;
        this.gradebook = gradebook;
        scores = (function() {
          var _ref, _ref2, _results;
          _ref = this.gradebook.students;
          _results = [];
          for (idx in _ref) {
            if (!__hasProp.call(_ref, idx)) continue;
            student = _ref[idx];
            if (((_ref2 = student["assignment_" + this.assignment.id]) != null ? _ref2.score : void 0) != null) {
              _results.push(student["assignment_" + this.assignment.id].score);
            }
          }
          return _results;
        }).call(this);
        locals = {
          assignment: this.assignment,
          cnt: scores.length,
          max: Math.max.apply(Math, scores),
          min: Math.min.apply(Math, scores),
          average: (function(scores) {
            var score, total, _i, _len;
            total = 0;
            for (_i = 0, _len = scores.length; _i < _len; _i++) {
              score = scores[_i];
              total += score;
            }
            return Math.round(total / scores.length);
          })(scores)
        };
        tally = 0;
        width = 0;
        totalWidth = 100;
        $.extend(locals, {
          showDistribution: locals.average && this.assignment.points_possible,
          noneLeftWidth: width = totalWidth * (locals.min / this.assignment.points_possible),
          noneLeftLeft: (tally += width) - width,
          someLeftWidth: width = totalWidth * ((locals.average - locals.min) / this.assignment.points_possible),
          someLeftLeft: (tally += width) - width,
          someRightWidth: width = totalWidth * ((locals.max - locals.average) / this.assignment.points_possible),
          someRightLeft: (tally += width) - width,
          noneRightWidth: width = totalWidth * ((this.assignment.points_possible - locals.max) / this.assignment.points_possible),
          noneRightLeft: (tally += width) - width
        });
        $(Template('AssignmentDetailsDialog', locals)).dialog({
          width: 375,
          close: function() {
            return $(this).remove();
          }
        });
      }
      return AssignmentDetailsDialog;
    })();
  });
}).call(this);
