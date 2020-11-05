# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module AttachmentFu
  class Railtie < ::Rails::Railtie
    initializer "attachment_fu.canvas_plugin" do
      ActiveRecord::Base.send(:extend, AttachmentFu::ActMethods)
      AttachmentFu::Railtie.setup_tempfile_path
    end

    def self.setup_tempfile_path
      AttachmentFu.tempfile_path = '/tmp/attachment_fu'
      AttachmentFu.tempfile_path = ATTACHMENT_FU_TEMPFILE_PATH if Object.const_defined?(:ATTACHMENT_FU_TEMPFILE_PATH)

      begin
        FileUtils.mkdir_p AttachmentFu.tempfile_path
      rescue Errno::EACCES
        # don't have permission; still let the rest of the app boot
      end
    end
  end
end
