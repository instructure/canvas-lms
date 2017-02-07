#
# Copyright (C) 2016 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe "Announcements API", type: :request do
  before :once do
    course_with_teacher :active_all => true
    student_in_course :active_enrollment => true
    @course1 = @course
    @ann1 = @course1.announcements.build :title => "Announcement 1", :message => '1'
    @ann1.posted_at = 7.days.ago
    @ann1.save!

    # For testing chronological ordering
    @anns = []

    1.upto(5) do |i|
      ann = @course1.announcements.build :title => "Accountment 1.#{i}", message: i
      ann.posted_at = (7 - i).days.ago # To make them more recent each time
      ann.save!

      @anns << ann
    end

    course_with_teacher :active_all => true, :user => @teacher
    student_in_course :active_enrollment => true, :user => @student
    @course2 = @course
    @ann2 = @course2.announcements.build :title => "Announcement 2", :message => '2'
    @ann2.workflow_state = 'post_delayed'
    @ann2.posted_at = Time.now
    @ann2.delayed_post_at = 21.days.from_now
    @ann2.save!

    @params = { :controller => 'announcements_api', :action => 'index', :format => 'json' }
  end

  context "as teacher" do
    it "requires course_ids argument" do
      json = api_call_as_user(@teacher, :get, "/api/v1/announcements", @params, {}, {}, { :expected_status => 400 })
      expect(json['message']).to eq 'Missing context_codes'
    end

    it "does not accept contexts other than courses" do
      json = api_call_as_user(@teacher, :get, "/api/v1/announcements",
                              @params.merge(:context_codes => ["user_#{@teacher.id}"]), {}, {},
                              { :expected_status => 400 })
      expect(json['message']).to include 'Invalid context_codes'
    end

    it "requires :read_announcements permission on all courses" do
      random_course = Course.create!
      api_call_as_user(@teacher, :get, "/api/v1/announcements",
               @params.merge(:context_codes => [ "course_#{@course1.id}", "course_#{random_course.id}" ]),
               {}, {}, { :expected_status => 401 })
    end

    it "returns announcements for the the surrounding 14 days by default" do
      json = api_call_as_user(@teacher, :get, "/api/v1/announcements",
                      @params.merge(:context_codes => [ "course_#{@course1.id}", "course_#{@course2.id}" ]))
      expect(json.length).to eq 6
      expect(json[0]['context_code']).to eq "course_#{@course1.id}"
    end

    it "returns announcements for the given date range" do
      start_date = 10.days.ago.iso8601
      end_date = 30.days.from_now.iso8601
      json = api_call_as_user(@teacher, :get, "/api/v1/announcements",
                      @params.merge(:context_codes => [ "course_#{@course1.id}", "course_#{@course2.id}" ],
                                    :start_date => start_date, :end_date => end_date))

      all_anns = @anns.map { |e| [e['context_code'], e['id']] }
      all_anns.concat([["course_#{@course1.id}", @ann1.id], ["course_#{@course2.id}", @ann2.id]])
      expect(json.length).to eq 7
      expect(json.map { |e| [e['context_code'], e['id']] }).to match_array all_anns
    end

    it "validates date formats" do
      start_date = "next sursdai"
      end_date = "y'all biscuitheads"
      api_call_as_user(@teacher, :get, "/api/v1/announcements",
                      @params.merge(:context_codes => [ "course_#{@course1.id}", "course_#{@course2.id}" ],
                                    :start_date => start_date, :end_date => end_date), {}, {},
                       { :expected_status => 400 })
    end

    it "matches dates inclusive" do
      start_date = end_date = @ann2.delayed_post_at.strftime('%F')
      json = api_call_as_user(@teacher, :get, "/api/v1/announcements",
                      @params.merge(:context_codes => [ "course_#{@course1.id}", "course_#{@course2.id}" ],
                                    :start_date => start_date, :end_date => end_date))
      expect(json.map { |thing| thing['id'] }).to eq [@ann2.id]
    end

    it "paginates" do
      start_date = 10.days.ago.iso8601
      end_date = 30.days.from_now.iso8601
      json = api_call_as_user(@teacher, :get, "/api/v1/announcements",
                      @params.merge(:context_codes => [ "course_#{@course1.id}", "course_#{@course2.id}" ],
                                    :start_date => start_date, :end_date => end_date, :per_page => 1))
      expect(json.length).to eq 1
      next_link = response.headers['Link'].split(",").detect { |link| link =~ /rel="next"/ }
      expect(next_link).to match /\/api\/v1\/announcements/
      expect(next_link).to include "page=2"
    end

    it "orders by reverse chronological order" do
      json = api_call_as_user(@teacher, :get, "/api/v1/announcements",
                      @params.merge(:context_codes => [ "course_#{@course1.id}" ]))
      expect(json.length).to eq 6
      expect(json[0]['context_code']).to eq "course_#{@course1.id}"
      expect(json.map { |thing| thing['id'] }).to eq @anns.map(&:id).reverse << @ann1.id
    end

    describe "active_only" do
      it "excludes delayed-post announcements" do
        start_date = 10.days.ago.iso8601
        end_date = 30.days.from_now.iso8601
        json = api_call_as_user(@teacher, :get, "/api/v1/announcements",
                        @params.merge(:context_codes => [ "course_#{@course1.id}", "course_#{@course2.id}" ],
                                      :start_date => start_date, :end_date => end_date, :active_only => true))
        expect(json.length).to eq 6
        expect(json.map { |thing| thing['id'] }).to eq @anns.map(&:id).reverse << @ann1.id
      end

      it "includes 'active' announcements with past `delayed_post_at`" do
        @ann1.update_attribute(:delayed_post_at, 7.days.ago)
        expect(@ann1).to be_active
        start_date = 10.days.ago.iso8601
        end_date = 30.days.from_now.iso8601
        json = api_call_as_user(@teacher, :get, "/api/v1/announcements",
                        @params.merge(:context_codes => [ "course_#{@course1.id}", "course_#{@course2.id}" ],
                                      :start_date => start_date, :end_date => end_date, :active_only => true))
        expect(json.length).to eq 6
        expect(json.map { |thing| thing['id'] }).to eq @anns.map(&:id).reverse << @ann1.id
      end

      it "excludes courses not in the context_ids list" do
        start_date = 10.days.ago.iso8601
        end_date = 30.days.from_now.iso8601
        json = api_call_as_user(@teacher, :get, "/api/v1/announcements",
                        @params.merge(:context_codes => [ "course_#{@course2.id}" ],
                                      :start_date => start_date, :end_date => end_date, :active_only => true))
        expect(json).to be_empty
      end
    end
  end

  context "as student" do
    it "excludes delayed-post announcements" do
      start_date = 10.days.ago.iso8601
      end_date = 30.days.from_now.iso8601
      json = api_call_as_user(@student, :get, "/api/v1/announcements",
                      @params.merge(:context_codes => [ "course_#{@course1.id}", "course_#{@course2.id}" ],
                                    :start_date => start_date, :end_date => end_date))
      expect(json.length).to eq 6
      expect(json.map { |thing| thing['id'] }).to eq @anns.map(&:id).reverse << @ann1.id
    end

    it "excludes 'active' announcements with future `delayed_post_at`" do
      @ann2.update_attribute(:workflow_state, 'active')
      start_date = 10.days.ago.iso8601
      end_date = 30.days.from_now.iso8601
      json = api_call_as_user(@student, :get, "/api/v1/announcements",
                      @params.merge(:context_codes => [ "course_#{@course1.id}", "course_#{@course2.id}" ],
                                    :start_date => start_date, :end_date => end_date))
      expect(json.length).to eq 6
      expect(json.map { |thing| thing['id'] }).to eq @anns.map(&:id).reverse << @ann1.id
    end


    it "includes 'active' announcements with past `delayed_post_at`" do
      @ann1.update_attribute(:delayed_post_at, 7.days.ago)
      expect(@ann1).to be_active
      start_date = 10.days.ago.iso8601
      end_date = 30.days.from_now.iso8601
      json = api_call_as_user(@student, :get, "/api/v1/announcements",
                      @params.merge(:context_codes => [ "course_#{@course1.id}", "course_#{@course2.id}" ],
                                    :start_date => start_date, :end_date => end_date))
      expect(json.length).to eq 6
      expect(json.map { |thing| thing['id'] }).to eq @anns.map(&:id).reverse << @ann1.id
    end

    it "excludes courses not in the context_ids list" do
      start_date = 10.days.ago.iso8601
      end_date = 30.days.from_now.iso8601
      json = api_call_as_user(@student, :get, "/api/v1/announcements",
                      @params.merge(:context_codes => [ "course_#{@course2.id}" ],
                                    :start_date => start_date, :end_date => end_date))
      expect(json).to be_empty
    end
  end
end
