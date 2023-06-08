# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
  attr_readonly :eportfolio_id

  has_many :eportfolio_entries, -> { ordered }, dependent: :destroy
  belongs_to :eportfolio

  before_save :infer_unique_slug
  after_save :check_for_spam, if: -> { eportfolio.needs_spam_review? }

  validates :eportfolio_id, presence: true
  validates :name, length: { maximum: maximum_string_length, allow_blank: true }

  acts_as_list scope: :eportfolio

  def infer_unique_slug
    categories = eportfolio.eportfolio_categories
    self.name ||= t(:default_section, "Section Name")
    self.slug = self.name.gsub(/\s+/, "_").gsub(/[^\w\d]/, "")
    categories = categories.where("id<>?", self) unless new_record?
    match_cnt = categories.where(slug:).count
    if match_cnt > 0
      self.slug = slug + "_" + (match_cnt + 1).to_s
    end
  end
  protected :infer_unique_slug

  private

  def check_for_spam
    eportfolio.flag_as_possible_spam! if eportfolio.title_contains_spam?(name)
  end
end
