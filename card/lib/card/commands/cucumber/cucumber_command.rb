require 'rails/command/environment_argument'
require 'rails/commands/rake/rake_command'
require 'card/command/system_exec'

class Card
  module Command
    class CucumberCommand < Base
      include ::Card::Command::SystemExec
      include ::Rails::Command::EnvironmentArgument

      no_commands do
        def help
          # super
          puts self.class.desc
        end
      end

      parser.banner = "Usage: decko cucumber [DECKO ARGS] -- [CUCUMBER ARGS]\n\n"
          parser.separator <<-EOT.strip_heredoc

             DECKO ARGS
          EOT
          opts[:env] = ["RAILS_ROOT=."]
          parser.on("-d", "--debug", "Drop into debugger on failure") do |a|
            opts[:env] << "DEBUG=1" if a
          end
          parser.on("-f", "--fast", "Stop on first failure") do |a|
            opts[:env] << "FAST=1" if a
          end
          parser.on("-l", "--launchy", "Open page on failure") do |a|
            opts[:env] << "LAUNCHY=1" if a
          end
          parser.on("-s", "--step", "Pause after each step") do |a|
            opts[:env] << "STEP=1" if a
          end
          parser.on("--[no-]spring", "Run with spring") do |spring|
            opts[:executer] =
              if spring
               "spring"
              else
               "bundle exec"
              end
          end


      class_option :spec, aliases: "-d", type: :string, # FILENAME(:LINE)
                   desc: "Run spec for a Decko deck file"
      class_option :core, aliases: "-c", type: :string,
                   desc: "Run spec for a Decko core file"
      class_option :mod, aliases: "-m", type: :string,
                   desc: "Run all specs for a mod or matching a mod"

      class_option :simplecov, aliases: "-s", type: :boolean,
                   desc: "Run with simplecov (defauls to on if the whole test suite is run)"
      class_option :rescue, aliases: "-r", type: :boolean,
                   desc: "Run with pry-rescue"
      class_option :spring, type: :boolean,
                   desc: "Run with spring"


      def perform
        process_file_options
        @decko_args, @rspec_args = split_args args
        run_command
      end

      private

      def command
        "#{env_args} #{executer} rspec #{@rspec_args.shelljoin} #{@files} "\
           "--exclude-pattern \"./card/vendor/**/*\""
      end

      def executer
        @executer = []
        if options[:spring]
          @executer << "spring"
          if options[:rescue]
            puts "Disabled pry-rescue. Not compatible with spring."
            options[:rescue] = false
          end
        else
          @executer << "bundle exec"
        end
        @executer << "rescue" if options[:rescue]
        @executer.join " "
      end

      def env_args
        ["RAILS_ROOT=.", coverage].compact.join " "
      end

      def coverage
        # no coverage if rspec was started with file argument
        if ((@files || @rspec_args.present?) && !options[:simplecov]) ||
          options[:simplecov] == false
          options[:simplecov] = "COVERAGE=false"
        end
      end

      def find_spec_file filename, base_dir
        file, line = filename.split(":")
        if file.include?("_spec.rb") && File.exist?(file)
          filename
        else
          file = File.basename(file, ".rb").sub(/_spec$/, "")
          Dir.glob("#{base_dir}/**/#{file}_spec.rb").flatten.map do |spec_file|
            line ? "#{spec_file}:#{line}" : file
          end.join(" ")
        end
      end

      def process_file_options
        @files =
          if options[:spec]
            find_spec_file(options[:spec], "#{Decko.root}/mod")
          elsif options[:core]
            find_spec_file(options[:spec], Cardio.gem_root)
          elsif options[:mod]
            mod_spec_files
          end
      end

      def mod_spec_files
        file = options[:mod]
        if File.exist?("mod/#{file}")
          "#{Cardio.gem_root}/mod/#{file}"
        elsif File.exist?("#{Cardio.gem_root}/mod/#{file}")
          "#{Cardio.gem_root}/mod/#{file}"
        elsif (files = find_spec_file(file, "mod")) && files.present?
          files
        else
          find_spec_file(file, "#{Cardio.gem_root}/mod")
        end
      end
    end
  end
end
