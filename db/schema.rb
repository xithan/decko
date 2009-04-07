# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090407193422) do

  create_table "card_files", :force => true do |t|
    t.string   "filename"
    t.string   "content_type"
    t.integer  "size"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "revision_id"
  end

  create_table "card_images", :force => true do |t|
    t.string   "filename"
    t.string   "content_type"
    t.integer  "size"
    t.integer  "height"
    t.integer  "width"
    t.integer  "parent_id"
    t.string   "thumbnail"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "card_id"
    t.integer  "db_file_id"
    t.integer  "revision_id"
  end

# Could not dump table "cards" because of following StandardError
#   Unknown type 'tsvector' for column 'indexed_content'

  create_table "cardtypes", :force => true do |t|
    t.string  "class_name"
    t.boolean "system"
  end

  add_index "cardtypes", ["class_name"], :name => "cardtypes_class_name_uniq", :unique => true

  create_table "db_files", :force => true do |t|
    t.binary "data"
  end

  create_table "open_id_authentication_associations", :force => true do |t|
    t.integer "issued"
    t.integer "lifetime"
    t.string  "handle"
    t.string  "assoc_type"
    t.binary  "server_url"
    t.binary  "secret"
  end

  create_table "open_id_authentication_nonces", :force => true do |t|
    t.integer "timestamp",  :null => false
    t.string  "server_url"
    t.string  "salt",       :null => false
  end

  create_table "permissions", :force => true do |t|
    t.integer "card_id"
    t.string  "task"
    t.string  "party_type"
    t.integer "party_id"
  end

  add_index "permissions", ["card_id", "task"], :name => "permissions_task_card_id_uniq", :unique => true
  add_index "permissions", ["task"], :name => "permissions_task_index"

  create_table "pg_ts_cfg", :id => false, :force => true do |t|
    t.text "ts_name",  :null => false
    t.text "prs_name", :null => false
    t.text "locale"
  end

  create_table "pg_ts_cfgmap", :id => false, :force => true do |t|
    t.text   "ts_name",                  :null => false
    t.text   "tok_alias",                :null => false
    t.string "dict_name", :limit => nil
  end

# Could not dump table "pg_ts_dict" because of following StandardError
#   Unknown type 'regprocedure' for column 'dict_init'

# Could not dump table "pg_ts_parser" because of following StandardError
#   Unknown type 'regprocedure' for column 'prs_start'

  create_table "revisions", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "card_id",    :null => false
    t.integer  "created_by", :null => false
    t.text     "content",    :null => false
  end

  add_index "revisions", ["card_id"], :name => "revisions_card_id_index"
  add_index "revisions", ["created_by"], :name => "revisions_created_by_index"

  create_table "roles", :force => true do |t|
    t.string "codename"
    t.string "tasks"
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "role_id", :null => false
    t.integer "user_id", :null => false
  end

  add_index "roles_users", ["role_id"], :name => "roles_users_role_id"
  add_index "roles_users", ["user_id"], :name => "roles_users_user_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "sessions_session_id_index"

  create_table "settings", :force => true do |t|
    t.string "codename"
  end

  create_table "system", :force => true do |t|
    t.string "name", :default => ""
  end

  create_table "users", :force => true do |t|
    t.string   "login",               :limit => 40
    t.string   "email",               :limit => 100
    t.string   "crypted_password",    :limit => 40
    t.string   "salt",                :limit => 42
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "password_reset_code", :limit => 40
    t.boolean  "blocked",                            :default => false,     :null => false
    t.integer  "cards_per_page",                     :default => 25,        :null => false
    t.boolean  "hide_duplicates",                    :default => true,      :null => false
    t.string   "status",                             :default => "request"
    t.integer  "invite_sender_id"
    t.string   "identity_url"
  end

  create_table "wiki_references", :force => true do |t|
    t.datetime "created_at",                                      :null => false
    t.datetime "updated_at",                                      :null => false
    t.integer  "card_id",                         :default => 0,  :null => false
    t.string   "referenced_name",                 :default => "", :null => false
    t.integer  "referenced_card_id"
    t.string   "link_type",          :limit => 1, :default => "", :null => false
  end

  add_index "wiki_references", ["card_id"], :name => "wiki_references_card_id"
  add_index "wiki_references", ["referenced_card_id"], :name => "wiki_references_referenced_card_id"
  add_index "wiki_references", ["referenced_name"], :name => "wiki_references_referenced_name"

end
