# frozen_string_literal: true

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

describe Canvas::Cdn do
  before do
    @original_config = Canvas::Cdn.config.dup
  end

  after do
    Canvas::Cdn.config.replace(@original_config)
  end

  describe ".enabled?" do
    it "returns true when the cdn config has a bucket" do
      Canvas::Cdn.config.merge! enabled: true, bucket: "bucket_name"
      expect(Canvas::Cdn.enabled?).to be true
    end

    it "returns false when the cdn config does not have a bucket" do
      Canvas::Cdn.config.merge! enabled: true, bucket: nil
      expect(Canvas::Cdn.enabled?).to be false
    end
  end

  describe ".config" do
    before { Canvas::Cdn.instance_variable_set(:@config, nil) }

    it "loads settings via Canvas.load_config_file_or_consul" do
      expect(Canvas).to receive(:load_config_file_or_consul)
        .with("canvas_cdn", failsafe_cache: true)
        .and_return("host" => "cdn.test", "bucket" => "b", "region" => "us-east-1")
      allow(Rails.application.credentials).to receive(:canvas_cdn_creds).and_return(nil)

      expect(Canvas::Cdn.config.host).to eq "cdn.test"
      expect(Canvas::Cdn.config.bucket).to eq "b"
      expect(Canvas::Cdn.config.region).to eq "us-east-1"
    end

    it "lets Rails credentials override the loaded config" do
      allow(Canvas).to receive(:load_config_file_or_consul)
        .and_return("aws_access_key_id" => "from-file-or-consul")
      allow(Rails.application.credentials).to receive(:canvas_cdn_creds)
        .and_return(aws_access_key_id: "from-creds")

      expect(Canvas::Cdn.config.aws_access_key_id).to eq "from-creds"
    end

    it "falls back cleanly when no source returns anything" do
      allow(Canvas).to receive(:load_config_file_or_consul).and_return(nil)
      allow(Rails.application.credentials).to receive(:canvas_cdn_creds).and_return(nil)

      expect(Canvas::Cdn.config.enabled).to be false
      expect(Canvas::Cdn.enabled?).to be false
    end
  end
end
