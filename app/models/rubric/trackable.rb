# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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
#

class Rubric
  module Trackable
    extend ActiveSupport::Concern

    included do
      before_save :track_metrics
    end

    def track_metrics
      version = context.feature_enabled?(:enhanced_rubrics) ? :enhanced : :old

      if new_record?
        if is_duplicate
          InstStatsd::Statsd.distributed_increment("#{context.class.to_s.downcase}.rubrics.duplicated_#{version}")
        elsif rubric_imports_id.present?
          InstStatsd::Statsd.distributed_increment("#{context.class.to_s.downcase}.rubrics.csv_imported")
        else
          InstStatsd::Statsd.distributed_increment("#{context.class.to_s.downcase}.rubrics.created_#{version}")
        end
      elsif is_manually_update
        InstStatsd::Statsd.distributed_increment("#{context.class.to_s.downcase}.rubrics.updated_#{version}")
      end
    end
  end
end
