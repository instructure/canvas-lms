# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative "course_copy_helper"

describe ContentMigration do
  context "blueprint settings" do
    include_context "course copy"

    before :once do
      @template = MasterCourses::MasterTemplate.set_as_master_course(@copy_from)
      @template.default_restrictions = { content: true }
      @template.use_default_restrictions_by_type = true
      @template.default_restrictions_by_type = {
        "Assignment" => { content: true, points: true, due_dates: false, availability_dates: false },
        "DiscussionTopic" => { content: false, points: false, due_dates: true, availability_dates: true },
        "WikiPage" => { content: false }
      }
      @template.save!

      @assignment = @copy_from.assignments.create!(title: "something")
      @topic = @copy_from.discussion_topics.create!(title: "o hai")
      @page = @copy_from.wiki_pages.create!(title: "blargh", body: "...")
      @unlocked_assign = @copy_from.assignments.create!(title: "not locked")

      [@assignment, @topic, @page].each_with_index do |item, index|
        tag = @template.content_tag_for(item)
        tag.restrictions = @template.default_restrictions_for(item)
        tag.use_default_restrictions = index.even? # pretend some items have custom restrictions set via the API
        tag.save!
      end
      @cm.update(user: account_admin_user)
    end

    it "does not copy blueprint settings if not requested" do
      run_course_copy
      expect(MasterCourses::MasterTemplate.is_master_course?(@copy_to)).to be false
    end

    it "copies blueprint settings" do
      @cm.migration_settings[:import_blueprint_settings] = true
      run_course_copy

      template_to = MasterCourses::MasterTemplate.full_template_for(@copy_to)
      expect(template_to).not_to be_nil

      expect(template_to.use_default_restrictions_by_type).to be true
      expect(template_to.default_restrictions).to eq(@template.default_restrictions)
      expect(template_to.default_restrictions_by_type).to eq(@template.default_restrictions_by_type)

      assign_to = @copy_to.assignments.where(migration_id: mig_id(@assignment)).take
      mt = template_to.content_tag_for(assign_to)
      expect(mt.restrictions).to eq({ content: true, points: true, due_dates: false, availability_dates: false })
      expect(mt.use_default_restrictions).to be true

      topic_to = @copy_to.discussion_topics.where(migration_id: mig_id(@topic)).take
      mt = template_to.content_tag_for(topic_to)
      expect(mt.restrictions).to eq({ content: false, points: false, due_dates: true, availability_dates: true })
      expect(mt.use_default_restrictions).to be false

      page_to = @copy_to.wiki_pages.where(migration_id: mig_id(@page)).take
      mt = template_to.content_tag_for(page_to)
      expect(mt.restrictions).to eq({ content: false })
      expect(mt.use_default_restrictions).to be true

      unlocked_assign_to = @copy_to.assignments.where(migration_id: mig_id(@unlocked_assign)).take
      expect(template_to.content_tag_for(unlocked_assign_to).restrictions).to eq({})
    end

    it "does nothing if the destination course is already associated with a blueprint course" do
      other_blueprint = course_model
      other_template = MasterCourses::MasterTemplate.set_as_master_course(other_blueprint)
      other_template.add_child_course!(@copy_to)

      @cm.migration_settings[:import_blueprint_settings] = true
      run_course_copy(["Course is ineligible to be set as a blueprint"])

      expect(MasterCourses::MasterTemplate.is_master_course?(@copy_to)).to be false
      expect(MasterCourses::ChildSubscription.is_child_course?(@copy_to)).to be true
    end

    it "does nothing if the destination course has student enrollments" do
      student_in_course(course: @copy_to)

      @cm.migration_settings[:import_blueprint_settings] = true
      run_course_copy(["Course is ineligible to be set as a blueprint"])

      expect(MasterCourses::MasterTemplate.is_master_course?(@copy_to)).to be false
    end
  end
end
