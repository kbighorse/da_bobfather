# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130604223402) do

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "fbid"
    t.boolean  "registered"
    t.string   "fb_access_token"
    t.string   "favorite_donut"
    t.time     "last_login"
    t.string   "state"
    t.boolean  "is_bobfather"
    t.integer  "node_id"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
    t.string   "ancestry"
  end

  add_index "users", ["ancestry"], :name => "index_users_on_ancestry"
  add_index "users", ["fbid"], :name => "index_users_on_fbid"
  add_index "users", ["node_id"], :name => "index_users_on_node_id"

end
