require 'funfig/load_proxy'
require 'funfig/ini_parser'
module Funfig
  class Group
    # Update config by yaml file
    def load_yaml(filename)
      params = YAML.load_file(filename)
      update(params)
    end

    # Update config by yaml string
    def load_yaml_string(string)
      params = YAML.load(string)
      update(params)
    end

    # Update config by ini file
    def load_ini(filename)
      params = IniParser.parse_file(filename)
      update(params)
    end

    # Update config by ini string
    def load_ini_string(string, file = nil)
      params = IniParser.new.parse(string, file)
      update(params)
    end

    # Update config by evaluating ruby file
    def load_ruby(file)
      rb = File.read(file)
      load_ruby_string(rb, file)
    end

    # Update config by evaluating string containing ruby code
    def load_ruby_string(string, file = nil)
      unless file
        for cl in caller
          next  if cl =~ %r{funfig/load\.rb}
          file, line = caller.first.match(/^(.*):(\d*)/).captures
          break
        end
      end
      LoadProxy.new(self).instance_eval string, file, line.to_i
    end

    # Update config by executing block inside of proxy
    def exec(&block)
      LoadProxy.new(self).instance_exec &block
    end
  end

  class Root
    # Load config from yaml file
    def self.from_yaml_file(file)
      self.new.load_yaml(file)
    end

    # Load config from ini file
    def self.from_ini_file(file)
      self.new.load_ini(file)
    end

    # Evaluate config file inside of configuration object
    def self.from_ruby_file(file)
      self.new.load_ruby(file)
    end

    def self.from_file(file)
      case file
      when /\.yml$/, /\.yaml$/
        from_yaml_file(file)
      when /\.ini$/
        from_ini_file(file)
      when /\.rb$/
        from_ruby_file(file)
      when Hash
        if fl = file[:yaml]
          from_yaml_file(fl)
        elsif fl = file[:ruby]
          from_ruby_file(fl)
        end
      end
    end
  end
end
