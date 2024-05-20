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
      class Webpack
        def initialize(environment:, manifest: nil)
          @asset_dir = if environment == "production"
                         "dist/webpack-production"
                       else
                         "dist/webpack-dev"
                       end
          @manifest = manifest || load_manifest_from_disk
          @files = Set.new(@manifest.values.flatten.uniq) { |x| realpath(x) }
        end

        def available?
          !@manifest.empty?
        end

        def include?(realpath)
          @files.include?(realpath)
        end

        def scripts_for(bundle)
          if @manifest.key?(bundle)
            [realpath(@manifest[bundle])]
          else
            []
          end
        end

        def entries
          # contains -entry- in filename, ends in .js, but doesn't end in .map.js
          all_entries = @manifest.values.grep(/-entry-.*\.js$/).grep_v(/\.map\.js$/).map { |x| realpath(x) }

          # partition entries into main and others
          main_entry, other_entries = all_entries.partition { |x| x.include? "main-entry" }

          # load other entries first, then main entry
          other_entries + main_entry
        end

        private

        def load_manifest_from_disk
          file = Rails.root.join("public/#{@asset_dir}/webpack-manifest.json")

          if file.exist?
            JSON.parse(file.read).freeze
          elsif Rails.env.production?
            raise "you must run \"webpack\" first"
          else
            {}
          end
        end

        def realpath(vfile)
          "/#{@asset_dir}/#{vfile}"
        end
      end
    end
  end
end
