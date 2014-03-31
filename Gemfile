# What have they done to the Gemfile???
#
# Relax. Breathe deep. All the gems are still there; they're just loaded in various files in Gemfile.d/
# This allows us to require gems locally that we might not want to commit to our public repo. We can maintain
# a customized list of gems for development and debuggery, without affecting our ability to merge with canvas-lms
#
# NOTE: this file has to use 1.8.7 hash syntax to not raise a parser exception on 1.8.7
#
# NOTE: some files in Gemfile.d/ will have certain required gems indented. While this may seem arbitrary,
# it actually has semantic significance. An indented gem required in Gemfile is a gem that is NOT
# directly used by Canvas, but required by a gem that is used by Canvas. We lock into specific versions of
# these gems to prevent regression, and the indentation serves to alert us to the relationship between the gem and canvas-lms
source 'https://rubygems.org/'

require File.expand_path("../config/canvas_rails3", __FILE__)

Dir.glob(File.join(File.dirname(__FILE__), 'Gemfile.d', '*.rb')).sort.each do |file|
  eval File.read(file), binding, file
end
