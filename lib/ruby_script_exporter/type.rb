module RubyScriptExporter
  class Type

    attr_reader :global

    @types = {}

    def initialize(name, type, help = nil, global: false)
      @name = name
      @type = type
      @help = help
      @global = global
    end

    def self.register_type(name, type, help = nil, global: false)
      raise ArgumentError, "Type for measurement '#{name}' already registered." if @types.key?(name)

      @types[name.to_sym] = Type.new(name, type, help, global: global)
    end

    def self.from_name(name)
      type = @types[name.to_sym]

      unless type
        puts "Warning type for measurement #{name} not found, defaulting to gauge."
        type = register_type(name, :gauge)
      end

      type
    end

    def self.types
      @types
    end

    def self.reset_types
      @types = @types.select { |_, v| v.global }
    end

    def format_for_open_metrics
      type_description = ''
      type_description << "# HELP #{@name} #{@help}\n" if @help
      type_description << "# TYPE #{@name} #{@type}"
      type_description
    end

  end
end