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

class EportfolioCategory < ActiveRecord::Base
  attr_accessible :name
  attr_readonly :eportfolio_id

  has_many :eportfolio_entries, :order => :position, :dependent => :destroy
  belongs_to :eportfolio

  EXPORTABLE_ATTRIBUTES = [:id, :eportfolio_id, :name, :position, :slug, :created_at, :updated_at]
  EXPORTABLE_ASSOCIATIONS = [:eportfolio_entries, :eportfolio]

  before_save :infer_unique_slug
  validates_presence_of :eportfolio_id
  validates_length_of :name, :maximum => maximum_string_length, :allow_blank => true

  acts_as_list :scope => :eportfolio
  
  def infer_unique_slug
    categories = self.eportfolio.eportfolio_categories
    self.name ||= t(:default_section, "Section Name")
    self.slug = self.name.gsub(/[\s]+/, "_").gsub(/[^\w\d]/, "")
    categories = categories.where("id<>?", self) unless self.new_record?
    match_cnt = categories.where(:slug => self.slug).count
    if match_cnt > 0
      self.slug = self.slug + "_" + (match_cnt + 1).to_s
    end
  end
  protected :infer_unique_slug
end
