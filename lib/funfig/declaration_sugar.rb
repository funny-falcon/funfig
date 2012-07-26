require "funfig/group"

module Funfig
  class ProxyParam < BasicObject
    def initialize(group)
      @group = group
    end
    def method_missing(name, value = NOT_SET, &block)
      unless value.equal? NOT_SET
        @group.param name, value
      else
        @group.param name, &block
      end
    end
  end

  class ProxyGroup < BasicObject
    def initialize(group)
      @group = group
    end
    def method_missing(name, &block)
      @group.group name, &block
    end
  end

  class ProxyRef < BasicObject
    def initialize(group)
      @group = group
    end
    def method_missing(name, group, &block)
      @group.reference name, group, &block
    end
  end

  class Group
    # syntax sugar proxy for declaring params
    #
    # :call-seq:
    #   conf = Funfig.new do
    #     p.name_of_param :default_value
    #     p.other_param { calculate_default }
    #   end
    def self.p
      @proxy_param ||= ProxyParam.new(self)
    end

    # syntax sugar proxy for declaring group
    #
    # :call-seq:
    #   conf = Funfig.new do
    #     g.name_of_group do
    #     end
    #   end
    def self.g
      @group_param ||= ProxyGroup.new(self)
    end

    # syntax sugar proxy for declaring references
    #
    # :call-seq:
    #   conf = Funfig.new do
    #     r.name_of_reference _.path.to.group do
    #     end
    #   end
    #
    #   conf = Funfig.new do
    #     r.name_of_reference _.path.to.group
    #   end
    def self.r
      @ref_param ||= ProxyRef.new(self)
    end
  end
end
