require './app/models/entities.rb'
require './app/models/game.rb'
require './app/helpers/game.rb'
require './app/api/v1.rb'

module Morris
   class API < Grape::API
      format :json
      prefix :morris
      mount Morris::V1
      add_swagger_documentation api_version: 'v1',
                                hide_documentation_path: true,
                                hide_format: true,
                                mount_path: 'doc'
   end
end
