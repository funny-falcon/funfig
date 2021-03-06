module Funfig
  NOT_SET = Object.new.freeze
  class Group
    def initialize(parent=nil) # :nodoc:
      @parent = parent
    end

    # Get enclosing group
    def _parent
      @parent
    end

    # Get root of configuration
    # :call-seq:
    #   _
    #   _root
    def _root
      @parent._root
    end
    alias _ _root

    # Update config by hash
    def update(hash)
      if hash.respond_to?(:each)
        hash.each{|k, v|
          k = k.to_s.gsub('-', '_')
          self.send("#{k}=", v)
        }
      else
        raise "Could not use #{hash} as value for group #{_path}"
      end
      self
    end

    # Iterate over parameter names
    def each_param
      return to_enum(:each_param) unless block_given?
      self.class._params.each{|k, _|
        yield k
      }
    end

    # Iterate over parameters and values
    # If called with parameter +true+, then iterate only over explicit setted parameters
    #
    # :call-seq:
    #    config.each{|name, value| puts "#{name} = #{value}"}
    #    config.each(true){|name, value| puts "#{name} = #{value}"}
    def each(explicit=false)
      return to_enum(:each, explicit) unless block_given?
      self.class._params.each{|k, _|
        yield k, send(k)  unless explicit && !instance_variable_defined?("@#{k}")
      }
    end

    # Convert configuration to hash
    # If called with parameter +true+ than consider only explicit setted parameters
    def to_hash(explicit=false)
      h = {}
      each(explicit){|k, v|
        if Group === v
          v = v.to_hash(explicit)
          next  if explicit && v.empty?
        end
        h[k] = v
      }
      h
    end

    def to_yaml(explicit=false)
      to_hash(explicit).to_yaml
    end

    def to_json(explicit=false)
      to_hash(explicit).to_json
    end

    # Imitate aget
    def [](k)
      if self.class._params[k.to_sym]
        send(k)
      else
        raise "Attempt to get not existed param #{_sub_name(k)}"
      end
    end

    # Imitate aset
    def []=(k, v)
      if self.class._params[k.to_sym]
        send("#{k}=", v)
      else
        raise "Attempt to set not existed param #{_sub_name(k)}"
      end
    end

    def inspect
      "<#{self.class.name} #{each.map{|k,v| "#{k}=#{v.inspect}"}.join(' ')}>"
    end

    # :stopdoc:

    def _cache_get(k, &block)
      _._cache.fetch(_sub_name(k), NOT_SET)
    end

    def _cache_set(k, v)
      _._cache[_sub_name(k)] = v
    end

    def _sub_name(name)
      self.class._sub_name(name)
    end

    def _path
      self.class._path
    end

    def method_missing(name, *args)
      raise "Not existed param #{_sub_name(name.to_s.sub(/=$/,''))}"
    end

    def self._params
      @params ||= {}
    end

    def self.initialize_clone(arg)
      super
      if @params
        params, @params = @params, {}
        params.each{|name, par|
          if par.is_a?(Class) && Group >= par
            @params[name] = par.clone
          else
            @params[name] = par
          end
        }
      end
    end

    def self._sub_name(name)
      "#{_path}.#{name}"
    end

    # :startdoc:

    def self._parent
      @parent
    end

    def self._root
      @parent._root
    end

    def self._
      _root
    end

    def self.method_missing(name, *args)
      (args.empty? && _params[name.to_sym]) || super
    end

    def self._path_proc
      eval "lambda{ #{_path} }"
    end

    # Define named group of values
    #
    # :call-seq:
    #   config = Funfig.new do
    #     group :name_of_group do
    #     end
    #   end
    def self.group(name, &block)
      name = name.to_sym
      vname = :"@#{name}"
      _prev = _params[name]
      klass = _prev.is_a?(Class) && Group >= _prev ? _prev : Class.new(Group)
      _params[name] = klass
      path = _sub_name(name)
      const_set name.to_s.gsub(/(^|_)([a-z])/){ $2.upcase }, klass

      klass.send(:define_singleton_method, :_path) do
        path
      end
      klass.instance_variable_set(:@parent, self)

      define_method(name) do
        instance_variable_get(vname) ||
          instance_variable_set(vname, self.class._params[name].new(self))
      end

      define_method("#{name}=") do |hash|
        send(name).update(hash)  if hash
      end

      define_method("#{name}_reset!") do
        _._cache_clear!
        remove_instance_variable(vname)  if instance_variable_defined?(vname)
      end
      klass.class_exec(&block)
      klass
    end

    # define named parameter
    #
    # :call-seq:
    #   config = Funfig.new do
    #     param :name_of_param do calculate_default_value end
    #   end
    def self.param(name, value = NOT_SET, &block)
      _params[name] = true
      vname = :"@#{name}"
      name = name.to_sym

      unless block || value == NOT_SET
        block = proc{
          begin
            value.dup
          rescue TypeError
            block = proc { value }
            value
          end
        }
      end

      define_method(name) do
        if instance_variable_defined?(vname)
          instance_variable_get(vname)
        else
          if (v = _cache_get(name)).equal? NOT_SET
            raise "Parameter #{_sub_name(name)} must be set!" unless block
            _cache_set(name, (v = instance_exec &block))
          end
          v
        end
      end

      alias_method :"#{name}?", name

      define_method("#{name}=") do |v|
        _._cache_clear!
        instance_variable_set(vname, v)
      end

      define_method("#{name}_reset!") do
        _._cache_clear!
        remove_instance_variable(vname)  if instance_variable_defined?(vname)
      end
    end

    # Create a reference to other group in config
    #
    # :call-seq:
    #   conf = Funfug.new do
    #     group :some do
    #       group :origin do
    #         param :first, 1
    #         param :second, 2
    #       end
    #     end
    #     group :awe do
    #       reference :copy, _.some.origin do
    #         # implicitly added:
    #         # param :first do _.some.origin.first end
    #         # param :second do _.some.origin.second end
    #         param :third, 3
    #       end
    #     end
    def self.reference(name, refered, &block)
      path_proc = refered._path_proc
      refered_params = refered._params
      group name do
        refered_params.each do |name, value|
          if value == true
            param(name){ instance_exec(&path_proc).send(name) }
          else
            reference(name, value)
          end
        end
        class_exec &block  if block
      end
    end

    # Create a copy of configuration scheme
    #
    # :call-seq:
    #   other_conf = config.clone do
    #     param :other_value do other_default end
    #   end
    #
    def self.clone(&block)
      new = super
      new.class_exec &block  if block_given?
      new
    end

    def self.drained
      klone = clone
      for par, val in _params
        if val.is_a?(Class) && Group > val
          klone._params[par] = val.drained
        else
          klone.param(par)
        end
      end
      klone
    end

    def self.as_root
      params = _params
      new_root = Funfig.new do
        for par, val in params
          if val.is_a?(Class) && Group > val
            _params[par] = val.drained
            group(par){ }
          else
            param(par)
          end
        end
      end
    end
  end
end
