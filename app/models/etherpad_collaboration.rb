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

class EtherpadCollaboration < Collaboration

  def service_name
    "EtherPad"
  end

  def style_class
    'etherpad'
  end

  # Etherpad embed query parameters
  # This information may be useful, but is kind of hard to find anymore
  # fullScreen=1 (or 0)           uses full window width
  # sidebar=0                     hides the sidebar
  # slider=0                      hides the slider in slider view
  # displayName=name              sets the user's name for the pad
  # /ep/pad/view/PAD_ID/latest  read-only view (still reveals pad id)

  def initialize_document
    self.url ||= "http://#{EtherpadCollaboration.config[:domain]}/i-#{self.uuid}"
  end

  def user_can_access_document_type?(user)
    true
  end

  def self.config
    Canvas::Plugin.find(:etherpad).try(:settings) || (YAML.load_file(Rails.root+"config/etherpad.yml")[Rails.env] rescue nil)
  end
end
