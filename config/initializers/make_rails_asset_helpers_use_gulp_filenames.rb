module RevManifest
  def self.manifest
    # don't look this up every request in prduction
    return @manifest if ActionController::Base.perform_caching && defined? @manifest
    file = Rails.root.join('public', 'dist', 'rev-manifest.json')
    if file.exist?
      Rails.logger.debug "reading rev-manifest.json"
      @manifest = JSON.parse(file.read).freeze
    elsif Rails.env.production?
      raise "you need to run `gulp rev` first"
    else
      @manifest = {}.freeze
    end
  end

  def self.url_for(source)
    # remove the leading slash if there is one
    source = source.sub(/^\//, '')
    fingerprinted = manifest[source]
    "/dist/#{fingerprinted}" if fingerprinted
  end
end


# This is where we monkeypatch rails to look at the rev-manifest.json file we make in `gulp rev`
# instead of doing it's normal cache busting stuff on the url.
# eg: instead of '/images/whatever.png?12345', we want '/dist/images/whatever-<md5 of file>.png'
# There is a different method that needs to be monkeypatched for rails 3 vs rails 4
if CANVAS_RAILS3
  module ActionView
    module Helpers
      module AssetTagHelper
        class AssetPaths
          private

            # Rails 3 expects us to override 'rewrite_asset_path' if we want to do something other than the
            # default "/images/whatever.png?12345".
            def rewrite_asset_path_with_gulp_assets(source, dir, options = nil)
              # our brandable_css stylesheets are already fingerprinted, we don't need to do anything to them
              return source if source =~ /^\/dist\/brandable_css/

              key = (source[0] == '/') ? source : "#{dir}/#{source}"
              RevManifest.url_for(key) || rewrite_asset_path_without_gulp_assets(source, dir, options)
            end
            alias_method_chain :rewrite_asset_path, :gulp_assets

        end
      end
    end
  end
else
  require 'action_view/helpers/asset_url_helper'
  module ActionView
    module Helpers
      module AssetUrlHelper

        # Rails 4 leaves us 'compute_asset_path' to override instead.
        def compute_asset_path_with_gulp_assets(source, options = {})
          original_path = compute_asset_path_without_gulp_assets(source, options)
          RevManifest.url_for(original_path) || original_path
        end
        alias_method_chain :compute_asset_path, :gulp_assets

      end
    end
  end
end