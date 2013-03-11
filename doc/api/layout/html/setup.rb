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
    if @file.is_a?(String)
      @contents = File.read(@file)
      @file = File.basename(@file)
    else
      @contents = @file.contents
      @file = File.basename(@file.path)
    end
    def @object.source_type; nil; end
    sections :layout, [:diskfile]
  elsif options[:all_resources]
    sections :layout, [T('topic')]
    sections[:layout].push(T('appendix')) if DOC_OPTIONS[:all_resource_appendixes]
  elsif options[:controllers]
    sections :layout, [T('topic'), T('appendix')]
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
  content = "<div id='filecontents'>" +
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
  options.delete(:no_highlight)
  content
end

def diskfile_shebang_or_default
  if @contents =~ /\A#!(\S+)\s*$/ # Shebang support
    @contents = $'
    $1.to_sym
  else
    options[:markup]
  end
end
