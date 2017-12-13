require 'rails/command/environment_argument'
require 'rails/commands/rake/rake_command'

class Card
  module Command
    class MigrateCommand < Base
      class_option :environment, aliases: "-e", type: :string,
                   desc: "Specifies the database to migrate to (test/development/production)."

      class_option :structure, aliases: "-s", type: :boolean,
                   desc: "Run structure migrations."

      class_option :gem, aliases: "-g", type: :boolean,
                   desc: "Run structure and core card migrations"

      class_option :deck, aliases: "-d", type: :boolean,
                         desc: "Run only deck card migrations"

      class_option :redo, aliases: "-r", type: :boolean,
                   desc: "Rerun the migration specified by the version argument"

      class_option :version, aliases: "-v", type: :string

      class_option :verbose, type: :boolean

      class_option :stamp, type: :boolean


      desc 'seed', 'Seed database'
      def perform
        ENV["NO_RAILS_CACHE"] = "true"
        ENV["RAILS_ENV"] = options[:environment]
        options[:stamp] = true if ENV["STAMP_MIGRATIONS"]

        require_application_and_environment!
        require_dependency "card"
        ActiveRecord::Migration.verbose = options[:verbose]
        run_migrations
      end

      private

      def run_migrations
        structure  if run_all? || options[:gem] || options[:structure]
        core_cards if run_all? || options[:gem]
        deck_cards if run_all? || options[:deck]
      end

      def run_all?
        !options[:gem] && !options[:structre] && !options[:deck]
      end

      def core_cards
        require "card/migration/core"
        run_migration :core_cards
      end

      def deck_cards
        require "card/migration"
        run_migration :deck_cards
      end

      def structure
        run_migration :structure do
          ::Rails::Command::RakeCommand.perform "db:_dump" # write schema.rb
        end
      end

      def stamp type
        return unless options[:stamp]

        prepare_db_operation
        stamp_file = Cardio.schema_stamp_path(type)

        Cardio.schema_mode type do
          version = ActiveRecord::Migrator.current_version
          if version.to_i > 0 && (file = open(stamp_file, "w"))
            puts ">>  writing version: #{version} to #{stamp_file}"
            file.puts version
          end
        end
      end

      def redo_migration
        raise "version argument is required" unless options[:version]
        ActiveRecord::Migration.verbose = verbose
        ActiveRecord::SchemaMigration.where(options[:redo]).delete_all
        ActiveRecord::Migrator.run :up, Cardio.migration_paths(:deck_cards),
                                   options[:redo]
      end

      def run_migration migration_type
        prepare_db_operation migration_type

        Cardio.schema_mode(migration_type) do |paths|
          ActiveRecord::Migrator.migrations_paths = paths
          ActiveRecord::Migrator.migrate paths, options[:version]
          yield if block_given?
        end
        stamp migration_type
      end

      def prepare_db_operation migration_type=nil
        ENV["SCHEMA"] ||= "#{Cardio.gem_root}/db/schema.rb"
        Card::Cache.reset_all
        Card.config.action_mailer.perform_deliveries = false
        reset_column_information if migration_type.in? %i[deck_cards core_cards]
      end

      def reset_column_information
        Card.reset_column_information
        Card::Reference.reset_column_information
      end
    end
  end
end

