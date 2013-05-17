#
# Copyright (C) 2011 Instructure, Inc.
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

describe ContentExportsController do
  describe "POST 'create'" do
    it "should explicitly export everything" do
      course_with_teacher_logged_in(:active_all => true)
      post 'create', :course_id => @course.id
      response.should be_success

      ContentExport.last.selected_content[:everything].should be_present
    end
  end

  describe 'GET xml_schema' do
    describe 'with a valid file' do
      let(:filename) { 'cccv1p0' }
      let(:full_path) { Rails.root + "lib/cc/xsd/#{filename}.xsd" }
      before { get 'xml_schema', :version => filename }

      it 'sends in the entire file' do
        response.header['Content-Length'].to_i.should == File.size?(full_path)
      end

      it 'recognizes the file as xml' do
        response.header['Content-Type'].should == 'text/xml'
      end

    end

    describe 'with a nonexistant file' do
      before { get 'xml_schema', :version => 'notafile' }

      it 'returns a 404' do
        response.should_not be_success
      end

      it 'renders the 404 template' do
        response.should render_template('shared/errors/404_message')
      end
    end
  end
end
