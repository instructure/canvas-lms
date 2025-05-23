# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class AccessibilityController < ApplicationController
  before_action :require_context
  before_action :require_user

  include Api::V1::Course
  include Api::V1::Assignment
  include Api::V1::Attachment
  include Api::V1::WikiPage

  def show
    return render(body: "") unless allowed?

    js_bundle :accessibility_checker

    render html: "<div id=\"accessibility-checker-container\"></div>".html_safe, layout: true
  end

  def issues
    return unless allowed?

    render json: create_accessibility_issues
  end

  def update
    return unless allowed?

    content = request.body.read
    content_data = JSON.parse(content)

    unless Accessibility::Rule.registry.key?(content_data["rule"])
      render json: {
               error: "Invalid rule identifier '#{content_data["rule"]}', should be one of #{Accessibility::Rule.registry.keys}"
             },
             status: :bad_request and return
    end

    rule = Accessibility::Rule.registry[content_data["rule"]]

    case content_data["content_type"]
    when "Page"
      wiki_page = @context.wiki_pages.find_by(id: content_data["content_id"])
      unless wiki_page
        render json: {
                 error: "Wiki page #{content_data["content_id"]} not found"
               },
               status: :not_found and return
      end

      wiki_page.body = AccessibilityControllerHelper.fix_content(
        wiki_page.body, rule, content_data["path"], content_data["value"]
      )
      wiki_page.save!
    when "Assignment"
      assignment = @context.assignments.find_by(id: content_data["content_id"])
      unless assignment
        render json: {
                 error: "Assignment #{content_data["content_id"]} not found"
               },
               status: :not_found and return
      end

      assignment.description = AccessibilityControllerHelper.fix_content(
        assignment.body, rule, content_data["path"], content_data["value"]
      )
      assignment.save!
    else
      render json: { error: "Invalid content type" }, status: :unprocessable_entity and return
    end

    render json: { success: true }
  end

  def create_accessibility_issues(rules = Accessibility::Rule.registry, pdf_rules = Accessibility::Rule.pdf_registry)
    course_pages = @context.wiki_pages.not_deleted.order(updated_at: :desc)
    course_assignments = @context.assignments.active.order(updated_at: :desc)
    attachments = @context.attachments.not_deleted.order(updated_at: :desc)

    {
      pages: create_page_issues(course_pages, rules),
      assignments: create_assignment_issues(course_assignments, rules),
      attachments: create_attachment_issues(attachments, pdf_rules),
      last_checked: Time.zone.now.strftime("%b %-d, %Y")
    }
  end

  private

  def allowed?
    return false unless tab_enabled?(Course::TAB_ACCESSIBILITY) && authorized_action(@context, @current_user, :read)

    true
  end

  def create_page_issues(pages, rules)
    issues = {}
    pages.each do |page|
      result = AccessibilityControllerHelper.check_content_accessibility(page.body, rules)

      issues[page.id] = result
      issues[page.id][:title] = page.title
      issues[page.id][:published] = page.published?
      issues[page.id][:updated_at] = page.updated_at&.iso8601 || ""
      page_url = polymorphic_url([@context, page])
      issues[page.id][:url] = page_url
      issues[page.id][:edit_url] = "#{page_url}/edit"
    end
    issues
  end

  def create_assignment_issues(assignments, rules)
    issues = {}
    assignments.each do |assignment|
      result = AccessibilityControllerHelper.check_content_accessibility(assignment.description, rules)

      issues[assignment.id] = result
      issues[assignment.id][:title] = assignment.title
      issues[assignment.id][:published] = assignment.published?
      issues[assignment.id][:updated_at] = assignment.updated_at&.iso8601 || ""
      assignment_url = polymorphic_url([@context, assignment])
      issues[assignment.id][:url] = assignment_url
      issues[assignment.id][:edit_url] = "#{assignment_url}/edit"
    end
    issues
  end

  def create_attachment_issues(attachments, rules)
    issues = {}
    attachments.each do |attachment|
      result = {}
      if attachment.content_type == "application/pdf"
        result = AccessibilityControllerHelper.check_pdf_accessibility(attachment, rules)
      end

      issues[attachment.id] = result
      issues[attachment.id][:title] = attachment.title
      issues[attachment.id][:content_type] = attachment.content_type
      issues[attachment.id][:published] = attachment.published?
      issues[attachment.id][:updated_at] = attachment.updated_at&.iso8601 || ""
      issues[attachment.id][:url] = course_files_url(@context, preview: attachment.id)
    end
    issues
  end
end
