module Funfig
  class Group
    # Update config by yaml file
    def load_yaml(filename)
      params = YAML.load_file(filename)
      update(params)
    end

    # Update config by evaluating ruby file
    def load_ruby(file)
      rb = File.read(file)
      instance_eval rb, file
    end
  end

  class Root
    # Load config for schema from yaml file
    def self.from_yaml_file(file)
      self.new.load_yaml(file)
    end

    # Evaluate config file inside of configuration object
    def self.from_ruby_file(file)
      self.new.load_ruby(file)
    end

    def self.from_file(file)
      case file
      when /\.yml$/, /\.yaml$/
        from_yaml_file(file)
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
