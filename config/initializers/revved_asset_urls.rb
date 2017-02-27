# This is where we monkeypatch rails to look at the rev-manifest.json file we make in `gulp rev`
# instead of doing it's normal cache busting stuff on the url.
# eg: instead of '/images/whatever.png?12345', we want '/dist/images/whatever-<md5 of file>.png'.
# There is a different method that needs to be monkeypatched for rails 3 vs rails 4
require 'action_view/helpers/asset_url_helper'
module RevAssetPaths
  def path_to_asset(source, options = {})
    original_path = super
    revved_url = Canvas::Cdn::RevManifest.url_for(original_path)
    if revved_url
      File.join(compute_asset_host(revved_url, options).to_s, revved_url)
    else
      original_path
    end
  end
end
ActionView::Base.include(RevAssetPaths)
