require 'funfig/group'
module Funfig
  # :stopdoc:
  class Root < Group
    attr_reader :_cache
    def initialize
      @_cache = {}
    end

    def _cache_clear!
      @_cache.clear
    end

    def _parent
      raise "Already at root"
    end

    def _
      self
    end

    def self._path
      ""
    end

    def self._sub_name(name)
      name.to_s
    end
  end
  # :startdoc:
end
