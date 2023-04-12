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

module Canvas
  module Cdn
    class Registry
      class Gulp
        def initialize(manifest: nil)
          @asset_dir = "dist"
          @manifest = manifest || load_manifest_from_disk
          @files = Set.new(@manifest.values) { |x| realpath(x) }
        end

        def available?
          !@manifest.empty?
        end

        def include?(realpath)
          @files.include?(realpath)
        end

        def url_for(file)
          #   source looks like "/images/apple-touch-icon.png"
          #             or like "/dist/images/apple-touch-icon.png"
          # virtpath looks like "images/apple-touch-icon.png"
          # realpath looks like "/dist/images/apple-touch-icon-585e5d997d.png"
          if (fingerprinted = @manifest[virtpath(file)])
            realpath(fingerprinted)
          end
        end

        private

        def load_manifest_from_disk
          file = Rails.public_path.join("dist/rev-manifest.json")

          if file.exist?
            JSON.parse(file.read).freeze
          elsif Rails.env.production?
            raise "you must run \"gulp rev\" first"
          else
            {}
          end
        end

        def virtpath(source)
          normal = source.sub(%r{^/}, "")

          if normal.start_with?(@asset_dir)
            normal[@asset_dir.length + 1..]
          else
            normal
          end
        end

        def realpath(vfile)
          "/#{@asset_dir}/#{vfile}"
        end
      end
    end
  end
end
