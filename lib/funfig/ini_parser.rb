require 'yaml'
require 'strscan'

module Funfig
  # fake ini file loader
  # loads *.ini file by converting it to YAML first
  class IniParser
    attr :hash
    attr_accessor :string

    def initialize(string = nil, file = nil)
      @string = string
      @file = file
    end

    def parse(string = @string, file = @file)
      raise "Should specify string for parse"  unless String === string
      prepare_parse(string, file)
      do_parse
      finish_parse
    end

    class << self
      def parse_file(file)
        if file.respond_to?(:read)
          new(file.read).parse
        else
          new(File.read(file), file).parse
        end
      end
    end
  private
    def prepare_parse(string, file)
      @file = file
      @scanner = StringScanner.new(string)
      @hash = {}
      @line_number = 0
    end

    def finish_parse
      @scanner = @line_number = nil
      @hash
    end

    def line_number(line = @line_number)
      if @file
        "#{@file}:#{line}"
      else
        line
      end
    end

    def do_parse
      section = "global"
      yaml = false
      while true
        skip_empty_lines!
        break if @scanner.eos?
        if @scanner.scan(/\s*\[\s*([-.\w]+)\s*\]/)
          section = @scanner[1]
        elsif @scanner.scan(/\s*([-.\w]+)\s*[:=]\s*/)
          param = @scanner[1]
          line_no = @line_number
          if @scanner.match?(/YAML([- #\[{"'<]|$)/)
            @scanner.skip(/YAML\s*/)
            yaml = true
          end

          if @scanner.scan(/\s*<<(\w+)/)
            multiline = @scanner[1]
            skip_eol!
            unless @scanner.scan(/(.*?)^([ \t]*)#{multiline}/m)
              raise "Multiline '#{multiline}' started at line #{line_number(line_no)} is not finished"
            end
            adjust_lineno!(@scanner[1])
            value = @scanner[1].chomp
            unless yaml
              value = unindent(value, @scanner[2])
            end
          else
            value = scan_value
          end

          if yaml
            value = YAML.load(value)
            yaml = false
          end

          set_value(section, param, value, line_no)
        else
          raise "Parse error at line #{line_number}"
        end
      end
    end

    EMPTY = /\s*([#;].*?)?(?:\r\n|\r|\n|\z)/
    def skip_eol!
      if (s = @scanner.skip(EMPTY)) && s > 0
        @line_number += 1
      end
    end

    def adjust_lineno!(str)
      @line_number += str.scan(/\r\n|\r|\n/).size
    end

    def skip_empty_lines!
      while skip_eol!; end
    end

    REPLACE_SQUOTE = {"\\'" => "'", "\\\\" => "\\"}
    REPLACE_DQUOTE = Hash.new{|h,k| h[k] = eval("\"#{k}\"")}
    def scan_value
      value = ''
      quoted = false
      while ! skip_eol! && ! @scanner.eos?
        if @scanner.skip(/[ \t]+/)
          value << ' '  unless value == ''
        end
        if @scanner.scan(/([^"'#;\s\r\n]+)/)
          value << @scanner[1]
        elsif s = @scanner.scan(/'((?:\\'|[^'])*)'/)
          quoted = true
          adjust_lineno!(s)
          value << @scanner[1].gsub(/\\[\\']/, REPLACE_SQUOTE)
        elsif s = @scanner.scan(/"(\\.|[^"]*)"/)
          quoted = true
          adjust_lineno!(s)
          # please, tell me how to do it cleaner
          val = @scanner[1].gsub(/\\(x[a-fA-F\d]{1,2}|u[a-fA-F\d]{4}|[^xu])/, REPLACE_DQUOTE)
          value << val
        else
          break
        end
      end

      return value  if quoted

      case value
      when '', 'null'
        nil
      when /\A[+-]?[1-9]\d*\z/
        value.to_i
      when /\A[+-]?\d*(\.\d+)?([eE][+-]?\d+)?\z/
        value.to_f
      when 'True', 'TRUE', 'true', 'Yes', 'yes'
        true
      when 'False', 'FALSE', 'false', 'No', 'no'
        false
      else
        value
      end
    end

    def set_value(section, param, value, line_no)
      key = "#{section}.#{param}"
      seq = key.split('.')
      seq.shift  if seq.first == 'global'
      hash = @hash
      path = []
      while seq.size > 1
        path << seq.shift
        if current = hash[path.last]
          unless Hash === current
            raise "Could not insert [#{section}] #{param} on line #{line_number(line_no)} cause #{path.join('.')} is not a hash"
          end
        else
          hash[path.last] = current = {}
        end
        hash = current
      end
      hash[seq.first] = value
    end

    def count_space(line)
      n, i = 0, 0
      while true
        if line[i] == ?\x20
          n += 1
        elsif line[i] == ?\t
          n = (n / 8) * 8 + 8
        else
          break
        end
        i += 1
      end
      n
    end

    def skip_space(line, nspace)
      n, i = 0, 0
      while n < nspace
        if line[i] == ?\x20
          n += 1
        elsif line[i] == ?\t
          n = (n / 8) * 8 + 8
        else
          break
        end
        i += 1
      end
      raise unless n >= nspace
      (" "*(n - nspace) + line[i..-1])
    end

    def unindent(value, space)
      nspace = count_space(space)
      value.each_line.map{|line| skip_space(line, nspace)}.join
    end

  end
end
