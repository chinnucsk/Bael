-module(bael_worker_sup).
-behaviour(supervisor).
-include("bael.hrl").

-export([init/1]).
-export([start_link/0, upgrade/0]).

start_link()->
	supervisor:start_link({local, ?MODULE}, ?MODULE, []).

upgrade()->
	ok.

init([])->
	Strategy={one_for_one, 10, 10},
	SpecsList=[{lists:concat(["worker_", ID]), {bael_worker, start_link, []},
	 permanent, 5000, worker, dynamic}||
 	 ID<-lists:seq(0, ?MAX_WORKERS_POOL_SIZE-1)],
 	{ok, {Strategy, lists:flatten(SpecsList)}}.
