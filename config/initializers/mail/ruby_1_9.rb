module Mail
  class Ruby19
    raise 'mail gem version has changed from 2.5.3: check these patches against the new mail gem' if Mail::VERSION.version > '2.5.3'

    # Updating the fix_encoding function to match the pick_encoding function from the gem's master branch:
    # This will fix encoding issues we've run into with ks_c_5601-1987 and gb2312

    # latest version:
    def Ruby19.fix_encoding(charset)
      case charset

      # ISO-8859-15, ISO-2022-JP and alike
      when /iso-?(\d{4})-?(\w{1,2})/i
        "ISO-#{$1}-#{$2}"

      # "ISO-2022-JP-KDDI"  and alike
      when /iso-?(\d{4})-?(\w{1,2})-?(\w*)/i
        "ISO-#{$1}-#{$2}-#{$3}"

      # UTF-8, UTF-32BE and alike
      when /utf-?(\d{1,2})?(\w{1,2})/i
        "UTF-#{$1}#{$2}".gsub(/\A(UTF-(?:16|32))\z/, '\\1BE')

      # Windows-1252 and alike
      when /Windows-?(.*)/i
        "Windows-#{$1}"

      when /^8bit$/
        Encoding::ASCII_8BIT

      # Microsoft-specific alias for CP949 (Korean)
      when 'ks_c_5601-1987'
        Encoding::CP949

      # Wrongly written Shift_JIS (Japanese)
      when 'shift-jis'
        Encoding::Shift_JIS

      # GB2312 (Chinese charset) is a subset of GB18030 (its replacement)
      when /gb2312/i
        Encoding::GB18030

      else
        charset
      end
    end

  end
end
