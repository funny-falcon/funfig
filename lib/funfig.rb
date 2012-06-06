require "funfig/version"
require "funfig/group"
require "funfig/root"
require "funfig/declaration_sugar"
require "funfig/load"
require "yaml" unless defined? YAML

module Funfig
  # Create configuration schema
  #
  # :call-seq:
  def self.new(&block)
    conf = Class.new(Root)
    conf.class_exec &block
    conf
  end
end
