#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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
    Canvas::LiveEvents.expects(:logged_in).once
    user_with_pseudonym(:username => 'jtfrd@instructure.com', :active_user => true, :password => 'qwertyuiop')
    post '/login', :pseudonym_session => { :unique_id => 'jtfrd@instructure.com', :password => 'qwertyuiop'}
    expect(response).to be_redirect
  end

  context 'Courses' do

    before do
      course_with_teacher_logged_in(:active_all => true)
    end

    context 'Wiki Pages' do

      def create_page(attrs)
        page = @course.wiki.wiki_pages.create!(attrs)
        page.publish! if page.unpublished?
        page
      end

      it 'should trigger a live event on page creation' do
        Canvas::LiveEvents.expects(:wiki_page_created).once
        create_page :title => 'a-page', :body => 'body'
      end

      it 'should trigger a live event on page update' do
        Canvas::LiveEvents.expects(:wiki_page_updated).twice
        page = create_page :title => 'a-page', :body => 'body'

        # Updating the page body should trigger a live event
        put "/api/v1/courses/#{@course.id}/pages/#{page.url}", :wiki_page => {body: 'UPDATED'}
        expect(response.code).to eq '200'

        # Updating the page title should trigger a live event
        put "/api/v1/courses/#{@course.id}/pages/#{page.url}", :wiki_page => {title: 'UPDATED'}
        expect(response.code).to eq '200'
      end

      it 'should trigger a live event on page delete' do
        Canvas::LiveEvents.expects(:wiki_page_deleted).once
        page = create_page :title => 'a-page', :body => 'body'

        # Updating the page body should trigger a live event
        delete "/api/v1/courses/#{@course.id}/pages/#{page.url}"
        expect(response.code).to eq '200'
      end

    end

    context 'Files' do
      def course_file
        data = fixture_file_upload('scribd_docs/doc.doc', 'application/msword', true)
        factory_with_protected_attributes(@course.attachments, :uploaded_data => data)
      end

      it 'should trigger a live event on files being added to the course' do
        Canvas::LiveEvents.expects(:attachment_created).once
        course_file
      end

      it 'should trigger a live event on file updates' do
        Canvas::LiveEvents.expects(:attachment_updated).once
        file = course_file
        put "/api/v1/files/#{file.id}", :name => 'UPDATED'
        expect(response.code).to eq '200'
      end

      it 'should trigger a live event on file deletes' do
        Canvas::LiveEvents.expects(:attachment_deleted).once
        file = course_file
        delete "/api/v1/files/#{file.id}"
        expect(response.code).to eq '200'
      end
    end
  end
end
