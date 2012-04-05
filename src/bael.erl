%% @author Mochi Media <dev@mochimedia.com>
%% @copyright 2010 Mochi Media <dev@mochimedia.com>

%% @doc bael.

-module(bael).
-author("Mochi Media <dev@mochimedia.com>").
-export([start/0, stop/0]).
-include("bael_mysql.hrl").

ensure_started(App) ->
    case application:start(App) of
        ok ->
            ok;
        {error, {already_started, App}} ->
            ok
    end.


%% @spec start() -> ok
%% @doc Start the bael server.
start() ->
    bael_deps:ensure(),
    ensure_started(crypto),
    ensure_started(emysql),
	init_db_conn(),
    application:start(bael).


%% @spec stop() -> ok
%% @doc Stop the bael server.
stop() ->
	application:stop(emysql),
    application:stop(bael).
    
    
init_db_conn()->
	emysql:add_pool(db_test, ?DB_CONN_NUM, ?DB_USER_NAME, ?DB_PASSWORD,
	 ?DB_HOSTNAME, ?DB_PORT, "WQMobile", utf8).
