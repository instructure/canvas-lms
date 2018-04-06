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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper')

describe LiveEvents do

  it 'should trigger a live event on login' do
    expect(Canvas::LiveEvents).to receive(:logged_in).once
    user_with_pseudonym(:username => 'jtfrd@instructure.com', :active_user => true, :password => 'qwertyuiop')
    post '/login/canvas', params: {:pseudonym_session => { :unique_id => 'jtfrd@instructure.com', :password => 'qwertyuiop'}}
    expect(response).to be_redirect
  end

  context 'Courses' do

    before do
      course_with_teacher_logged_in(:active_all => true)
    end

    context 'Wiki Pages' do

      def create_page(attrs)
        page = @course.wiki_pages.create!(attrs)
        page.publish! if page.unpublished?
        page
      end

      it 'should trigger a live event on page creation' do
        expect(Canvas::LiveEvents).to receive(:wiki_page_created).once
        create_page :title => 'a-page', :body => 'body'
      end

      it 'should trigger a live event on page update' do
        expect(Canvas::LiveEvents).to receive(:wiki_page_updated).twice
        page = create_page :title => 'a-page', :body => 'body'

        # Updating the page body should trigger a live event
        put "/api/v1/courses/#{@course.id}/pages/#{page.url}", params: {:wiki_page => {body: 'UPDATED'}}
        expect(response.code).to eq '200'

        # Updating the page title should trigger a live event
        put "/api/v1/courses/#{@course.id}/pages/#{page.url}", params: {:wiki_page => {title: 'UPDATED'}}
        expect(response.code).to eq '200'
      end

      it 'should trigger a live event on page delete' do
        expect(Canvas::LiveEvents).to receive(:wiki_page_deleted).once
        page = create_page :title => 'a-page', :body => 'body'

        # Updating the page body should trigger a live event
        delete "/api/v1/courses/#{@course.id}/pages/#{page.url}"
        expect(response.code).to eq '200'
      end

    end

    context 'Files' do
      def course_file
        data = fixture_file_upload('docs/doc.doc', 'application/msword', true)
        factory_with_protected_attributes(@course.attachments, :uploaded_data => data)
      end

      it 'should trigger a live event on files being added to the course' do
        expect(Canvas::LiveEvents).to receive(:attachment_created).once
        course_file
      end

      it 'should trigger a live event on file updates' do
        expect(Canvas::LiveEvents).to receive(:attachment_updated).once
        file = course_file
        put "/api/v1/files/#{file.id}", params: {:name => 'UPDATED'}
        expect(response.code).to eq '200'
      end

      it 'should trigger a live event on file deletes' do
        expect(Canvas::LiveEvents).to receive(:attachment_deleted).once
        file = course_file
        delete "/api/v1/files/#{file.id}"
        expect(response.code).to eq '200'
      end
    end
  end

  context 'Enrollments' do
    it "should trigger a live event on limit_privileges_to_course_section!" do
      course_with_student
      expect(Canvas::LiveEvents).to receive(:enrollment_updated).once
      Enrollment.limit_privileges_to_course_section!(@course, @user, true)
    end
  end
end
