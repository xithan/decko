require 'rails/command/environment_argument'
require 'rails/commands/rake/rake_command'

module Card
  module Command
    class SeedCommand < ::Rails::Command::Base
      include ::Rails::Command::EnvironmentArgument
      class_option :environment, aliases: "-e", type: :string,
        desc: "Specifies the datbabase to seed (test/development/production)."

      class_option :all, aliases: "-a", type: :boolean,
                   desc: "Seed all environments (test, development, and production)."

      class_option :scratch, aliases: "-s", type: :boolean,
                   desc: "Drop and re-create database."

      # class_option :development, aliases: "-d", type: :boolean,
      #              desc: "Shorthand for '-e development'"
      #
      # class_option :production, aliases: "-p", type: :boolean,
      #                    desc: "Shorthand for '-e production'"
      #
      # class_option :test, aliases: "-t", type: :boolean,
      #                          desc: "Shorthand for '-e test'"

      class_option :update, aliases: "-u", type: :boolean,
                               desc: "Update seed data."


      desc 'seed', 'Seed database'
      def perform
        envs =
          if options[:all]
            %w[production development test]
          else
            extract_environment_option_from_argument
            [options[:environment]]
          end

        # RAILS_ENV needs to be set before config/application is required.
        envs.each do |env|
          ENV["RAILS_ENV"] = env
          drop_db if options[:scratch]

          require_application_and_environment!
          ENV["SCHEMA"] ||= "#{Cardio.gem_root}/db/schema.rb"
          ::Rails::Command::RakeCommand.perform "db:seed"
        end
      end

      def drop_db
        ::Rails::Command::RakeCommand.perform("db:drop")
      rescue
        puts "dropped failed"
      end
    end
  end
end

