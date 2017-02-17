#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'nokogiri'

describe "syllabus" do
  def anonymous_syllabus_access_allowed(property, value=true)
    course_with_teacher(:course => @course, :active_all => true)
    @course.send("#{property}=", value)
    @course.save!

    get "/courses/#{@course.id}/assignments/syllabus"

    expect(response).to be_success
    page = Nokogiri::HTML(response.body)
    expect(page.css('#identity a[href="/login"]')).not_to be_nil
    expect(page.at_css('#syllabusContainer')).not_to be_nil
  end

  it "should allow access to public courses" do
    anonymous_syllabus_access_allowed :is_public
  end

  it "should allow access to a public syllabus" do
    anonymous_syllabus_access_allowed :public_syllabus
  end

  shared_examples_for "public syllabus file verifiers" do
    it "should allow viewing available files in a public syllabus" do
      course_factory(active_all: true)
      attachment_model
      @course.syllabus_body = "<a href=\"/courses/#{@course.id}/files/#{@attachment.id}/download\">linky</a>"
      @course.public_syllabus = true
      @course.save!

      get "/courses/#{@course.id}/assignments/syllabus"

      expect(response).to be_success
      page = Nokogiri::HTML(response.body)
      expect(page.css('#identity a[href="/login"]')).not_to be_nil
      link = page.at_css('#course_syllabus a')
      expect(link.attributes['href'].value).to include("verifier=#{@attachment.uuid}")
    end

    it "should not allow viewing locked files in a public syllabus" do
      course_factory(active_all: true)
      attachment_model
      @attachment.locked = true
      @attachment.save!

      @course.syllabus_body = "<a href=\"/courses/#{@course.id}/files/#{@attachment.id}/download\">linky</a>"
      @course.public_syllabus = true
      @course.save!

      get "/courses/#{@course.id}/assignments/syllabus"

      expect(response).to be_success
      page = Nokogiri::HTML(response.body)
      expect(page.css('#identity a[href="/login"]')).not_to be_nil
      link = page.at_css('#course_syllabus a')
      expect(link.attributes['href'].value).to_not include("verifier=#{@attachment.uuid}")
    end
  end

  shared_examples_for "public syllabus for authenticated file verifiers" do
    it "should allow viewing available files in a public to authenticated syllabus" do
      course_factory(active_all: true)
      attachment_model
      @course.syllabus_body = "<a href=\"/courses/#{@course.id}/files/#{@attachment.id}/download\">linky</a>"
      @course.public_syllabus_to_auth = true
      @course.public_syllabus = false
      @course.save!

      get "/courses/#{@course.id}/assignments/syllabus"

      expect(response).to be_success
      page = Nokogiri::HTML(response.body)
      expect(page.css('#identity a[href="/login"]')).not_to be_nil
      link = page.at_css('#course_syllabus a')
      expect(link.attributes['href'].value).to include("verifier=#{@attachment.uuid}")
    end

    it "should not allow viewing locked files in a public to authenticated syllabus" do
      course_factory(active_all: true)
      attachment_model
      @attachment.locked = true
      @attachment.save!

      @course.syllabus_body = "<a href=\"/courses/#{@course.id}/files/#{@attachment.id}/download\">linky</a>"
      @course.public_syllabus = false
      @course.public_syllabus_to_auth = true
      @course.save!

      get "/courses/#{@course.id}/assignments/syllabus"

      expect(response).to be_success
      page = Nokogiri::HTML(response.body)
      expect(page.css('#identity a[href="/login"]')).not_to be_nil
      link = page.at_css('#course_syllabus a')
      expect(link.attributes['href'].value).to_not include("verifier=#{@attachment.uuid}")
    end
  end

  context "as an authenticated non-course user" do
    before :each do
      user_factory(active_all: true)
      user_session(@user)
    end

    include_examples "public syllabus for authenticated file verifiers"
  end

  context "as an anonymous user" do
    include_examples "public syllabus file verifiers"
  end

  context "as an authenticated non-course user" do
    before :each do
      user_factory(active_all: true)
      user_session(@user)
    end

    include_examples "public syllabus file verifiers"
  end

  it "as an authenticated non-course user with public_syllabus_to_auth true" do
    course_factory.public_syllabus_to_auth = true
    course_factory.public_syllabus = false
    course_factory.save
    user_factory(active_user: true)
    user_session(@user)

  end

  it "should display syllabus description on syllabus course home pages" do
    course_with_teacher_logged_in(:active_all => true)
    syllabus_body = "test syllabus body"
    @course.syllabus_body = syllabus_body
    @course.default_view = "syllabus"
    @course.save!

    get "/courses/#{@course.id}"

    expect(response).to be_success
    page = Nokogiri::HTML(response.body)
    expect(page.at_css('#course_syllabus').text).to include(syllabus_body)
  end
end
