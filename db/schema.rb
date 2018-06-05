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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160929135825) do

  create_table "census_boundaries", force: :cascade do |t|
    t.string   "name",            limit: 255
    t.integer  "area_identifier", limit: 4
    t.text     "bounds",          limit: 4294967295
    t.string   "geo_id",          limit: 255
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
  end

  create_table "provider_statistics", force: :cascade do |t|
    t.string   "name",                       limit: 50,                                           null: false
    t.integer  "applications",               limit: 4,                           default: 0,      null: false
    t.float    "rating",                     limit: 24,                          default: 0.0,    null: false
    t.decimal  "advertised_to_actual_ratio",            precision: 5,  scale: 2, default: 0.0,    null: false
    t.decimal  "average_price",                         precision: 5,  scale: 2, default: 0.0,    null: false
    t.string   "provider_type",              limit: 20,                          default: "both", null: false
    t.datetime "created_at",                                                                      null: false
    t.datetime "updated_at",                                                                      null: false
    t.decimal  "actual_speed_sum",                      precision: 60, scale: 2, default: 0.0,    null: false
    t.decimal  "provider_speed_sum",                    precision: 60, scale: 2, default: 0.0,    null: false
  end

  create_table "submissions", force: :cascade do |t|
    t.string   "testing_for",           limit: 20,                                             null: false
    t.string   "address",               limit: 255
    t.string   "zip_code",              limit: 10
    t.string   "provider",              limit: 255
    t.string   "connected_with",        limit: 255
    t.float    "monthly_price",         limit: 24
    t.float    "provider_down_speed",   limit: 24
    t.decimal  "provider_price",                      precision: 15, scale: 2
    t.float    "actual_down_speed",     limit: 24,                                             null: false
    t.decimal  "actual_price",                        precision: 15, scale: 2
    t.integer  "rating",                limit: 4
    t.boolean  "completed",                                                    default: false
    t.datetime "created_at",                                                                   null: false
    t.datetime "updated_at",                                                                   null: false
    t.float    "latitude",              limit: 24
    t.float    "longitude",             limit: 24
    t.integer  "ping",                  limit: 4
    t.float    "actual_upload_speed",   limit: 24,                                             null: false
    t.text     "additional_comments",   limit: 65535
    t.string   "service_plan",          limit: 255
    t.string   "internet_location",     limit: 255
    t.boolean  "indoor",                                                       default: true
    t.string   "internet_for",          limit: 20
    t.integer  "census_code",           limit: 4
    t.float    "provider_upload_speed", limit: 24
  end

  add_index "submissions", ["actual_down_speed"], name: "index_submissions_on_actual_down_speed", using: :btree
  add_index "submissions", ["provider"], name: "index_submissions_on_provider", using: :btree
  add_index "submissions", ["rating"], name: "index_submissions_on_rating", using: :btree
  add_index "submissions", ["testing_for"], name: "index_submissions_on_testing_for", using: :btree
  add_index "submissions", ["zip_code"], name: "index_submissions_on_zip_code", using: :btree

  create_table "zip_boundaries", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "zip_type",   limit: 255
    t.text     "bounds",     limit: 4294967295
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

end
