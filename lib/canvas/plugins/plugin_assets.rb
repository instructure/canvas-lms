# pull in the bundles from the various plugins' config/assets.yml extension
# files and combine them under a plugins.<plugin> dictionary. so e.g. the
# stylesheets bundles from {gems,vendor}/plugins/myplugin/config/assets.yml
# will be added under
#
# plugins:
#   myplugin:
#     stylesheets:
#       ...
#
# in the output. additionally, rescope bundle elements defined under public/
# (in the context of the plugin) as follows:
#
#  * public/stylesheets/compiled -> public/stylesheets/compiled/plugins/<plugin>
#  * public/* -> public/plugins/<plugin>/*
#
# i.e. public/x becomes public/plugins/myplugin/x with the exception of
# compiled stylesheets, where compass throws them in the more specific
# public/stylesheets/compiled/plugins/myplugin/
#
# to prevent this translation on a bundle element -- to request an element
# from canvas-lms in your bundle, for example -- prefix it with "~:". this
# prefix will be removed but no other changes made.
#
# similarly, a prefix of "otherplugin:" just as without a prefix, but the
# rescoping will target "otherplugin" rather than "myplugin". this is useful
# if myplugin can rely on otherplugin being installed and wishes to reuse
# some of the assets from otherplugin.


class PluginAssets
  attr_reader :anchors, :asset_matcher, :plugin_matcher

  def initialize( options = {} )
    @anchors = { 'stylesheets' => {} }
    @asset_matcher = options[:asset_matcher] || '{gems,vendor}/plugins/*/config/assets.yml'
    @plugin_matcher = options[:plugin_matcher] || %r{^(?:gems|vendor)/plugins/(.*)/config/assets\.yml$}
  end

  # this is the yaml that can be dropped into the top of assets.yml
  # to output the different plugin bundle definitions
  def bundle_yml

    subdoc = YAML.dump('plugins' => plugin_assets).gsub(/^---\s?\n/, '')

    # add anchors to the various bundles in the imported plugin asset definitions.
    # these bundles will be included in the known bundle types below with a
    # namespaced bundle name. for instance, the bar stylesheet bundle in the foo
    # plugin will be referred under stylesheets below as "plugins/foo/bar" and
    # use the corresponding anchor.
    #
    # I'd add the anchors programmatically instead of through post-processing of
    # the serialized document, but I couldn't figure out how
    subdoc.gsub!(%r{^( {6})plugins/([^/]*)/([^/]*)/([^:]*): ?$}) do |match|
      indent, plugin, type, bundle = $1, $2, $3, $4
      namespaced_bundle = "plugins_#{plugin}_#{bundle}"
      anchor = "#{type}_#{namespaced_bundle}"
      anchors[type][namespaced_bundle] = anchor if anchors[type]
      "#{indent}#{bundle}: &#{anchor}"
    end

    # for some reason the serialized document outputs as
    #
    # plugins:
    #   foo:
    #     stylesheets:
    #       bar: &anchor
    #       - value
    #
    # instead of
    #
    # plugins:
    #   foo:
    #     stylesheets:
    #       bar: &anchor
    #         - value
    #
    # both are equivalent without an anchor on bar, but with an anchor on bar,
    # the first for adds value to plugins.foo.stylesheets.bar but *not* to
    # *anchor. the second form adds value to both.
    subdoc.gsub!(%r{(^ {6})- (.*)$}, '\\1  - \\2')

    subdoc

  end

  def anchors_yml(options = {})
    indent_depth = options[:indent_depth] || 2
    indent_token = Array.new(indent_depth, ' ').join('')
    bundle_yml if anchors['stylesheets'].empty?
    anchors['stylesheets'].map { |(bundle, anchor)| "#{bundle}: *#{anchor}" }.join( "\n#{indent_token}" )
  end

  def plugin_assets
    return @plugin_assets if @plugin_assets

    @plugin_assets = {}
    for_each_plugin do |name, assets|
      assets.each do |type,bundles|
        bundles.keys.each do |bundle,entries|
          # the bundle is temporarily renamed to a fully namespaced bundle so
          # that we can detect and translate that namespace into an anchor in
          # post-processing.
          bundles["plugins/#{name}/#{type}/#{bundle}"] = bundles.
            delete(bundle).map { |entry| format_bundle_entry( entry, name ) }
        end
      end
      @plugin_assets[name] = assets
    end
    @plugin_assets
  end

  def for_each_plugin
    Dir.glob( asset_matcher ).sort.each do |asset_file|
      yield plugin_name_for(asset_file), YAML.load(File.read(asset_file))
    end
  end

  def format_bundle_entry(entry, plugin)
    entry.gsub(%r{^public/stylesheets/compiled/}, "~:public/stylesheets/compiled/plugins/#{plugin}/").
          gsub(%r{^public/}, "~:public/plugins/#{plugin}/").
          gsub(%r{^(\w+):public/stylesheets/compiled/}, "~:public/stylesheets/compiled/plugins/\\1/").
          gsub(%r{^(\w+):public/}, "~:public/plugins/\\1/").
          gsub(%r{^~:}, '')
  end

  def plugin_name_for(path)
    match = plugin_matcher.match(path)
    raise ArgumentError, 'must provide a valid plugin asset.yml path' unless match
    match[1]
  end
end
