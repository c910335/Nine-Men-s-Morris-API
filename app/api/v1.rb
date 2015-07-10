module Morris
   class V1 < Grape::API
      format :json

      helpers Morris::Helpers
      helpers do
         @@games = nil
         def games
            return @@games unless @@games.nil?
            @@games = Hash.new
         end
      end

      resource :game do
         format :json

         desc 'Start a new game.' do
            success Morris::Entities::NewGame
            failure [[400, 'Not Support VS COM']]
         end
         params do
            requires :title, type: String, desc: 'Title of the game.'
            requires :com, type: Boolean, desc: 'True if vs com.'
            requires :name, type: String, desc: 'Your name.'
         end
         post do
            error! 'Not Support VS COM', 400 if params[:com]
            game = new_game params[:title], params[:com], params[:name]
            games[game.token] = game
            {:title => game.title, :token => game.token, :player_token => game.host[:token]}
         end

         desc 'Return details of a specific game.' do
            success Morris::Entities::PrivateGame
            failure [[404, 'Not Found'], [403, 'Invalid Player Token']]
         end
         params do
            requires :token, type: String, desc: 'Token of the game.'
            requires :player_token, type: String, desc: 'Your player token.'
         end
         get do
            error! 'Not Found', 404 if games[params[:token]].nil?
            game = games[params[:token]]
            error! 'Invalid Player Token', 403 unless game.has_player? params[:player_token]
            game.to_private_hash
         end

         desc 'Return a list of all games.' do
            success Morris::Entities::GameList
         end
         get :list do
            list = Array.new
            games.each_value do |game|
               list.push game.to_hash unless game.over?
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

         desc 'Return whether the game has begun.' do
            success Morris::Entities::Begin
            failure [[404, 'Not Found'], [403, 'Invalid Player Token']]
         end
         params do
            requires :token, type: String, desc: 'Token of the game.'
            requires :player_token, type: String, desc: 'Your player token.'
         end
         get :begin do
            error! 'Not Found', 404 if games[params[:token]].nil?
            game = games[params[:token]]
            error! 'Invalid Player Token', 403 unless game.has_player? params[:player_token]
            {:begin => game.begin? }
         end

         desc 'Return whether it is your turn.' do
            success Morris::Entities::MyTurn
            failure [[404, 'Not Found'], [403, 'Invalid Player Token'], [410, 'This game is already over']]
         end
         params do
            requires :token, type: String, desc: 'Token of the game.'
            requires :player_token, type: String, desc: 'Your player token.'
         end
         get :my_turn do
            error! 'Not Found', 404 if games[params[:token]].nil?
            game = games[params[:token]]
            error! 'Invalid Player Token', 403 unless game.has_player? params[:player_token]
            {:my_turn => game.my_turn?( params[:player_token] )}
         end

         desc 'Click on x, y.' do
            success Morris::Entities::Result
            failure [[404, 'Not Found'], [403, 'Invalid Player Token'], [410, 'This game is already over'], [400, 'Against the Rules']]
         end
         params do
            requires :token, type: String, desc: 'Token of the game.'
            requires :player_token, type: String, desc: 'Your player token.'
            requires :x, type: Integer, desc: 'The x coordinate to click.'
            requires :y, type: Integer, desc: 'The y coordinate to click.'
         end
         post :click do
            error! 'Not Found', 404 if games[params[:token]].nil?
            game = games[params[:token]]
            error! 'Invalid Player Token', 403 unless game.has_player? params[:player_token]
            result = game.click params[:x], params[:y], params[:player_token]
            error! result[:error_message], result[:http_code] if result[:code] == game.class::ERROR
            result.delete :code
            result
         end

         desc 'Return the last click result.' do
            success Morris::Entities::Result
            failure [[404, 'Not Found'], [403, 'Invalid Player Token'], [403, 'The game has just begun.'], [403, 'The game has not yet begun.']]
         end
         params do
            requires :token, type: String, desc: 'Token of the game.'
            requires :player_token, type: String, desc: 'Your player token.'
         end
         get :last_click do
            error! 'Not Found', 404 if games[params[:token]].nil?
            game = games[params[:token]]
            rror! 'Invalid Player Token', 403 unless game.has_player? params[:player_token]
            result = game.last_click
            error! result[:error_message], result[:http_code] if result[:code] == game.class::ERROR
            result.delete :code
            result
         end

      end

      add_swagger_documentation api_version: 'v1',
                                hide_documentation_path: true,
                                hide_format: true,
                                mount_path: '/doc',
                                base_path: '/morris/v1/'

   end
end
