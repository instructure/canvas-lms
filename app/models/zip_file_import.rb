#
# Copyright (C) 2011 Instructure, Inc.
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

class ZipFileImport < ActiveRecord::Base
  attr_accessible :attachment, :folder, :context
  include Workflow

  belongs_to :attachment
  belongs_to :folder
  belongs_to :context, :polymorphic => true
  validates_inclusion_of :context_type, :allow_nil => true, :in => ['Group', 'User', 'Course']
  validates_presence_of :context

  serialize :data

  set_policy do
    given { |user| self.context.try(:grants_right?, user, :manage_files) }
    can :read
  end

  workflow do
    state :created
    state :importing
    state :imported
    state :failed
  end

  def download_zip
    if self.data[:file_path]
      File.open(self.data[:file_path], 'rb')
    else
      self.attachment.open(:need_local_file => true)
    end
  end

  def process
    self.workflow_state = :importing
    self.progress = 0
    self.data ||= {}
    self.save

    zipfile = download_zip

    update_progress_proc = Proc.new do |pct|
      if self.updated_at < 2.seconds.ago || pct == 1.0
        self.update_attribute(:progress, pct)
      end
    end

    UnzipAttachment.process(
      :context => self.context,
      :root_directory => self.folder,
      :filename => zipfile.path,
      :callback => update_progress_proc
    )

    zipfile.close
    zipfile = nil

    self.workflow_state = :imported
    self.save
  rescue => e
    ErrorReport.log_exception(:zip_file_import, e)

    self.data[:error_message] = e.to_s
    self.data[:stack_trace] = "#{e.to_s}\n#{e.backtrace.join("\n")}"
    self.workflow_state = "failed"
    self.save
  end
  handle_asynchronously :process, :strand => proc { |zip_file_import| Shard.birth.activate { "zip_file_import:#{zip_file_import.context.asset_string}" } }
end
