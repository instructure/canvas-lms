# frozen_string_literal: true

# What have they done to the Gemfile???
#
# Relax. Breathe deep. All the gems are still there; they're just loaded in various files in Gemfile.d/
# This allows us to require gems locally that we might not want to commit to our public repo. We can maintain
# a customized list of gems for development and debuggery, without affecting our ability to merge with canvas-lms
#
# NOTE: some files in Gemfile.d/ will have certain required gems indented. While this may seem arbitrary,
# it actually has semantic significance. An indented gem required in Gemfile is a gem that is NOT
# directly used by Canvas, but required by a gem that is used by Canvas. We lock into specific versions of
# these gems to prevent regression, and the indentation serves to alert us to the relationship between the gem and canvas-lms
source 'https://rubygems.org/'

# ensure we don't get confused if we're inside a symlink, and that
# symlink changes; we want the gems in our current directory,
# not a directory _named_ what our current directory is
root_path = Pathname.new(__FILE__).realpath.join("..")

Dir[root_path.join('gems/plugins/*/Gemfile.d/_before.rb')].each do |file|
  eval(File.read(file), nil, file)
end

require_relative "config/canvas_rails_switcher"

Dir.glob(root_path.join("Gemfile.d/*.rb")).sort.each do |file|
  eval(File.read(file), nil, file)
end
