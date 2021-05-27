# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

require 'spec_helper'

describe FileAuthenticator do
  before :each do
    @oauth_host = 'http://oauth.host/'
    @user = user_model
    @access_token = @user.access_tokens.create!
    @acting_as = user_model
    @attachment = attachment_with_context(@user)
    @attachment.filename = "test.txt"
    @authenticator = FileAuthenticator.new(
      user: @user,
      acting_as: @acting_as,
      access_token: @access_token,
      root_account: Account.default,
      oauth_host: @oauth_host
    )
  end

  describe "fingerprint" do
    it "should be a hexdigest string" do
      expect(@authenticator.fingerprint).to match(/^\h{64}$/)
    end

    it "should be stable across instances with the same parameters" do
      User.where(id: @user).update_all(updated_at: Time.now.utc)
      reloaded = User.where(id: @user).first
      new_authenticator = FileAuthenticator.new(
        user: reloaded,
        acting_as: @acting_as,
        access_token: nil,
        root_account: Account.default,
        oauth_host: @oauth_host
      )
      expect(new_authenticator.fingerprint).to eql(@authenticator.fingerprint)
    end

    it "should be unique across instances with different parameters" do
      new_authenticator = FileAuthenticator.new(
        user: user_model,
        acting_as: @acting_as,
        access_token: nil,
        root_account: Account.default,
        oauth_host: @oauth_host
      )
      expect(new_authenticator.fingerprint).not_to eql(@authenticator.fingerprint)
    end
  end

  context "with an inst-fs attachment" do
    before do
      @attachment.instfs_uuid = 1
    end

    describe "download_url" do
      it "should construct an instfs download url" do
        download_url = 'http://downloadUrl'
        expect(InstFS).to receive(:authenticated_url).
          with(@attachment, include(download: true)).
          and_return(download_url)
        expect(@authenticator.download_url(@attachment)).to eql(download_url)
      end

      it "should construct a url specific to the authenticator params" do
        expect(InstFS).to receive(:authenticated_url).
          with(@attachment, include(
            user: @user,
            acting_as: @acting_as,
            access_token: @access_token,
            root_account: Account.default,
            oauth_host: @oauth_host
          ))
        @authenticator.download_url(@attachment)
      end
    end

    describe "inline_url" do
      it "should construct an instfs inline url" do
        inline_url = 'http://inlineUrl'
        expect(InstFS).to receive(:authenticated_url).
          with(@attachment, include(download: false)).
          and_return(inline_url)
        expect(@authenticator.inline_url(@attachment)).to eql(inline_url)
      end

      it "should construct a url specific to the authenticator params" do
        expect(InstFS).to receive(:authenticated_url).
          with(@attachment, include(
            user: @user,
            acting_as: @acting_as,
            access_token: @access_token,
            root_account: Account.default,
            oauth_host: @oauth_host
          ))
        @authenticator.inline_url(@attachment)
      end
    end

    describe "thumbnail_url" do
      it "should return nil if Attachment.skip_thumbnails" do
        allow(@attachment).to receive(:thumbnailable?).and_return(false)
        allow(Attachment).to receive(:skip_thumbnails).and_return(true)
        expect(@authenticator.thumbnail_url(@attachment)).to be_nil
      end

      it "should return nil if attachment is not thumbnailable" do
        allow(@attachment).to receive(:thumbnailable?).and_return(false)
        expect(@authenticator.thumbnail_url(@attachment)).to be_nil
      end

      it "should construct an instfs thumbnail url" do
        thumbnail_url = 'http://thumbnailUrl'
        allow(@attachment).to receive(:thumbnailable?).and_return(true)
        expect(InstFS).to receive(:authenticated_thumbnail_url).
          with(@attachment, anything).
          and_return(thumbnail_url)
        expect(@authenticator.thumbnail_url(@attachment)).to eql(thumbnail_url)
      end

      it "should pass along the thumbnail geometry" do
        geometry = "640>"
        allow(@attachment).to receive(:thumbnailable?).and_return(true)
        expect(InstFS).to receive(:authenticated_thumbnail_url).
          with(@attachment, include(geometry: geometry))
        @authenticator.thumbnail_url(@attachment, size: geometry)
      end

      it "should pass along the original_url" do
        original_url = "http://example.com/preview/1234"
        allow(@attachment).to receive(:thumbnailable?).and_return(true)
        expect(InstFS).to receive(:authenticated_thumbnail_url).
          with(@attachment, include(original_url: original_url))
        @authenticator.thumbnail_url(@attachment, original_url: original_url)
      end

      it "should construct a url specific to the authenticator params" do
        allow(@attachment).to receive(:thumbnailable?).and_return(true)
        expect(InstFS).to receive(:authenticated_thumbnail_url).
          with(@attachment, include(
            user: @user,
            acting_as: @acting_as,
            access_token: @access_token,
            root_account: Account.default,
            oauth_host: @oauth_host
          ))
        @authenticator.thumbnail_url(@attachment)
      end
    end
  end

  context "with a non-inst-fs attachment" do
    before :each do
      @attachment.instfs_uuid = nil
    end

    it "should delegate to attachment.thumbnail_url" do
      geometry = "640>"
      thumbnail = double()
      expect(@attachment).to receive(:thumbnail_url).
        with(include(size: geometry)).
        and_return(thumbnail)
      expect(@authenticator.thumbnail_url(@attachment, size: geometry)).to be(thumbnail)
    end

    it "should delegate to attachment.public_download_url" do
      download_url = 'http://downloadUrl'
      expect(@attachment).to receive(:public_download_url).and_return(download_url)
      expect(@authenticator.download_url(@attachment)).to be(download_url)
    end

    it "should delegate to attachment.public_inline_url" do
      inline_url = 'http://inlineUrl'
      expect(@attachment).to receive(:public_inline_url).and_return(inline_url)
      expect(@authenticator.inline_url(@attachment)).to be(inline_url)
    end
  end
end
