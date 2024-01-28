module RubyScriptExporter
  module Util

    def self.counterize(string, count)
      string = string.prepend('s') if count != 1

      "#{count} #{string}"
    end

  end
end
