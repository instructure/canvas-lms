# See https://groups.google.com/forum/#!msg/rubyonrails-core/gb5woRkmDlk/iQ2G7jjNWKkJ
if RUBY_VERSION >= "1.9.3"
  MissingSourceFile::REGEXPS << [/^cannot load such file -- (.+)$/i, 1]
end
