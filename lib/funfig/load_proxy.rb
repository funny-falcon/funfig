module Funfig
  class LoadProxy < BasicObject
    def initialize(group)
      @group = group
      methods = {}
      group.public_methods(false).each{|m| methods[m] = true}
      @methods = methods
      @params = @group.class._params
    end

    def _parent
      @group._parent
    end

    def _root
      @group._root
    end
    alias _ _root

    def method_missing(name, *args, &block)
      if @methods.include?(name)
        if par = @params[name]
          if par.is_a?(::Class) && par < Group && args.empty? && block
            proxy = LoadProxy.new(@group.send(name))
            proxy.instance_exec &block
          elsif !args.empty?
            raise "Could not pass both block and value for option"  if block
            raise "Could set only single value for option"  if args.size > 1
            @group.send("#{name}=", args[0])
          else
            @group.send(name)
          end
        else
          @group.send(name, *args, &block)
        end
      else
        ::Kernel.raise ::NotImplementedError, "no configuration option #{@group._sub_name(name)}"
      end
    end
  end
end
