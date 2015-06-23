require './app/models/code.rb'
require './app/models/game.rb'
require './app/models/entities.rb'
require './app/helpers/game.rb'
require './app/api/v1.rb'

module Morris
   class API < Grape::API
      mount Morris::V1 => '/morris/v1'
   end
end
