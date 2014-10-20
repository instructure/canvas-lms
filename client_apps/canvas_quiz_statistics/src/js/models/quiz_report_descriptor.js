define(function(require) {
  var I18n = require('i18n!quiz_reports');
  var DateTimeHelpers = require('../util/date_time_helpers');

  var STUDENT_ANALYSIS = 'student_analysis';
  var ITEM_ANALYSIS = 'item_analysis';
  var friendlyDatetime = DateTimeHelpers.friendlyDatetime;
  var fudgeDateForProfileTimezone = DateTimeHelpers.fudgeDateForProfileTimezone;

  return {
    getInteractionLabel: function(report) {
      var label;
      var type = report.reportType;

      if (report.isGenerated) {
        if (type === STUDENT_ANALYSIS) {
          label = I18n.t('download_student_analysis',
            'Download student analysis report.');
        } else if (type === ITEM_ANALYSIS) {
          label = I18n.t('download_item_analysis',
            'Download item analysis report.');
        }
      }
      else {
        if (type === STUDENT_ANALYSIS) {
          label = I18n.t('generate_student_analysis_report',
            'Generate student analysis report.');
        }
        else if (type === ITEM_ANALYSIS) {
          label = I18n.t('generate_item_analysis_report',
            'Generate item analysis report.');
        }
      }

      return label;
    },

    getDetailedStatusLabel: function(report, justBeenGenerated) {
      var generatedAt, completion, label;

      if (!report.generatable) {
        label = I18n.t('non_generatable_report_notice',
          'Report can not be generated for Survey Quizzes.');
      }
      else if (report.isGenerated) {
        generatedAt = friendlyDatetime(fudgeDateForProfileTimezone(report.file.createdAt));

        if (justBeenGenerated) {
          label = I18n.t('generation_complete', 'Report has been generated.');
        }
        else {
          label = I18n.t('generated_at', 'Generated: %{date}', {
            date: generatedAt
          });
        }
      }
      else if (report.isGenerating) {
        completion = report.progress.completion;

        if (completion < 50) {
          label = I18n.t('generation_started', 'Report is being generated.');
        }
        else if (completion < 75) {
          label = I18n.t('generation_halfway', 'Less than half-way to go.');
        }
        else {
          label = I18n.t('generation_almost_done', 'Almost done.');
        }
      } else {
        label = I18n.t('generatable', 'Report has never been generated.');
      }

      return label;
    }
  };
});