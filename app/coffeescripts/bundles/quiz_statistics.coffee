require [
  'jquery'
  'compiled/models/QuizReport'
  'compiled/views/quiz_reports/QuizReportGenerator'
  'quiz_statistics' # all the old crap
], ($, QuizReport, QuizReportGenerator) ->

  $container = $('.quiz-reports')
  for report in ENV.quiz_reports
    el = $('<div>').appendTo($container)
    # need to alias this attribute to preserve the translations
    report.report_name = report.readable_type
    model = new QuizReport(report)
    new QuizReportGenerator({el, model}).render()

