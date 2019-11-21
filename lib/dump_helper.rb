require 'set'

module DumpHelper
  class << self
    def find_dump_error(val, key = "<toplevel>", prefix = "", __visited_dump_vars = Set.new)
      return if __visited_dump_vars.include?(val)
      __visited_dump_vars << val

      Marshal.dump(val)
    rescue TypeError

      if $!.message == "singleton can't be dumped" && !val.singleton_methods.empty?
        raise TypeError, "Unable to dump #{prefix}#{key} (#<#{val.class}>): #{$!}"
      end

      # see if anything inside val can't be dumped...
      sub_prefix = "  #{prefix}#{key} (#<#{val.class}>) => "

      if val.respond_to?(:marshal_dump, true)
        return find_dump_error(val.marshal_dump, "marshal_dump", sub_prefix, __visited_dump_vars)
      elsif val.respond_to?(:_dump, true)
        stringval = val._dump(-1)
        unless stringvals.instance_variables.empty?
          dump_ivars(stringval, "#{sub_prefix}_dump => ", __visited_dump_vars)
        else
          dump_ivars(val, sub_prefix, __visited_dump_vars)
        end
        return
      else
        dump_ivars(val, sub_prefix, __visited_dump_vars)

        if val.is_a?(Hash) || val.is_a?(Struct)
          val.each_pair do |k, v|
            find_dump_error(k, "hash key #{k}", sub_prefix, __visited_dump_vars)
            find_dump_error(v, "[#{k.inspect}]", sub_prefix, __visited_dump_vars)
          end
        elsif val.is_a?(Array)
          val.each_with_index do |v, i|
            find_dump_error(v, "[#{i}]", sub_prefix, __visited_dump_vars)
          end if val.is_a?(Array)
        else
          # guess it's val proper
          raise TypeError.new("Unable to dump #{prefix}#{key} (#<#{val.class}>): #{$!}")
        end
      end
    end

    private

    def dump_ivars(val, sub_prefix, __visited_dump_vars)
      val.instance_variables.map do |k|
        v = val.instance_variable_get(k)
        find_dump_error(v, k, sub_prefix, __visited_dump_vars)
      end
    end
  end
end
