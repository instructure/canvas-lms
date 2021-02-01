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

require_relative '../common'

describe 'user_content post processing' do
  before(:each) { course_with_teacher_logged_in }

  include_context 'in-process server selenium tests'

  def create_wiki_page_with_content(page_title, page_content)
    @root_folder = Folder.root_folders(@course).first
    @course.wiki_pages.create!(title: page_title, body: page_content)
  end

  describe 'with rce_better_file_downloading flag on' do
    before(:each) { Account.site_admin.enable_feature!(:rce_better_file_downloading) }

    it 'adds a preview and download buttons' do
      create_wiki_page_with_content(
        'page',
        '<a id="7" class="instructure_file_link instructure_scribd_file" href="/courses/1/files/7?wrap=1&verifier=xyzzy">file</a>'
      )
      get "/courses/#{@course.id}/pages/page"
      # the file link
      file_link = f('a.instructure_file_link')
      expect(file_link).to be_displayed
      expect(file_link.attribute('href')).to end_with '/courses/1/files/7?wrap=1&verifier=xyzzy'
      # the file inline preview button
      expect(f('a.file_preview_link')).to be_displayed
      # the file download button
      download_btn = f('a.file_download_btn')
      expect(download_btn).to be_displayed
      expect(
        download_btn.attribute('href')
      ).to end_with '/courses/1/files/7/download?verifier=xyzzy&download_frd=1'
    end

    it 'omits preview button is requested' do
      create_wiki_page_with_content(
        'page',
        '<a id="7" class="instructure_file_link instructure_scribd_file inline_disabled" href="/courses/1/files/7?wrap=1&verifier=xyzzy">file</a>'
      )
      get "/courses/#{@course.id}/pages/page"
      # the file link
      file_link = f('a.instructure_file_link')
      expect(file_link).to be_displayed
      expect(file_link.attribute('href')).to end_with '/courses/1/files/7?wrap=1&verifier=xyzzy'
      # the file inline preview button
      expect(f('body')).not_to contain_css('a.file_preview_link')
      # the file download button
      download_btn = f('a.file_download_btn')
      expect(download_btn).to be_displayed
      expect(
        download_btn.attribute('href')
      ).to end_with '/courses/1/files/7/download?verifier=xyzzy&download_frd=1'
    end
  end

  describe 'with rce_better_file_downloading flag off' do
    before(:each) { Account.site_admin.disable_feature!(:rce_better_file_downloading) }

    it 'adds a preview and download buttons' do
      create_wiki_page_with_content(
        'page',
        '<a id="7" class="instructure_file_link instructure_scribd_file" href="/courses/1/files/7?wrap=1&verifier=xyzzy">file</a>'
      )
      get "/courses/#{@course.id}/pages/page"
      # the file link
      file_link = f('a.instructure_file_link')
      expect(file_link).to be_displayed
      expect(file_link.attribute('href')).to end_with '/courses/1/files/7?wrap=1&verifier=xyzzy'
      # the file inline preview button
      expect(f('a.file_preview_link')).to be_displayed
      # the file download button
      expect(f('body')).not_to contain_css('a.file_download_btn')
    end
  end
end
