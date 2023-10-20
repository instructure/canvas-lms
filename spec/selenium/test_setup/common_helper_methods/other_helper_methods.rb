# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module OtherHelperMethods
  def stub_kaltura
    # trick kaltura into being activated
    kal = double("CanvasKaltura::ClientV3")
    allow(kal).to receive(:startSession).and_return "new_session_id_here"
    allow(CanvasKaltura::ClientV3).to receive_messages(
      config: {
        "domain" => "www.instructuremedia.com",
        "resource_domain" => "www.instructuremedia.com",
        "partner_id" => "100",
        "subpartner_id" => "10000",
        "secret_key" => "fenwl1n23k4123lk4hl321jh4kl321j4kl32j14kl321",
        "user_secret_key" => "1234821hrj3k21hjk4j3kl21j4kl321j4kl3j21kl4j3k2l1",
        "player_ui_conf" => "1",
        "kcw_ui_conf" => "1",
        "upload_ui_conf" => "1"
      },
      new: kal
    )
    kal
  end

  def page_view(opts = {})
    course = opts[:course] || @course
    user = opts[:user] || @student
    controller = opts[:controller] || "assignments"
    summarized = opts[:summarized] || nil
    url = opts[:url]
    user_agent = opts[:user_agent] || "firefox"

    page_view = course.page_views.build(
      user:,
      controller:,
      url:,
      user_agent:
    )

    page_view.summarized = summarized
    page_view.request_id = SecureRandom.hex(10)
    page_view.created_at = opts[:created_at] || Time.now

    if opts[:participated]
      page_view.participated = true
      access = page_view.build_asset_user_access
      access.display_name = "Some Asset"
    end

    page_view.store
    page_view
  end

  TEST_FILE_UUIDS = {
    "testfile1.txt" => "63f46f1c-dd4a-467d-a136-333f262f1366",
    "testfile1copy.txt" => "63f46f1c-dd4a-467d-a136-333f262f1366",
    "testfile2.txt" => "5d714eca-2cff-4737-8604-45ca098165cc",
    "testfile3.txt" => "72476b31-58ab-48f5-9548-a50afe2a2fe3",
    "testfile4.txt" => "38f6efa6-aff0-4832-940e-b6f88a655779",
    "testfile5.zip" => "3dc43133-840a-46c8-ea17-3e4bef74af37",
    "attachments.zip" => File.read(File.expand_path(File.dirname(__FILE__) + "/../../../fixtures/attachments.zip")),
    "graded.png" => File.read(File.expand_path(File.dirname(__FILE__) + "/../../../../public/images/graded.png")),
    "cc_full_test.zip" => File.read(File.expand_path(File.dirname(__FILE__) + "/../../../fixtures/migration/cc_full_test.zip")),
    "cc_outcomes.imscc" => File.read(File.expand_path(File.dirname(__FILE__) + "/../../../fixtures/migration/cc_outcomes.imscc")),
    "cc_ark_test.zip" => File.read(File.expand_path(File.dirname(__FILE__) + "/../../../fixtures/migration/cc_ark_test.zip")),
    "canvas_cc_minimum.zip" => File.read(File.dirname(__FILE__) + "/../../../fixtures/files/migration/canvas_cc_minimum.zip"),
    "canvas_cc_only_questions.zip" => File.read(File.expand_path(File.dirname(__FILE__) + "/../../../fixtures/migration/canvas_cc_only_questions.zip")),
    "qti.zip" => File.read(File.expand_path(File.dirname(__FILE__) + "/../../../fixtures/migration/package_identifier/qti.zip")),
    "a_file.txt" => File.read(File.expand_path(File.dirname(__FILE__) + "/../../../fixtures/files/a_file.txt")),
    "b_file.txt" => File.read(File.expand_path(File.dirname(__FILE__) + "/../../../fixtures/files/b_file.txt")),
    "c_file.txt" => File.read(File.expand_path(File.dirname(__FILE__) + "/../../../fixtures/files/c_file.txt")),
    "amazing_file.txt" => File.read(File.expand_path(File.dirname(__FILE__) + "/../../../fixtures/files/amazing_file.txt")),
    "Dog_file.txt" => File.read(File.expand_path(File.dirname(__FILE__) + "/../../../fixtures/files/Dog_file.txt")),
    "cn-image.jpg" => File.read(File.expand_path(File.dirname(__FILE__) + "/../../../fixtures/files/cn_image.jpg")),
    "empty_file.txt" => File.read(File.expand_path(File.dirname(__FILE__) + "/../../../fixtures/files/empty_file.txt")),
  }.freeze

  def get_file(filename, data = nil)
    data ||= TEST_FILE_UUIDS[filename]
    @file = Tempfile.new(filename.split(/(?=\.)/))
    @file.write data
    @file.close
    fullpath = @file.path
    filename = File.basename(@file.path)
    [filename, fullpath, data, @file]
  end

  module EncryptedCookieStoreTestSecret
    cattr_accessor :test_secret

    def self.prepended(klass)
      klass.cattr_accessor(:test_secret)
    end

    def call(env)
      if self.class.test_secret.present?
        @secret = self.class.test_secret
        @encryption_key = unhex(@secret[0...(@data_cipher.key_len * 2)]).freeze
      end
      super
    end
  end
  EncryptedCookieStore.prepend(EncryptedCookieStoreTestSecret)

  def clear_timers!
    # we don't want any AJAX requests getting kicked off after a test ends.
    # the unload event won't fire until sometime after the next test begins (and
    # the old session cookie becomes invalid). that means a late AJAX call can
    # screw up the next test, i.e. two requests send the old (now-invalid)
    # encrypted session cookie, each gets a new (different) session cookie in
    # the response, meaning the authenticity token on your new page might
    # already be invalid.
    driver.execute_script <<~JS
      var highest = setTimeout(function(){}, 1000);
      for (var i = 0; i < highest; i++) {
        clearTimeout(i);
      }
      highest = setInterval(function(){}, 1000);
      for (var i = 0; i < highest; i++) {
        clearInterval(i);
      }
    JS
  end

  def clear_local_storage
    driver.execute_script "localStorage.clear();"
  end

  def scroll_height
    driver.execute_script "return window.pageYOffset"
  end

  def focused_element
    driver.execute_script "return document.activeElement"
  end
end
