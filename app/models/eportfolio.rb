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

class Eportfolio < ActiveRecord::Base
  include Workflow
  has_many :eportfolio_categories, -> { ordered }, dependent: :destroy
  has_many :eportfolio_entries, dependent: :destroy
  has_many :attachments, as: :context, inverse_of: :context

  after_save :check_for_spam, if: -> { needs_spam_review? }

  belongs_to :user

  SPAM_MODERATIONS = %w[marked_as_safe marked_as_spam].freeze

  validates :user_id, presence: true
  validates :name, length: { maximum: maximum_string_length, allow_blank: true }
  # flagged_as_possible_spam => our internal filters have flagged this as spam, but
  # an admin has not manually marked this as spam.
  # marked_as_safe => an admin has manually marked this as safe.
  # marked_as_spam => an admin has manually marked this as spam.
  validates :spam_status,
            inclusion: ["flagged_as_possible_spam", *SPAM_MODERATIONS],
            allow_nil: true

  workflow do
    state :active
    state :deleted
  end

  alias_method :destroy_permanently!, :destroy

  def destroy
    self.workflow_state = "deleted"
    self.deleted_at = Time.now.utc
    save
  end

  def restore
    self.workflow_state = "active"
    self.deleted_at = nil
    save
  end

  def flagged_as_possible_spam?
    spam_status == "flagged_as_possible_spam"
  end

  def spam?(include_possible_spam: true)
    spam_status == "marked_as_spam" ||
      (include_possible_spam && spam_status == "flagged_as_possible_spam")
  end

  scope :active, -> { where("eportfolios.workflow_state<>'deleted'") }
  scope :deleted, -> { where("eportfolios.workflow_state='deleted'") }
  scope :flagged_or_marked_as_spam,
        -> { where(spam_status: %w[flagged_as_possible_spam marked_as_spam]) }

  before_create :assign_uuid
  def assign_uuid
    self.uuid ||= CanvasSlug.generate_securish_uuid
  end
  protected :assign_uuid

  set_policy do
    given do |user|
      user&.eportfolios_enabled? &&
        !user.eportfolios.active.flagged_or_marked_as_spam.exists? &&
        (user.has_enrollment? || user.account_membership?)
    end
    can :create

    # User is the author and eportfolios are enabled (whether this eportfolio
    # is spam or not, the author can see it and delete it).
    given { |user| active? && self.user == user && user.eportfolios_enabled? }
    can :read and can :delete

    # If an eportfolio has been flagged as possible spam or marked as spam, don't let the author
    # update it. If an admin marks the content as safe, the user will be able to make updates again,
    # but we don't want to let the user make changes before an admin can review the content.
    given { |user| active? && self.user == user && user.eportfolios_enabled? && !spam? }
    can :update and can :manage

    # The eportfolio is public, eportfolios are enabled, and it hasn't been flagged or marked as spam.
    given { |_| active? && public && !spam? && self.user.eportfolios_enabled? }
    can :read

    # The eportfolio is private and the user has access to the private link
    # (we know this by way of the session having the eportfolio id), the
    # eportfolio hasn't been flagged or marked as spam, and eportfolios are
    # enabled for the author in the context.
    given do |_, session|
      active? && session && session[:eportfolio_ids] &&
        session[:eportfolio_ids].include?(id) &&
        !spam? && self.user.eportfolios_enabled?
    end
    can :read

    given do |user|
      self.user != user && active? && self.user&.grants_right?(user, :moderate_user_content)
    end
    can :read and can :moderate and can :delete and can :restore

    given do |user|
      self.user != user && deleted? && self.user&.grants_right?(user, :moderate_user_content)
    end
    can :restore
  end

  def ensure_defaults
    cat = eportfolio_categories.first
    cat ||= eportfolio_categories.create!(name: t(:first_category, "Home"))
    if cat && cat.eportfolio_entries.empty?
      entry =
        cat.eportfolio_entries.build(eportfolio: self, name: t("first_entry.title", "Welcome"))
      entry.content = t("first_entry.content", "Nothing entered yet")
      entry.save!
    end
    cat
  end

  def self.serialization_excludes
    %i[uuid]
  end

  def title_contains_spam?(title)
    Eportfolio.spam_criteria_regexp&.match?(title)
  end

  def flag_as_possible_spam!
    update!(spam_status: "flagged_as_possible_spam")
  end

  def needs_spam_review?
    active? && spam_status.nil?
  end

  def self.spam_criteria_regexp(type: :title)
    setting_name =
      (type == :title) ? "eportfolio_title_spam_keywords" : "eportfolio_content_spam_keywords"
    spam_keywords = Setting.get(setting_name, "").split(",").map(&:strip).reject(&:empty?)
    return nil if spam_keywords.blank?

    escaped_keywords = spam_keywords.map { |token| Regexp.escape(token) }
    /\b(#{escaped_keywords.join("|")})\b/i
  end

  private

  def check_for_spam
    flag_as_possible_spam! if title_contains_spam?(name)
  end
end
