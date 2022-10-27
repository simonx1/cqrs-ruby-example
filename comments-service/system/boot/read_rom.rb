# frozen_string_literal: true

App.boot(:read_rom) do |app|
  init do
    require "rom"
    require "rom-sql"
    require "rom-repository"

    container = ROM.container(:sql, ENV['READ_DATABASE_URL']) do |configuration|

      # configuration.default.create_table(:comments) do
      #   primary_key :id
      #   column :body, String, null: false
      #   column :author_name, String, null: false
      #   column :post_id, Integer, null: false
      #   column :created_at, DateTime, null: false
      #   column :updated_at, DateTime, null: false
      # end

      configuration.relation(:comments) do
        schema(infer: true)
        auto_struct true
      end
    end

    register(:read_rom, container)
  end
end
