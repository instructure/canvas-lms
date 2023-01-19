# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

config = ConfigFile.load("marginalia") || {}

if config[:components].present?
  require "marginalia"
  Marginalia::Railtie.insert

  module Marginalia
    module Comment
      class << self
        attr_accessor :migration, :rake_task

        def context_id
          RequestContext::Generator.request_id
        end

        def job_tag
          Delayed::Worker.current_job&.tag
        end
      end
    end
  end

  Marginalia::Comment.components = config[:components].map(&:to_sym)
  Marginalia::Comment.prepend_comment = true

  module Marginalia::RakeTask
    def execute(args = nil)
      previous, Marginalia::Comment.rake_task = Marginalia::Comment.rake_task, name
      super
    ensure
      Marginalia::Comment.rake_task = previous
    end
  end

  Rake::Task.prepend(Marginalia::RakeTask)
end
