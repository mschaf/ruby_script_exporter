module RubyScriptExporter
  class Type

    @types = {}

    def initialize(name, type, help = nil)
      @name = name
      @type = type
      @help = help
    end

    def self.register_type(name, type, help = nil)
      raise ArgumentError, "Type for measurement '#{name}' already registered." if @types.key?(name)

      @types[name.to_sym] = Type.new(name, type, help)
    end

    def self.from_name(name)
      type = @types[name.to_sym]

      unless type
        puts "Warning type for measurement #{name} not found, defaulting to gauge."
        type = register_type(name, :gauge)
      end

      type
    end

    def self.clear_types
      @types = {}
    end

    def format_for_open_metrics
      type_description = ''
      type_description << "# HELP #{@name} #{@help}\n" if @help
      type_description << "# TYPE #{@name} #{@type}"
      type_description
    end

  end
end