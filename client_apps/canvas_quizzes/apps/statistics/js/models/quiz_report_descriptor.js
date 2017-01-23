define((require) => {
  const I18n = require('i18n!quiz_reports');
  const DateTimeHelpers = require('canvas_quizzes/util/date_time_helpers');

  const STUDENT_ANALYSIS = 'student_analysis';
  const ITEM_ANALYSIS = 'item_analysis';
  const friendlyDatetime = DateTimeHelpers.friendlyDatetime;
  const fudgeDateForProfileTimezone = DateTimeHelpers.fudgeDateForProfileTimezone;

  return {
    getLabel (reportType) {
      if (reportType === STUDENT_ANALYSIS) {
        return I18n.t('student_analysis', 'Student Analysis');
      } else if (reportType === ITEM_ANALYSIS) {
        return I18n.t('item_analysis', 'Item Analysis');
      }

      return reportType;
    },

    getInteractionLabel (report) {
      let label;
      const type = report.reportType;
      const labelText = '';

      if (report.isGenerated) {
        if (type === STUDENT_ANALYSIS) {
          label = I18n.t('Download student analysis report %{statusLabel}', { statusLabel: this.getDetailedStatusLabel(report) });
        } else if (type === ITEM_ANALYSIS) {
          label = I18n.t('Download item analysis report %{statusLabel}', { statusLabel: this.getDetailedStatusLabel(report) });
        }
      } else if (type === STUDENT_ANALYSIS) {
        label = I18n.t('Generate student analysis report %{statusLabel}', { statusLabel: this.getDetailedStatusLabel(report) });
      } else if (type === ITEM_ANALYSIS) {
        label = I18n.t('Generate item analysis report %{statusLabel}', { statusLabel: this.getDetailedStatusLabel(report) });
      }

      return label;
    },

    getDetailedStatusLabel (report, justBeenGenerated) {
      let generatedAt,
        completion,
        label;

      if (!report.generatable) {
        label = I18n.t('non_generatable_report_notice',
          'Report can not be generated for Survey Quizzes.');
      } else if (report.isGenerated) {
        generatedAt = friendlyDatetime(fudgeDateForProfileTimezone(report.file.createdAt));

        if (justBeenGenerated) {
          label = I18n.t('generation_complete', 'Report has been generated.');
        } else {
          label = I18n.t('generated_at', 'Generated: %{date}', {
            date: generatedAt
          });
        }
      } else if (report.isGenerating) {
        completion = report.progress.completion;

        if (completion < 50) {
          label = I18n.t('generation_started', 'Report is being generated.');
        } else if (completion < 75) {
          label = I18n.t('generation_halfway', 'Less than half-way to go.');
        } else {
          label = I18n.t('generation_almost_done', 'Almost done.');
        }
      } else {
        label = I18n.t('generatable', 'Report has never been generated.');
      }

      return label;
    }
  };
});
