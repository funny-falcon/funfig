require "funfig/group"

module Funfig
  NOT_SET = Object.new.freeze
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

  class Group
    # syntax sugar proxy for declaring params
    #
    # :call-seq
    #   conf = Funfig.new do
    #     p.name_of_param :default_value
    #     p.other_param { calculate_default }
    #   end
    def self.p
      @proxy_param ||= ProxyParam.new(self)
    end

    # syntax sugar proxy for declaring group
    #
    # :call-seq
    #   conf = Funfig.new do
    #     g.name_of_group do
    #     end
    #   end
    def self.g
      @group_param ||= ProxyGroup.new(self)
    end
  end
end
