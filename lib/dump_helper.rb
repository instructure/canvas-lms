require 'set'

module DumpHelper
  class << self
    def find_dump_error(val, key = "<toplevel>", prefix = "", __visited_dump_vars = Set.new)
      return true if __visited_dump_vars.include?(val)
      __visited_dump_vars << val

      Marshal.dump(val)
      false
    rescue TypeError

      # see if anything inside val can't be dumped...
      sub_prefix = "#{prefix}#{key} (#<#{val.class}>) => "

      if val.respond_to?(:marshal_dump)
        result = find_dump_error(val.marshal_dump, "marshal_dump", sub_prefix, __visited_dump_vars)
        return result if result
      else
        results = []
        # instance var?
        results << val.instance_variables.map do |k|
          v = val.instance_variable_get(k)
          find_dump_error(v, k, sub_prefix, __visited_dump_vars)
        end.any?

        # hash key/value?
        val.each_pair do |k, v|
          results << find_dump_error(k, "hash key #{k}", sub_prefix, __visited_dump_vars)
          results << find_dump_error(v, "[#{k.inspect}]", sub_prefix, __visited_dump_vars)
        end if val.respond_to?(:each_pair)

        # array element?
        val.each_with_index do |v, i|
          results << find_dump_error(v, "[#{i}]", sub_prefix, __visited_dump_vars)
        end if val.respond_to?(:each_with_index)
        return true if results.any?
      end

      # guess it's val proper
      raise TypeError.new("Unable to dump #{prefix}#{key} (#<#{val.class}>): #{$!}")
    end
  end
end
