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

require "sanitize"

class EportfolioEntry < ActiveRecord::Base
  attr_readonly :eportfolio_id, :eportfolio_category_id
  belongs_to :eportfolio, touch: true
  belongs_to :eportfolio_category

  acts_as_list scope: :eportfolio_category
  before_save :infer_unique_slug
  before_save :infer_comment_visibility
  after_save :check_for_spam, if: -> { eportfolio.needs_spam_review? }

  after_save :update_portfolio
  validates :eportfolio_id, presence: true
  validates :eportfolio_category_id, presence: true
  validates :name, length: { maximum: maximum_string_length, allow_blank: true }
  validates :slug, length: { maximum: maximum_string_length, allow_blank: true }
  has_many :page_comments, -> { preload(:user).order("page_comments.created_at DESC") }, as: :page

  serialize :content

  set_policy do
    given { |user| user && allow_comments }
    can :comment
  end

  def infer_comment_visibility
    self.show_comments = false unless allow_comments
    true
  end
  protected :infer_comment_visibility

  def update_portfolio
    eportfolio.save!
  end
  protected :update_portfolio

  def content_sections
    ((content.is_a?(String) && Array(content)) || content || []).map do |section|
      if section.is_a?(Hash)
        section.with_indifferent_access
      else
        section
      end
    end
  end

  def submission_ids
    res = []
    content_sections.each do |section|
      res << section["submission_id"] if section["section_type"] == "submission"
    end
    res
  end

  def full_slug
    fs = (eportfolio_category.slug rescue "") + "_" + slug
    fs = Digest::SHA256.hexdigest(fs) if fs.length > 250 # ".html" will push this over the 255-char max filename
    fs
  end

  def attachments
    res = []
    content_sections.each do |section|
      if section["attachment_id"].present? && section["section_type"] == "attachment"
        res << (eportfolio.user.all_attachments.where(id: section["attachment_id"]).first rescue nil)
      end
    end
    res.compact
  end

  def submissions
    res = []
    content_sections.each do |section|
      if section["submission_id"].present? && section["section_type"] == "submission"
        res << (eportfolio.user.submissions.where(id: section["submission_id"]).first rescue nil)
      end
    end
    res.compact
  end

  def parse_content(params)
    cnt = params[:section_count].to_i rescue 0
    self.content = []
    cnt.times do |idx|
      obj = params[("section_" + (idx + 1).to_s).to_sym].slice(:section_type, :content, :submission_id, :attachment_id)
      new_obj = { section_type: obj[:section_type] }
      case obj[:section_type]
      when "rich_text", "html"
        config = CanvasSanitize::SANITIZE
        new_obj[:content] = Sanitize.clean(obj[:content] || "", config).strip
        new_obj = nil if new_obj[:content].empty?
      when "submission"
        submission = eportfolio.user.submissions.where(id: obj[:submission_id]).exists? if obj[:submission_id].present?
        if submission
          new_obj[:submission_id] = obj[:submission_id].to_i
        else
          new_obj = nil
        end
      when "attachment"
        attachment = eportfolio.user.attachments.active.where(id: obj[:attachment_id]).exists? if obj[:attachment_id].present?
        if attachment
          new_obj[:attachment_id] = obj[:attachment_id].to_i
        else
          new_obj = nil
        end
      else
        new_obj = nil
      end

      if new_obj
        content << new_obj
      end
    end
    content << t(:default_content, "No Content Added Yet") if content.empty?
  end

  def category_slug
    eportfolio_category.slug rescue eportfolio_category_id
  end

  def infer_unique_slug
    pages = eportfolio_category.eportfolio_entries rescue []
    self.name ||= t(:default_name, "Page Name")
    self.slug = self.name.gsub(/\s+/, "_").gsub(/[^\w\d]/, "")
    pages = pages.where("id<>?", self) unless new_record?
    match_cnt = pages.where(slug:).count
    if match_cnt > 0
      self.slug = slug + "_" + (match_cnt + 1).to_s
    end
  end
  protected :infer_unique_slug

  def to_atom(opts = {})
    rendered_content = t(:click_through, "Click to view page content")
    url = "http://#{HostUrl.default_host}/eportfolios/#{eportfolio_id}/#{eportfolio_category.slug}/#{slug}"
    url += "?verifier=#{eportfolio.uuid}" if opts[:private]

    {
      title: self.name.to_s,
      author: t(:atom_author, "ePortfolio Entry"),
      updated: updated_at,
      published: created_at,
      link: url,
      id: "tag:#{HostUrl.default_host},#{created_at.strftime("%Y-%m-%d")}:/eportfoli_entries/#{feed_code}_#{created_at.strftime("%Y-%m-%d-%H-%M") rescue "none"}",
      content: rendered_content
    }
  end

  private

  def content_contains_spam?
    content_regexp = Eportfolio.spam_criteria_regexp(type: :content)
    return false if content_regexp.blank?

    content_bodies = content_sections.map do |section|
      case section
      when String
        section
      when Hash
        section[:content]
      end
    end
    content_bodies.compact.any? { |content| content_regexp.match?(content) }
  end

  def check_for_spam
    eportfolio.flag_as_possible_spam! if eportfolio.title_contains_spam?(name) || content_contains_spam?
  end
end
