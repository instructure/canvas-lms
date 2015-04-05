# This initializer registers the two interal tools canvas uses
# for tracking errors.  One (:error_report) creates a record in the
# error_reports database table for each exception that occurs.  The
# other (:error_stats) will send two counter increments to statsd,
# one for "all" which tabulates every error that occurs, and one
# that includes the class of the exception in the key so you
# can see big spikes in a certain kind of error.  Either can be
# disabled individually with a setting.
#
Canvas::Errors.register!(:error_report) do |exception, data|
  setting = Setting.get("error_report_exception_handling", 'true')
  if setting == 'true'
    report = ErrorReport.log_exception_from_canvas_errors(exception, data)
    report.try(:global_id)
  end
end

Canvas::Errors.register!(:error_stats) do |exception, data|
  setting = Setting.get("collect_error_statistics", 'true')
  Canvas::ErrorStats.capture(exception, data) if setting == 'true'
end
