# -*- encoding : utf-8 -*-

class Card
  # Used to extend setting modules like Card::Set::Self::Create in the
  # settings mod
  module Setting
    # Let M = Card::Setting           (module)
    #     E = Card::Set::Self::Create (module extended with M)
    #     O = Card['*create']         (object)
    # accessible in E
    attr_accessor :codename
    # accessible in E and M
    mattr_accessor :groups, :group_names, :user_specific
    def self.extended host_class
      # accessible in E and O
      host_class.mattr_accessor :restricted_to_type, :rule_type_editable, :short_help_text,
                                :raw_help_text, :right_set, :applies
      setting_class_name = host_class.to_s.split("::").last
      host_class.ensure_set { "Card::Set::Right::#{setting_class_name}" }
      host_class.right_set = Card::Set::Right.const_get(setting_class_name)
      host_class.right_set.mattr_accessor :raw_help_text
    end

    def self.codenames
      Card::Setting.groups.values.flatten.compact.map(&:codename)
    end

    @@group_names = {
      templating: "Templating",
      permission: "Permissions",
      webpage: "Webpage",
      editing: "Editing",
      event: "Events",
      other: "Other",
      config: "Config"
    }
    @@groups = @@group_names.keys.each_with_object({}) do |key, groups|
      groups[key] = []
    end
    @@user_specific = ::Set.new

    def self.user_specific? codename
      @@user_specific.include? codename
    end

    # usage:
    # setting_opts group:        :permission | :event | ...
    #              position:     <Fixnum> (starting at 1, default: add to end)
    #              rule_type_editable: true | false (default: false)
    #              restricted_to_type: <cardtype> | [ <cardtype>, ...]
    def setting_opts opts
      group = opts[:group] || :other
      @@groups[group] ||= []
      set_position group, opts[:position]

      @codename = opts[:codename] ||
                  name.match(/::(\w+)$/)[1].underscore.to_sym
      self.rule_type_editable = opts[:rule_type_editable]
      self.restricted_to_type = permitted_type_ids opts[:restricted_to_type]
      self.short_help_text = opts[:short_help_text]
      self.applies = opts[:applies]
      right_set.raw_help_text = self.raw_help_text = opts[:help_text]
      return unless opts[:user_specific]

      @@user_specific << @codename
    end

    def set_position group, pos
      if pos
        if @@groups[group][pos - 1]
          @@groups[group].insert(pos - 1, self)
        else
          @@groups[group][pos - 1] = self
        end
      else
        @@groups[group] << self
      end
    end

    def applies_to_cardtype type_id, prototype=nil
      (!restricted_to_type || restricted_to_type.include?(type_id)) &&
        (!prototype || applies_to_prototype?(prototype))
    end

    def applies_to_prototype? prototype
      return true unless applies

      applies.call(prototype)
    end

    private

    def permitted_type_ids types
      return unless types

      type_ids = Array.wrap(types).flatten.map do |cardtype|
        Card::Codename.id cardtype
      end
      ::Set.new(type_ids)
    end
  end
end
