require 'set'

# An interface to the manifest file created by `gulp rev` and webpack
module Canvas
  module Cdn
    module RevManifest
      class << self

        def include?(source)
          if webpack_request?(source)
            webpack_revved_urls.include?(source)
          else
            gulp_revved_urls.include?(source)
          end
        end

        def gulp_manifest
          load_gulp_data_if_needed
          @gulp_manifest
        end

        def webpack_manifest
          load_webpack_data_if_needed
          @webpack_manifest
        end

        def gulp_revved_urls
          load_gulp_data_if_needed
          @gulp_revved_urls
        end

        def webpack_revved_urls
          load_webpack_data_if_needed
          @webpack_revved_urls
        end

        def webpack_request?(source)
          source =~ Regexp.new(webpack_dir)
        end

        def webpack_prod?
          ENV['USE_OPTIMIZED_JS'] == 'true' || ENV['USE_OPTIMIZED_JS'] == 'True'
        end

        def webpack_dir
          if webpack_prod?
            'dist/webpack-production'
          else
            'dist/webpack-dev'
          end
        end

        def webpack_url_for(source)
          # source will look something like: "dist/webpack-prod/vendor.js"
          # the manifest looks something like: {"vendor.js" : "vendor.bundle-d4be58c989364f9fe7db.js", ...}
          # we want to return something like: "/dist/webpack-prod/vendor.bundle-d4be58c989364f9fe7db.js"
          key = source.sub(webpack_dir + '/', '')
          fingerprinted = webpack_manifest[key]
          "/#{webpack_dir}/#{fingerprinted}" if fingerprinted
        end

        def url_for(source)
          # remove the leading slash if there is one
          source = source.sub(/^\//, '')
          if webpack_request?(source)
            webpack_url_for(source)
          else
            fingerprinted = gulp_manifest[source]
            "/dist/#{fingerprinted}" if fingerprinted
          end
        end

        private
        def load_gulp_data_if_needed
          return if ActionController::Base.perform_caching && defined? @gulp_manifest
          file = Rails.root.join('public', 'dist', 'rev-manifest.json')
          if file.exist?
            Rails.logger.debug "reading rev-manifest.json"
            @gulp_manifest = JSON.parse(file.read).freeze
          elsif Rails.env.production?
            raise "you need to run `gulp rev` first"
          else
            @gulp_manifest = {}.freeze
          end
          @gulp_revved_urls = Set.new(@gulp_manifest.values.map{|s| "/dist/#{s}" }).freeze
        end

        def load_webpack_data_if_needed
          return if (ActionController::Base.perform_caching || webpack_prod?) && defined? @webpack_manifest
          file = Rails.root.join('public', webpack_dir, 'webpack-manifest.json')
          if file.exist?
            Rails.logger.debug "reading #{file}"
            @webpack_manifest = JSON.parse(file.read).freeze
          else
            raise "you need to run webpack"
          end
          @webpack_revved_urls = Set.new(@webpack_manifest.values.map{|s| "/#{webpack_dir}/#{s}" }).freeze
        end

      end
    end
  end
end
