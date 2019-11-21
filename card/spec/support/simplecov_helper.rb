def is_in_mod? file, mod_path
  mod_msg = "below pulled from #{Rails.root}/mod/#{mod_path}/"
  file.src.join("") =~ /#{mod_msg}/
end

def card_simplecov_filters
  add_filter "spec/"
  add_filter "/config/"
  add_filter "/tasks/"
  # filter all card mods
  add_filter do |src_file|
    src_file.filename =~ %r{tmp/} && !/\d+-(.+\.rb)/.match(src_file.filename) do |m|
      Dir["mod/**/#{m[1].tr('-', '/').sub('/', '/set/')}"].present?
    end
  end
  # add group for each deck mod
  Dir["mod/*"].map { |path| path.sub("mod/", "") }.each do |mod|
    add_group mod.capitalize do |src_file|
      src_file.filename =~ %r{mod/#{mod}/} ||
        (
          src_file.filename =~ %r{tmp/} &&
          (match = /\d+-(.+\.rb)/.match(src_file.filename) do |m|
            # '/set' is not in the path anymore after some updates
            # but `set` exists in the path of the source files
            Dir["mod/**/#{m[1].tr('-', '/').sub('/', '/set/')}"].present?
          end) &&
          is_in_mod?(src_file, mod)
        )
    end
  end

  add_group "Sets" do |src_file|
    src_file.filename =~ %r{tmp/set/} &&
      /\d+-(.+\.rb)/.match(src_file.filename) { |m| Dir["mod/**/#{m[1]}"].present? }
  end
  add_group "Set patterns" do |src_file|
    src_file.filename =~ %r{tmp/set_pattern/} &&
      /\d+-(.+\.rb)/.match(src_file.filename) { |m| Dir["mod/**/#{m[1]}"].present? }
  end
  add_group "Formats" do |src_file|
    src_file.filename =~ %r{mod/[^/]+/formats}
  end
  add_group "Chunks" do |src_file|
    src_file.filename =~ %r{mod/[^/]+/chunks}
  end
end

def card_core_dev_simplecov_filters
  filters.clear # This will remove the :root_filter that comes via simplecov's defaults
  add_filter do |src|
    src.filename !~ /^#{SimpleCov.root}/ unless src.filename =~ /card|wagn/
  end

  add_filter "/spec/"
  add_filter "/features/"
  add_filter "/config/"
  add_filter "/tasks/"
  add_filter "/generators/"
  add_filter "lib/card"

  add_group "Card", "lib/card"
  add_group "Set Patterns", "tmp/set_pattern/"
  add_group "Sets",         "tmp/set/"
  add_group "Formats" do |src_file|
    src_file.filename =~ %r{mod/[^/]+/format}
  end
  add_group "Chunks" do |src_file|
    src_file.filename =~ %r{mod/[^/]+/chunk}
  end
end
