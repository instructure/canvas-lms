# This is where we monkeypatch rails to look at the rev-manifest.json file we make in `gulp rev`
# instead of doing it's normal cache busting stuff on the url.
# eg: instead of '/images/whatever.png?12345', we want '/dist/images/whatever-<md5 of file>.png'.
# There is a different method that needs to be monkeypatched for rails 3 vs rails 4
if CANVAS_RAILS3
  module ActionView
    module Helpers
      module AssetTagHelper
        class AssetPaths
          private

            # Rails 3 expects us to override 'rewrite_asset_path' if we want to do something other than the
            # default "/images/whatever.png?12345".
            def rewrite_asset_path_with_rev_manifest(source, dir, options = nil)
              # our brandable_css stylesheets are already fingerprinted, we don't need to do anything to them
              return source if source =~ /^\/dist\/brandable_css/

              key = (source[0] == '/') ? source : "#{dir}/#{source}"
              Canvas::Cdn::RevManifest.url_for(key) || rewrite_asset_path_without_rev_manifest(source, dir, options)
            end
            alias_method_chain :rewrite_asset_path, :rev_manifest

        end
      end
    end
  end
else
  require 'action_view/helpers/asset_url_helper'
  module ActionView
    module Helpers
      module AssetUrlHelper

        # Rails 4 leaves us 'path_to_asset' to override instead.
        def path_to_asset_with_rev_manifest(source, options = {})
          original_path = path_to_asset_without_rev_manifest(source, options)
          revved_url = Canvas::Cdn::RevManifest.url_for(original_path)
          if revved_url
            File.join(compute_asset_host(revved_url, options).to_s, revved_url)
          else
            original_path
          end
        end
        alias_method_chain :path_to_asset, :rev_manifest

      end
    end
  end
end