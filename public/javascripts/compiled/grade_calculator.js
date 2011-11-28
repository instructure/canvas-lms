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
      var assignment, data, dropped, lowOrHigh, rules, s, submission, sum, _i, _j, _k, _l, _len, _len2, _len3, _len4, _len5, _m, _ref, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8;
      sum = {
        submissions: [],
        score: 0,
        possible: 0,
        submission_count: 0
      };
      _ref = group.assignments;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        assignment = _ref[_i];
        data = {
          score: 0,
          possible: 0,
          percent: 0,
          drop: false,
          submitted: false
        };
        submission = $.detect(submissions, function() {
          return this.assignment_id === assignment.id;
        });
        if (submission == null) {
          submission = {
            score: null
          };
        }
        submission.assignment_group_id = group.id;
        if ((_ref2 = submission.points_possible) == null) {
          submission.points_possible = assignment.points_possible;
        }
        data.submission = submission;
        sum.submissions.push(data);
        if (!(ignore_ungraded && (!(submission.score != null) || submission.score === ''))) {
          data.score = this.parse(submission.score);
          data.possible = this.parse(assignment.points_possible);
          data.percent = this.parse(data.score / data.possible);
          data.submitted = (submission.score != null) && submission.score !== '';
          if (data.submitted) {
            sum.submission_count += 1;
          }
        }
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
      _ref3 = ['low', 'high'];
      for (_j = 0, _len2 = _ref3.length; _j < _len2; _j++) {
        lowOrHigh = _ref3[_j];
        _ref4 = sum.submissions;
        for (_k = 0, _len3 = _ref4.length; _k < _len3; _k++) {
          data = _ref4[_k];
          if (!data.drop && rules["drop_" + lowOrHigh + "est"] > 0 && $.inArray(data.assignment_id, rules.never_drop) === -1 && data.possible > 0 && data.submitted) {
            data.drop = true;
            if ((_ref5 = data.submission) != null) {
              _ref5.drop = true;
            }
            rules["drop_" + lowOrHigh + "est"] -= 1;
            dropped += 1;
          }
        }
      }
      if (dropped > 0 && dropped === sum.submission_count) {
        sum.submissions[sum.submissions.length - 1].drop = false;
        if ((_ref6 = sum.submissions[sum.submissions.length - 1].submission) != null) {
          _ref6.drop = false;
        }
        dropped -= 1;
      }
      sum.submission_count -= dropped;
      _ref7 = sum.submissions;
      for (_l = 0, _len4 = _ref7.length; _l < _len4; _l++) {
        s = _ref7[_l];
        if (!s.drop) {
          sum.score += s.score;
        }
      }
      _ref8 = sum.submissions;
      for (_m = 0, _len5 = _ref8.length; _m < _len5; _m++) {
        s = _ref8[_m];
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
    GradeCalculator.letter_grade = function(grading_scheme, score) {
      var letter, letters;
      if (score < 0) {
        score = 0;
      }
      letters = $.grep(grading_scheme, function(row, i) {
        return score >= row[1] * 100 || i === (grading_scheme.length - 1);
      });
      letter = letters[0];
      return letter[0];
    };
    return GradeCalculator;
  })();
  window.INST.GradeCalculator = GradeCalculator;
}).call(this);
