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

InstStatsd::DefaultTracking.track_sql
InstStatsd::DefaultTracking.track_active_record
InstStatsd::DefaultTracking.track_cache
InstStatsd::DefaultTracking.track_jobs(enable_periodic_queries: false)
InstJobsStatsd::Naming.configure(strand_filter: ->(job) { DelayedJobConfig.strands_to_send_to_statsd.include?(job.strand) })
InstStatsd::BlockTracking.logger = InstStatsd::RequestLogger.new(Rails.logger)
InstStatsd::RequestTracking.enable logger: Rails.logger
