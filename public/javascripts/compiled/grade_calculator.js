(function() {
  var GradeCalculator;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  GradeCalculator = (function() {
    function GradeCalculator() {}
    GradeCalculator.calculate = function(submissions, groups, weighting_scheme) {
      var result;
      result = {};
      result.group_sums = $.map(groups, __bind(function(group) {
        return {
          group: group,
          current: this.create_group_sum(group, submissions, true),
          'final': this.create_group_sum(group, submissions, false)
        };
      }, this));
      result.current = this.calculate_total(result.group_sums, true, weighting_scheme);
      result['final'] = this.calculate_total(result.group_sums, false, weighting_scheme);
      return result;
    };
    GradeCalculator.create_group_sum = function(group, submissions, ignore_ungraded) {
      var data, dropped, lowOrHigh, rules, s, submission, sum, _fn, _i, _j, _k, _l, _len, _len2, _len3, _len4, _len5, _m, _ref, _ref2, _ref3, _ref4, _ref5, _ref6;
      sum = {
        submissions: [],
        score: 0,
        possible: 0,
        submission_count: 0
      };
      _fn = __bind(function(submission) {
        var assignment, data, _ref;
        if (!submission.assignment_group_id) {
          assignment = $.detect(group.assignments, function() {
            return submission.assignment_id === this.id;
          });
          if (assignment) {
            submission.assignment_group_id = group.id;
                        if ((_ref = submission.points_possible) != null) {
              _ref;
            } else {
              submission.points_possible = assignment != null ? assignment.points_possible : void 0;
            };
          }
        }
        if (submission.assignment_group_id === group.id) {
          data = {
            submission: submission,
            score: 0,
            possible: 0,
            percent: 0,
            drop: false,
            submitted: false
          };
          sum.submissions.push(data);
          if (!(ignore_ungraded && (!submission.score || submission.score === ''))) {
            data.score = this.parse(submission.score);
            data.possible = this.parse(submission.points_possible);
            data.percent = this.parse(data.score / data.possible);
            data.submitted = submission.score && submission.score !== '';
            if (data.submitted) {
              return sum.submission_count += 1;
            }
          }
        }
      }, this);
      for (_i = 0, _len = submissions.length; _i < _len; _i++) {
        submission = submissions[_i];
        _fn(submission);
      }
      sum.submissions.sort(function(a, b) {
        return a.percent - b.percent;
      });
      rules = $.extend({
        drop_lowest: 0,
        drop_highest: 0,
        never_drop: []
      }, group.rules);
      dropped = 0;
      _ref = ['low', 'high'];
      for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
        lowOrHigh = _ref[_j];
        _ref2 = sum.submissions;
        for (_k = 0, _len3 = _ref2.length; _k < _len3; _k++) {
          data = _ref2[_k];
          if (!data.drop && rules["drop_" + lowOrHigh + "est"] > 0 && $.inArray(data.assignment_id, rules.never_drop) === -1 && data.possible > 0 && data.submitted) {
            data.drop = true;
            if ((_ref3 = data.submission) != null) {
              _ref3.drop = true;
            }
            rules["drop_" + lowOrHigh + "est"] -= 1;
            dropped += 1;
          }
        }
      }
      if (dropped > 0 && dropped === sum.submission_count) {
        sum.submissions[sum.submissions.length - 1].drop = false;
        if ((_ref4 = sum.submissions[sum.submissions.length - 1].submission) != null) {
          _ref4.drop = false;
        }
        dropped -= 1;
      }
      sum.submission_count -= dropped;
      _ref5 = sum.submissions;
      for (_l = 0, _len4 = _ref5.length; _l < _len4; _l++) {
        s = _ref5[_l];
        if (!s.drop) {
          sum.score += s.score;
        }
      }
      _ref6 = sum.submissions;
      for (_m = 0, _len5 = _ref6.length; _m < _len5; _m++) {
        s = _ref6[_m];
        if (!s.drop) {
          sum.possible += s.possible;
        }
      }
      return sum;
    };
    GradeCalculator.calculate_total = function(group_sums, ignore_ungraded, weighting_scheme) {
      var data, data_idx, possible, possible_weight_from_submissions, score, tally, total_possible_weight, _i, _len;
      data_idx = ignore_ungraded ? 'current' : 'final';
      if (weighting_scheme === 'percent') {
        score = 0.0;
        possible_weight_from_submissions = 0.0;
        total_possible_weight = 0.0;
        for (_i = 0, _len = group_sums.length; _i < _len; _i++) {
          data = group_sums[_i];
          if (data.group.group_weight > 0) {
            if (data[data_idx].submission_count > 0) {
              tally = data[data_idx].score / data[data_idx].possible;
              score += data.group.group_weight * tally;
              possible_weight_from_submissions += data.group.group_weight;
            }
            total_possible_weight += data.group.group_weight;
          }
        }
        if (ignore_ungraded && possible_weight_from_submissions < 100.0) {
          possible = total_possible_weight < 100.0 ? total_possible_weight : 100.0;
          score = score * possible / possible_weight_from_submissions;
        }
        return {
          score: score,
          possible: 100.0
        };
      } else {
        return {
          score: this.sum((function() {
            var _j, _len2, _results;
            _results = [];
            for (_j = 0, _len2 = group_sums.length; _j < _len2; _j++) {
              data = group_sums[_j];
              _results.push(data[data_idx].score);
            }
            return _results;
          })()),
          possible: this.sum((function() {
            var _j, _len2, _results;
            _results = [];
            for (_j = 0, _len2 = group_sums.length; _j < _len2; _j++) {
              data = group_sums[_j];
              _results.push(data[data_idx].possible);
            }
            return _results;
          })())
        };
      }
    };
    GradeCalculator.sum = function(values) {
      var result, value, _i, _len;
      result = 0;
      for (_i = 0, _len = values.length; _i < _len; _i++) {
        value = values[_i];
        result += value;
      }
      return result;
    };
    GradeCalculator.parse = function(score) {
      var result;
      result = parseFloat(score);
      if (result && isFinite(result)) {
        return result;
      } else {
        return 0;
      }
    };
    return GradeCalculator;
  })();
  window.INST.GradeCalculator = GradeCalculator;
}).call(this);
