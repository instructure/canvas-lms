# frozen_string_literal: true

#
# Copyright (C) 2011 - 2015 Instructure, Inc.
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

require_relative "../api_spec_helper"

describe "Course Nicknames API", type: :request do
  before(:once) do
    @params = { controller: "course_nicknames", format: "json" }
  end

  it "requires a user for index" do
    api_call(:get,
             "/api/v1/users/self/course_nicknames",
             @params.merge(action: "index"),
             {},
             {},
             { expected_status: 401 })
  end

  context "with user" do
    before(:once) do
      course_with_student active_all: true
    end

    describe "index" do
      it "lists all nicknames" do
        @student.set_preference(:course_nicknames, @course.id, "nickname")
        json = api_call(:get, "/api/v1/users/self/course_nicknames", @params.merge(action: "index"))
        expect(json).to eq([{ "course_id" => @course.id, "name" => @course.name, "nickname" => "nickname" }])
      end

      it "deals with no nicknames existing" do
        json = api_call(:get, "/api/v1/users/self/course_nicknames", @params.merge(action: "index"))
        expect(json).to eq([])
      end
    end

    describe "show" do
      it "returns a single nickname" do
        @student.set_preference(:course_nicknames, @course.id, "nickname")
        json = api_call(:get,
                        "/api/v1/users/self/course_nicknames/#{@course.id}",
                        @params.merge(action: "show", course_id: @course.to_param))
        expect(json).to eq({ "course_id" => @course.id, "name" => @course.name, "nickname" => "nickname" })
      end

      it "returns the user's nickname, not the course's friendly_name if present" do
        @student.set_preference(:course_nicknames, @course.id, "nickname")
        @course.account.enable_as_k5_account!
        @course.friendly_name = "friendly_name"
        @course.save!
        json = api_call(:get,
                        "/api/v1/users/self/course_nicknames/#{@course.id}",
                        @params.merge(action: "show", course_id: @course.to_param))
        expect(json).to eq({ "course_id" => @course.id, "name" => @course.name, "nickname" => "nickname" })
      end

      it "returns a null nickname if no nickname exists" do
        json = api_call(:get,
                        "/api/v1/users/self/course_nicknames/#{@course.id}",
                        @params.merge(action: "show", course_id: @course.to_param))
        expect(json).to eq({ "course_id" => @course.id, "name" => @course.name, "nickname" => nil })
      end

      it "errors if you don't have permission to view the course" do
        other_course = Course.create!
        api_call(:get,
                 "/api/v1/users/self/course_nicknames/#{other_course.id}",
                 @params.merge(action: "show", course_id: other_course.to_param),
                 {},
                 {},
                 { expected_status: 401 })
      end
    end

    describe "update" do
      it "creates a course nickname" do
        json = api_call(:put,
                        "/api/v1/users/self/course_nicknames/#{@course.id}?nickname=new_nickname",
                        @params.merge(action: "update",
                                      course_id: @course.to_param,
                                      nickname: "new_nickname"))
        expect(json["nickname"]).to eq("new_nickname")
        expect(@student.reload.course_nickname(@course)).to eq "new_nickname"
      end

      it "updates a course nickname" do
        @student.set_preference(:course_nicknames, @course.id, "old_nickname")
        json = api_call(:put,
                        "/api/v1/users/self/course_nicknames/#{@course.id}?nickname=new_nickname",
                        @params.merge(action: "update",
                                      course_id: @course.to_param,
                                      nickname: "new_nickname"))
        expect(json["nickname"]).to eq("new_nickname")
        expect(@student.reload.course_nickname(@course)).to eq "new_nickname"
      end

      it "requires the nickname param" do
        json = api_call(:put,
                        "/api/v1/users/self/course_nicknames/#{@course.id}",
                        @params.merge(action: "update", course_id: @course.to_param),
                        {},
                        {},
                        { expected_status: 400 })
        expect(json["message"]).to include "missing nickname"
      end

      it "rejects an empty nickname" do
        json = api_call(:put,
                        "/api/v1/users/self/course_nicknames/#{@course.id}?nickname=",
                        @params.merge(action: "update", course_id: @course.to_param, nickname: ""),
                        {},
                        {},
                        { expected_status: 400 })
        expect(json["message"]).to include "missing nickname"
      end

      it "rejects an overly long nickname" do
        long_nickname = "x" * 100
        json = api_call(:put,
                        "/api/v1/users/self/course_nicknames/#{@course.id}?nickname=#{long_nickname}",
                        @params.merge(action: "update", course_id: @course.to_param, nickname: long_nickname),
                        {},
                        {},
                        { expected_status: 400 })
        expect(json["message"]).to include "nickname too long"
      end

      it "doesn't create a nickname for a course the caller can't access" do
        other_course = Course.create!
        api_call(:put,
                 "/api/v1/users/self/course_nicknames/#{other_course.id}?nickname=blah",
                 @params.merge(action: "update", course_id: other_course.to_param, nickname: "blah"),
                 {},
                 {},
                 { expected_status: 401 })
      end
    end

    describe "delete" do
      it "deletes a single nickname" do
        @student.set_preference(:course_nicknames, @course.id, "nickname")
        json = api_call(:delete,
                        "/api/v1/users/self/course_nicknames/#{@course.id}",
                        @params.merge(action: "delete", course_id: @course.to_param))
        expect(json).to eq({ "course_id" => @course.id, "name" => @course.name, "nickname" => nil })
        expect(@student.reload.course_nickname(@course)).to be_nil
      end
    end

    describe "clear" do
      it "removes all course nicknames" do
        other_course = Course.create!
        @student.set_preference(:course_nicknames, @course.id, "nickname1")
        @student.set_preference(:course_nicknames, other_course.id, "nickname2")
        api_call(:delete,
                 "/api/v1/users/self/course_nicknames",
                 @params.merge(action: "clear"))
        expect(@student.reload.preferences[:course_nicknames]).to eq({})
      end
    end
  end
end
