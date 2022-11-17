module Queries
  class List
    include Import[repo: 'read_model.repositories.posts']

    def call(with_comments = false)
      with_comments ? repo.with_comments : repo.all
    end
  end
end
