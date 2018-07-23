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

class Eportfolio < ActiveRecord::Base
  include Workflow
  has_many :eportfolio_categories, -> { order(:position) }, dependent: :destroy
  has_many :eportfolio_entries, :dependent => :destroy
  has_many :attachments, :as => :context, :inverse_of => :context

  belongs_to :user
  validates_presence_of :user_id
  validates_length_of :name, :maximum => maximum_string_length, :allow_blank => true

  workflow do
    state :active
    state :deleted
  end

  alias_method :destroy_permanently!, :destroy

  def destroy
    self.workflow_state = 'deleted'
    self.deleted_at = Time.now.utc
    self.save
  end

  scope :active, -> { where("eportfolios.workflow_state<>'deleted'") }

  before_create :assign_uuid
  def assign_uuid
    self.uuid ||= CanvasSlug.generate_securish_uuid
  end
  protected :assign_uuid

  set_policy do
    given {|user| user && user.eportfolios_enabled? }
    can :create

    given {|user| self.active? && self.user == user && user.eportfolios_enabled? }
    can :read and can :manage and can :update and can :delete

    given {|_| self.active? && self.public }
    can :read

    given {|_, session| self.active? && session && session[:eportfolio_ids] && session[:eportfolio_ids].include?(self.id) }
    can :read
  end

  def ensure_defaults
    cat = self.eportfolio_categories.first
    cat ||= self.eportfolio_categories.create!(:name => t(:first_category, "Home"))
    if cat && cat.eportfolio_entries.empty?
      entry = cat.eportfolio_entries.build(:eportfolio => self, :name => t('first_entry.title', "Welcome"))
      entry.content = t('first_entry.content', "Nothing entered yet")
      entry.save!
    end
    cat
  end
  def self.serialization_excludes; [:uuid]; end
end
