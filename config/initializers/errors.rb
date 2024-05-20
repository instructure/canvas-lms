# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

# This initializer registers the two interal tools canvas uses
# for tracking errors.  One (:error_report) creates a record in the
# error_reports database table for each exception that occurs.  The
# other (:error_stats) will send two counter increments to statsd,
# one for "all" which tabulates every error that occurs, and one
# that includes the class of the exception in the key so you
# can see big spikes in a certain kind of error.  Either can be
# disabled individually with a setting.
#
Rails.configuration.to_prepare do
  ErrorReport.configure_to_ignore(%w[
                                    AuthenticationMethods::AccessTokenError
                                    ActionController::InvalidAuthenticityToken
                                    Turnitin::Errors::SubmissionNotScoredError
                                    ActionController::ParameterMissing
                                    SearchTermHelper::SearchTermTooShortError
                                  ])

  # write a database record to our application DB capturing useful info for looking
  # at this error later
  CanvasErrors.register!(:error_report) do |exception, data, level|
    if level == :error
      report = ErrorReport.log_exception_from_canvas_errors(exception, data)
      report.try(:global_id)
    end
  end

  # keep track of incidence rates for errors we might not send
  # to the DB or to sentry (e.g. we expect auth errors to happen,
  # but if they spike we want to see that in a dashboard and maybe
  # even have a monitor fire)
  CanvasErrors.register!(:error_stats) do |exception, data, level|
    Canvas::ErrorStats.capture(exception, data, level)
  end

  # output full error stack trace and context to log files
  CanvasErrors.register!(:logging) do |exception, data, level|
    Canvas::Errors::LogEntry.write(exception, data, level)
  end
end
