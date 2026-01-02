# frozen_string_literal: true

require "lint_roller"

module RuboCop
  module Markdown
    # A plugin that integrates rubocop-md with RuboCop's plugin system.
    class Plugin < LintRoller::Plugin
      def about
        LintRoller::About.new(
          name: "rubocop-md",
          version: VERSION,
          homepage: "https://github.com/rubocop/rubocop-md",
          description: "Run RuboCop against your Markdown files to make sure " \
                       "that code examples follow style guidelines."
        )
      end

      def supported?(context)
        context.engine == :rubocop
      end

      def rules(_context)
        LintRoller::Rules.new(
          type: :path,
          config_format: :rubocop,
          value: Pathname.new(__dir__).join("../../../config/default.yml")
        )
      end
    end
  end
end
