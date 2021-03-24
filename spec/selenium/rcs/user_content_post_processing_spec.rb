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
  include_context 'in-process server selenium tests'

  before(:each) do
    course_with_teacher_logged_in
    @file =
      @course.attachments.create!(
        display_name: 'file',
        context: @teacher,
        uploaded_data: fixture_file_upload('files/a_file.txt', 'text/plain')
      )
    @file.save!
    @file_url = "http://#{HostUrl.default_host}/users/#{@teacher.id}/files/#{@file.id}"
  end

  def create_wiki_page_with_content(page_title, page_content)
    @root_folder = Folder.root_folders(@course).first
    @course.wiki_pages.create!(title: page_title, body: page_content)
  end

  describe 'with rce_better_file_downloading flag on' do
    before(:each) { Account.site_admin.enable_feature!(:rce_better_file_downloading) }

    it 'adds a preview and download buttons' do
      create_wiki_page_with_content(
        'page',
        "<a id='link1' class='instructure_file_link instructure_scribd_file'
          href='#{@file_url}?wrap=1&verifier=#{@file.uuid}'>file link w/o download</a>
        <a id='link2' class='instructure_file_link instructure_scribd_file'
          href='#{@file_url}/download?wrap=1&verifier=#{@file.uuid}'>file link with download</a>"
      )
      get "/courses/#{@course.id}/pages/page"

      # the file link w/o /download
      file_link1 = f('a#link1')
      expect(file_link1).to be_displayed
      expect(file_link1.attribute('class')).to eq('')
      expect(file_link1.attribute('href')).to end_with "#{@file_url}?wrap=1&verifier=#{@file.uuid}"

      file_link2 = f('a#link2')
      expect(file_link2).to be_displayed
      expect(file_link2.attribute('class')).to eq('')
      expect(
        file_link2.attribute('href')
      ).to end_with "#{@file_url}/download?wrap=1&verifier=#{@file.uuid}"

      # the file inline preview buttons
      expect(ff('a.file_preview_link')[0]).to be_displayed
      expect(ff('a.file_preview_link')[1]).to be_displayed

      # the file download buttons
      # href includes 1 and only 1 /download
      download_btn = ff('a.file_download_btn')
      expect(download_btn[0]).to be_displayed
      expect(download_btn[1]).to be_displayed
      expect(
        download_btn[0].attribute('href')
      ).to end_with "#{@file_url}/download?verifier=#{@file.uuid}&download_frd=1"
      expect(
        download_btn[1].attribute('href')
      ).to end_with "#{@file_url}/download?verifier=#{@file.uuid}&download_frd=1"

      expect(download_btn[0]).to have_attribute('download')
      expect(download_btn[1]).to have_attribute('download')
    end

    it 'omits preview button is requested' do
      create_wiki_page_with_content(
        'page',
        "<a id='thelink' class='instructure_file_link instructure_scribd_file inline_disabled'
          href='#{@file_url}?wrap=1&verifier=#{@file.uuid}'>file</a>"
      )
      get "/courses/#{@course.id}/pages/page"

      # the file link
      file_link = f('a#thelink')
      expect(file_link).to be_displayed
      expect(file_link.attribute('class')).to eq('inline_disabled')
      expect(file_link.attribute('href')).to end_with "#{@file_url}?wrap=1&verifier=#{@file.uuid}"

      # the file inline preview button
      expect(f('body')).not_to contain_css('a.file_preview_link')

      # the file download button
      download_btn = f('a.file_download_btn')
      expect(download_btn).to be_displayed
      expect(
        download_btn.attribute('href')
      ).to end_with "#{@file_url}/download?verifier=#{@file.uuid}&download_frd=1"
      expect(download_btn).to have_attribute('download')
    end

    it 'omits download button if an external link' do
      create_wiki_page_with_content(
        'page',
        "<a id='link1' class='instructure_file_link'
          href='http://instructure.com'>external link</a>"
      )
      get "/courses/#{@course.id}/pages/page"

      # the link has an external-link button
      expect(f('.ui-icon-extlink')).to be_displayed
      expect(f('#link1')).not_to contain_css('.file_download_btn')
    end

    it 'omits download button if internal link' do
      create_wiki_page_with_content(
        'page',
        "<a id='link1' class='instructure_file_link'
          href='/courses/#{@course.id}/pages/other-page'>internal link</a>"
      )
      get "/courses/#{@course.id}/pages/page"

      # look up the link by the data-api-endpoint
      # because this is how we determine to hide the download button for internal links
      data_api_endpoint = "http://#{HostUrl.default_host}/api/v1/courses/#{@course.id}/pages/other-page"
      expect(fj("a[data-api-endpoint='#{data_api_endpoint}']")).to be_displayed
      expect(f('body')).not_to contain_css('a.file_download_btn')
    end
  end

  describe 'with rce_better_file_downloading flag off' do
    before(:each) { Account.site_admin.disable_feature!(:rce_better_file_downloading) }

    it 'adds a preview and download buttons' do
      create_wiki_page_with_content(
        'page',
        "<a id='thelink' class='instructure_file_link instructure_scribd_file'
          href='#{@file_url}?wrap=1&verifier=#{@file.uuid}'>file</a>"
      )
      get "/courses/#{@course.id}/pages/page"

      # the file link
      file_link = f('a#thelink')
      expect(file_link).to be_displayed
      expect(file_link.attribute('href')).to end_with "#{@file_url}?wrap=1&verifier=#{@file.uuid}"

      # the file inline preview button
      expect(f('a.file_preview_link')).to be_displayed

      # the file download button
      expect(f('body')).not_to contain_css('a.file_download_btn')
    end
  end

  describe 'with rce_better_file_previewing flag on' do
    before(:each) { Account.site_admin.enable_feature!(:rce_better_file_previewing) }

    it 'previews files in the FilePreview overlay' do
      create_wiki_page_with_content(
        'page',
        "<a id='thelink' class='instructure_file_link instructure_scribd_file inline_disabled'
          href='#{@file_url}?wrap=1&verifier=#{@file.uuid}'>file</a>"
      )
      get "/courses/#{@course.id}/pages/page"

      file_link = f('a#thelink')
      expect(file_link.attribute('class')).to include('preview_in_overlay')

      file_link.click
      expect(f('[aria-label="File Preview Overlay"]')).to be_displayed
    end

    it 'inline-able file link does not show the file preview icon' do
      create_wiki_page_with_content(
        'page',
        "<a id='thelink' class='instructure_file_link instructure_scribd_file'
          href='#{@file_url}?wrap=1&verifier=#{@file.uuid}'>file</a>"
      )
      get "/courses/#{@course.id}/pages/page"

      file_link = f('a#thelink')
      expect(file_link.attribute('class')).to include('file_preview_link')
      expect(f('.instructure_file_holder')).not_to contain_css('img[alt="Preview the document"]')

      file_link.click
      expect(f('.loading_image_holder')).to be_displayed
      preview_container = f('#preview_1[role="region"]')
      expect(f('.hide_file_preview_link', preview_container)).to be_displayed
      expect(f('iframe', preview_container)).to be_displayed
    end

    it 'performs the browser default action if inline preview link is clicked with a modifier key pressed' do
      create_wiki_page_with_content(
        'page',
        "<a id='thelink' class='instructure_file_link instructure_scribd_file'
          href='#{@file_url}?wrap=1&verifier=#{@file.uuid}'>file</a>"
      )
      get "/courses/#{@course.id}/pages/page"

      browser_tabs = driver.window_handles
      expect(browser_tabs.length).to eq(1)

      modifier_key = /mac/ =~ driver.capabilities.platform ? :meta : :control
      file_link = f('a#thelink')
      driver.action.key_down(modifier_key).click(file_link).key_up(modifier_key).perform

      browser_tabs = driver.window_handles
      expect(browser_tabs.length).to eq(2)

      # if we don't close the new tab, flake_spec_catcher
      # starts the next iteration with both tabs open
      driver.switch_to.window(browser_tabs[1])
      driver.close
      driver.switch_to.window(browser_tabs[0])
    end

    it 'performs the browser default action if overlay view link is clicked with a modifier key pressed' do
      create_wiki_page_with_content(
        'page',
        "<a id='thelink' class='instructure_file_link instructure_scribd_file inline_disabled'
          href='#{@file_url}?wrap=1&verifier=#{@file.uuid}'>file</a>"
      )
      get "/courses/#{@course.id}/pages/page"

      browser_tabs = driver.window_handles
      expect(browser_tabs.length).to eq(1)

      modifier_key = /mac/ =~ driver.capabilities.platform ? :meta : :control
      file_link = f('a#thelink')
      driver.action.key_down(modifier_key).click(file_link).key_up(modifier_key).perform

      browser_tabs = driver.window_handles
      expect(browser_tabs.length).to eq(2)

      # if we don't close the new tab, flake_spec_catcher
      # starts the next iteration with both tabs open
      driver.switch_to.window(browser_tabs[1])
      driver.close
      driver.switch_to.window(browser_tabs[0])
    end
  end
end
