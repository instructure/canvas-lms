#
# Copyright (C) 2011 Instructure, Inc.
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
#

include Helpers::FilterHelper

def init
  @breadcrumb = []

  @page_title = options[:title]

  if @file
    @contents = File.read_binary(@file)
    @file = File.basename(@file)
    sections :layout, [:diskfile]
  elsif object
    case object
    when '_index.html'
      sections :layout, [:index]
    when CodeObjects::Base
      type = object.root? ? :module : object.type
      #sections :layout, [T(type), T('disqus')]
      sections :layout, [T(type)]
    end
  else
    sections :layout, [:contents]
  end
end

def contents
  @contents
end

def index
  legitimate_objects = @objects.reject {|o| o.root? || !is_class?(o) || !o.meths.find { |m| !m.tags('API').empty? } }

  @resources = legitimate_objects.sort_by {|o| o.tags('API').first.text }

  erb(:index)
end

def diskfile
  "<div id='filecontents'>" +
  case (File.extname(@file)[1..-1] || '').downcase
  when 'htm', 'html'
    @contents
  when 'txt'
    "<pre>#{@contents}</pre>"
  when 'textile', 'txtile'
    htmlify(@contents, :textile)
  when 'markdown', 'md', 'mdown', 'mkd'
    htmlify(@contents, :markdown)
  else
    htmlify(@contents, diskfile_shebang_or_default)
  end +
  "</div>"
end

def diskfile_shebang_or_default
  if @contents =~ /\A#!(\S+)\s*$/ # Shebang support
    @contents = $'
    $1.to_sym
  else
    options[:markup]
  end
end
