# frozen_string_literal: true
require "pry"

App.boot(:read_rom) do |app|
  init do
    require "rom"
    require "rom-sql"
    require "rom-repository"

    container = ROM.container(:sql, ENV['DATABASE_URL']) do |configuration|

      # configuration.default.create_table(:users) do
      #   primary_key :id
      #   column :full_name, String, null: false
      #   column :created_at, DateTime, null: false
      #   column :updated_at, DateTime, null: false
      # end

      configuration.relation(:users) do
        schema(infer: true)
        auto_struct true
      end
    end

    register(:rom, container)
  end
end
