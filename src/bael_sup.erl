%% @author Mochi Media <dev@mochimedia.com>
%% @copyright 2010 Mochi Media <dev@mochimedia.com>

%% @doc Supervisor for the bael application.

-module(bael_sup).
-author("Mochi Media <dev@mochimedia.com>").

-include("bael.hrl").

-behaviour(supervisor).

%% External exports
-export([start_link/0, upgrade/0]).

%% supervisor callbacks
-export([init/1]).

%% @spec start_link() -> ServerRet
%% @doc API for starting the supervisor.
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% @spec upgrade() -> ok
%% @doc Add processes if necessary.
upgrade() ->
    {ok, {_, Specs}} = init([]),

    Old = sets:from_list(
            [Name || {Name, _, _, _} <- supervisor:which_children(?MODULE)]),
    New = sets:from_list([Name || {Name, _, _, _, _, _} <- Specs]),
    Kill = sets:subtract(Old, New),

    sets:fold(fun (Id, ok) ->
                      supervisor:terminate_child(?MODULE, Id),
                      supervisor:delete_child(?MODULE, Id),
                      ok
              end, ok, Kill),

    [supervisor:start_child(?MODULE, Spec) || Spec <- Specs],
    ok.

%% @spec init([]) -> SupervisorTree
%% @doc supervisor callback.
init([]) ->
    Web = web_specs(bael_web, ?HTTP_PORT),
    ServerSup={bael_server_sup, {bael_server_sup, start_link, []},
		permanent, 5000, supervisor, dynamic},
    FsmSup={bael_fsm_sup, {bael_fsm_sup, start_link, []},
		permanent, 5000, supervisor, dynamic},
	MsgServer={
		bael_msg_server, 
		{
			bael_msg_server, 
			start_link, 
			[bael_msg_server, bael_fsm_sup, {bael_fsm, get_msg}]
		},
		permanent, 5000, worker, dynamic},
    Processes = [Web, ServerSup, FsmSup, MsgServer],
    Strategy = {one_for_one, 10, 10},
    {ok,
     {Strategy, lists:flatten(Processes)}}.

web_specs(Mod, Port) ->
    WebConfig = [{ip, {0,0,0,0}},
                 {port, Port},
                 {docroot, bael_deps:local_path(["priv", "www"])}],
    {Mod,
     {Mod, start, [WebConfig]},
     permanent, 5000, worker, dynamic}.
