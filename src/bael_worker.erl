-module(bael_worker).
-behaviour(gen_server).
-include("bael.hrl").
-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	code_change/3, terminate/2]).

start_link()->
	gen_server:start_link(?MODULE, [], []).

init([])->
	{ok, #bael_worker_state{}}.

handle_call(_Msg, _From, State)->
	{reply, reply, State}.

handle_cast(_Msg, State)->
	{noreply, State}.

handle_info(_Msg, State)->
	{noreply, State}.

code_change(_Vsn, State, _Extra)->
	{ok, State}.

terminate(_Reason, _State)->
	ok.
