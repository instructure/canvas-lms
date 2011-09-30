(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  I18n.scoped('gradebook2', function(I18n) {
    return this.CurveGradesDialog = (function() {
      function CurveGradesDialog(assignment, gradebook) {
        var locals;
        this.assignment = assignment;
        this.gradebook = gradebook;
        this.curve = __bind(this.curve, this);
        locals = {
          assignment: this.assignment,
          action: "" + this.gradebook.options.context_url + "/gradebook/update_submission",
          middleScore: parseInt((this.assignment.points_possible || 0) * 0.6),
          showOutOf: this.assignment.points_possible >= 0
        };
        this.$dialog = $(Template('CurveGradesDialog', locals));
        this.$dialog.formSubmit({
          disableWhileLoading: true,
          processData: __bind(function(data) {
            var cnt, curves, idx, pre;
            cnt = 0;
            curves = this.curve();
            for (idx in curves) {
              pre = "submissions[submission_" + idx + "]";
              data[pre + "[assignment_id]"] = data.assignment_id;
              data[pre + "[user_id]"] = idx;
              data[pre + "[grade]"] = curves[idx];
              cnt++;
            }
            if (cnt === 0) {
              this.$dialog.errorBox(I18n.t("errors.none_to_update", "None to Update"));
              return false;
            }
            return data;
          }, this),
          success: __bind(function(data) {
            var datum, submissions;
            this.$dialog.dialog('close');
            submissions = (function() {
              var _i, _len, _results;
              _results = [];
              for (_i = 0, _len = data.length; _i < _len; _i++) {
                datum = data[_i];
                _results.push(datum.submission);
              }
              return _results;
            })();
            $.publish('submissions_updated', [submissions]);
            return alert(I18n.t("alerts.scores_updated", {
              one: "1 Student score updated",
              other: "%{count} Student scores updated"
            }, {
              count: data.length
            }));
          }, this)
        }).dialog({
          width: 350,
          modal: true,
          resizable: false,
          open: this.curve,
          close: __bind(function() {
            return this.$dialog.remove();
          }, this)
        }).fixDialogButtons();
        this.$dialog.find("#middle_score").bind("blur change keyup focus", this.curve);
        this.$dialog.find("#assign_blanks").change(this.curve);
      }
      CurveGradesDialog.prototype.curve = function() {
        var breakPercents, breakScores, breaks, cnt, color, currentBreak, data, finalScore, finalScores, final_users_for_score, idx, interval, jdx, maxCount, middleScore, pct, score, scoreCount, scores, skipCount, student, tally, user, users, users_for_score, width, _ref;
        idx = 0;
        scores = {};
        data = this.$dialog.getFormData();
        users_for_score = [];
        scoreCount = 0;
        middleScore = parseInt($("#middle_score").val(), 10);
        middleScore = middleScore / this.assignment.points_possible;
        if (isNaN(middleScore)) {
          return;
        }
        _ref = this.gradebook.students;
        for (idx in _ref) {
          student = _ref[idx];
          score = student["assignment_" + this.assignment.id].score;
          if (score > this.assignment.points_possible) {
            score = this.assignment.points_possible;
          }
          if (score < 0) {
            score = 0;
          }
          users_for_score[parseInt(score, 10)] = users_for_score[parseInt(score, 10)] || [];
          users_for_score[parseInt(score, 10)].push([idx, score || 0]);
          scoreCount++;
        }
        breaks = [0.006, 0.012, 0.028, 0.040, 0.068, 0.106, 0.159, 0.227, 0.309, 0.401, 0.500, 0.599, 0.691, 0.773, 0.841, 0.894, 0.933, 0.960, 0.977, 0.988, 1.000];
        interval = (1.0 - middleScore) / Math.floor(breaks.length / 2);
        breakScores = [];
        breakPercents = [];
        idx = 0;
        while (idx < breaks.length) {
          breakPercents.push(1.0 - (interval * idx));
          breakScores.push(Math.round((1.0 - (interval * idx)) * this.assignment.points_possible));
          idx++;
        }
        tally = 0;
        finalScores = {};
        currentBreak = 0;
        $("#results_list").empty();
        $("#results_values").empty();
        final_users_for_score = [];
        idx = users_for_score.length - 1;
        while (idx >= 0) {
          users = users_for_score[idx] || [];
          score = Math.round(breakScores[currentBreak]);
          for (jdx in users) {
            user = users[jdx];
            finalScores[user[0]] = score;
            if (user[1] === 0) {
              finalScores[user[0]] = 0;
            }
            finalScore = finalScores[user[0]];
            final_users_for_score[finalScore] = final_users_for_score[finalScore] || [];
            final_users_for_score[finalScore].push(user[0]);
          }
          tally += users.length;
          while (tally > (breaks[currentBreak] * scoreCount)) {
            currentBreak++;
          }
          idx--;
        }
        maxCount = 0;
        idx = final_users_for_score.length - 1;
        while (idx >= 0) {
          cnt = (final_users_for_score[idx] || []).length;
          if (cnt > maxCount) {
            maxCount = cnt;
          }
          idx--;
        }
        width = 15;
        skipCount = 0;
        idx = final_users_for_score.length - 1;
        while (idx >= 0) {
          users = final_users_for_score[idx];
          pct = 0;
          cnt = 0;
          if (users || skipCount > (this.assignment.points_possible / 10)) {
            if (users) {
              pct = users.length / maxCount;
              cnt = users.length;
            }
            color = (idx === 0 ? "#ee8" : "#cdf");
            $("#results_list").prepend("<td style='padding: 1px;'><div title='" + cnt + " student" + (cnt === 1 ? "" : "s") + " will get " + idx + " points' style='border: 1px solid #888; background-color: " + color + "; width: " + width + "px; height: " + (100 * pct) + "px; margin-top: " + (100 * (1 - pct)) + "px;'>&nbsp;</div></td>");
            $("#results_values").prepend("<td style='text-align: center;'>" + idx + "</td>");
            skipCount = 0;
          } else {
            skipCount++;
          }
          idx--;
        }
        $("#results_list").prepend("<td><div style='height: 100px; position: relative; width: 30px; font-size: 0.8em;'><img src='/images/number_of_students.png' alt='# of students'/><div style='position: absolute; top: 0; right: 3px;'>" + maxCount + "</div><div style='position: absolute; bottom: 0; right: 3px;'>0</div></div></td>");
        $("#results_values").prepend("<td>&nbsp;</td>");
        return finalScores;
      };
      return CurveGradesDialog;
    })();
  });
}).call(this);
