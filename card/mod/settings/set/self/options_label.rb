extend Card::Setting
setting_opts group: :editing, position: 2,
             restricted_to_type: %i[pointer session],
             rule_type_editable: false,
             help_text: "Labels for [[Pointer]] radio button and checkbox items.  "\
                        "[[http://decko.org/Pointer|more]]"
