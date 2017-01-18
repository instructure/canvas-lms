require 'set'

# An interface to the manifest file created by `gulp rev`
module Canvas
  module Cdn
    module RevManifest
      class << self
        delegate :include?, to: :revved_urls

        def manifest
          load_data_if_needed
          @manifest
        end

        def revved_urls
          load_data_if_needed
          @revved_urls
        end

        def url_for(source)
          # remove the leading slash if there is one
          source = source.sub(/^\//, '')
          fingerprinted = manifest[source]
          "/dist/#{fingerprinted}" if fingerprinted
        end

        private
        def load_data_if_needed
          # don't look this up every request in prduction
          return if ActionController::Base.perform_caching && defined? @manifest
          file = Rails.root.join('public', 'dist', 'rev-manifest.json')
          if file.exist?
            Rails.logger.debug "reading rev-manifest.json"
            @manifest = JSON.parse(file.read).freeze
          elsif Rails.env.production?
            raise "you need to run `gulp rev` first"
          else
            @manifest = {}.freeze
          end
          @revved_urls = Set.new(@manifest.values.map{|s| "/dist/#{s}" }).freeze
        end

      end
    end
  end
end