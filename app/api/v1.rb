module Morris
   class V1 < Grape::API
      format :json
      version 'v1', using: :path
      helpers Morris::Helpers
      helpers do
         @@games = nil
         def games
            return @@games unless @@games.nil?
            @@games = Hash.new
         end
      end
      resource :game do

         desc 'Start a new game.' do
            success Morris::Entities::NewGame
         end
         params do
            requires :title, type: String, desc: 'Title of the game.'
            requires :com, type: Boolean, desc: 'True if vs com.'
            requires :name, type: String, desc: 'Your name.'
         end
         post do
            game = new_game params[:title], params[:com], params[:name]
            games[game.token] = game
            {:title => game.title, :token => game.token, :player_token => game.host[:token]}
         end

         desc 'Return status of a specific game.' do
            success Morris::Entities::StatusGame
            failure [[404, 'Not Found'], [403, 'Invalid Player Token']]
         end
         params do
            requires :token, type: String, desc: 'Token of the game.'
            requires :player_token, type: String, desc: 'Your player token.'
         end
         get do
            error! 'Not Found', 404 if games[params[:token]].nil?
            game = games[params[:token]]
            error! 'Invalid Player Token', 403 unless game.host[:token] == params[:player_token] || !game.attendee.nil? && game.attendee[:token] == params[:player_token]
            game.to_hash
         end

         desc 'Return a list of all games.' do
            success Morris::Entities::GameList
         end
         get :list do
            list = Array.new
            games.each_value do |game|
               list.push game.to_hash
            end
            {:list => list}
         end

         desc 'Attend a specific game.' do
            success Morris::Entities::NewGame
            failure [[404, 'Not Found'], [403, 'Full']]
         end
         params do
            requires :token, type: String, desc: 'Token of the game.'
            requires :name, type: String, desc: 'Your name.'
         end
         post :attend do
            error! 'Not Found', 404 if games[params[:token]].nil?
            game = games[params[:token]]
            error! 'Full', 403 unless game.attend_ability
            game.attend params[:name]
            {:title => game.title, :token => game.token, :player_token => game.attendee[:token]}
         end

      end
   end
end
