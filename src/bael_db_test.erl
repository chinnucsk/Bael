-module(bael_db_test).
-export([mysql_test/0, mnesia_test/0]).
-export([odbc_write_test/2, odbc_read_test/2, odbc_update_test/2]).
-export([emysql_write_test/1, emysql_read_test/1, emysql_update_test/1]).
-export([mnesia_write_test/1, mnesia_read_test/1]).
-include("bael_mysql.hrl").
-define(MAX_TABLE_ROWS, 100).
-define(CREATE_TEST_TABLE, "
	CREATE TABLE `bael_test` (
		`id` INT(10) NOT NULL AUTO_INCREMENT,
		`name` VARCHAR(128) NOT NULL DEFAULT '0',
		`pid` VARCHAR(128) NOT NULL DEFAULT '0',
		PRIMARY KEY (`id`)
	)
	COLLATE='utf8_general_ci'
	ENGINE=InnoDB;").
-record(test_record,{
	id, name, pid
}).

mysql_test()->
	{ok, Conn}=odbc:connect("DSN=bael_local", []),
	{selected, _, [{Count}]}=odbc:sql_query(Conn, lists:concat(["
		select count(*) from 
			`INFORMATION_SCHEMA`.`TABLES` 
			where `TABLE_SCHEMA`='", ?DB_DEFAULT_DB ,"' 
				and `TABLE_NAME`='bael_test'"])),
	if
		Count=/="0"->
			odbc:sql_query(Conn, "drop table bael_test");
		true->do_nothing
	end,
	odbc:sql_query(Conn, ?CREATE_TEST_TABLE),
	io:format("odbc test start...~n"),
	{T0, _}=timer:tc(?MODULE, odbc_write_test, [Conn, ?MAX_TABLE_ROWS]),
	io:format("write times:~p, case time:~p~n", [?MAX_TABLE_ROWS, T0]),
	{T1, _}=timer:tc(?MODULE, odbc_read_test, [Conn, ?MAX_TABLE_ROWS]),
	io:format("read times:~p, case time:~p~n", [?MAX_TABLE_ROWS, T1]),
	{T2, _}=timer:tc(?MODULE, odbc_update_test, [Conn, ?MAX_TABLE_ROWS]),
	io:format("update times:~p, case time:~p~n", [?MAX_TABLE_ROWS, T2]),
	io:format("odbc test finish.~n"),
	odbc:sql_query(Conn, "drop table bael_test"),
	odbc:sql_query(Conn, ?CREATE_TEST_TABLE),
	io:format("emysql test start...~n"),
	{T3, _}=timer:tc(?MODULE, emysql_write_test, [?MAX_TABLE_ROWS]),
	io:format("write times:~p, case time:~p~n", [?MAX_TABLE_ROWS, T3]),
	{T4, _}=timer:tc(?MODULE, emysql_read_test, [?MAX_TABLE_ROWS]),
	io:format("read times:~p, case time:~p~n", [?MAX_TABLE_ROWS, T4]),
	{T5, _}=timer:tc(?MODULE, emysql_update_test, [?MAX_TABLE_ROWS]),
	io:format("update times:~p, case time:~p~n", [?MAX_TABLE_ROWS, T5]),
	io:format("emysql test finish.~n"),
	odbc:disconnect(Conn).

odbc_write_test(Conn, Num)->
	F=fun(N)->
		Sql=lists:concat([
			"insert into bael_test(name, pid) value('",
				"odbc_", N, "', '", pid_to_list(Conn), "'
			)"
		]),
		odbc:sql_query(Conn, Sql)
	end,
	lists:foreach(F, lists:seq(1, Num)).

emysql_write_test(Num)->
	F=fun(N)->
		Sql=lists:concat([
			"insert into bael_test(name, pid) value('",
				"emysql_", N, "', '", pid_to_list(self()), "'
			)"
		]),
		emysql:execute(db_test, Sql)
	end,
	lists:foreach(F, lists:seq(1, Num)).

odbc_read_test(Conn, Num)->
	F=fun(N)->
		Sql=lists:concat([
			"select * from bael_test 
				where name='", "odbc_", N, "'"
		]),
		odbc:sql_query(Conn, Sql)
	end,
	lists:foreach(F, lists:seq(1, Num)).

emysql_read_test(Num)->
	F=fun(N)->
		Sql=lists:concat([
			"select * from bael_test 
				where name='", "emysql_", N, "'"
		]),
		emysql:execute(db_test, Sql)
	end,
	lists:foreach(F, lists:seq(1, Num)).

odbc_update_test(Conn, Num)->
	F=fun(N)->
		Sql=lists:concat([
			"update bael_test set
				pid=concat(pid, '-update')
			where name='odbc_", N, "'"
		]),
		odbc:sql_query(Conn, Sql)
	end,
	lists:foreach(F, lists:seq(1, Num)).

emysql_update_test(Num)->
	F=fun(N)->
		Sql=lists:concat([
			"update bael_test set
				pid=concat(pid, '-update')
			where name='emysql_", N, "'"
		]),
		emysql:execute(db_test, Sql)
	end,
	lists:foreach(F, lists:seq(1, Num)).

mnesia_test()->
	mnesia:delete_table(db_test_mnesia),
	Res=mnesia:create_table(db_test_mnesia, [
		{disc_only_copies, [node()]},
		{attributes, record_info(fields, test_record)},
		{record_name, test_record}
	]),
	io:format("mnesia test start...~p~n", [Res]),
	{T0, _}=timer:tc(?MODULE, mnesia_write_test, [?MAX_TABLE_ROWS]),
	io:format("write times:~p, case time:~p~n", [?MAX_TABLE_ROWS, T0]),
	{T1, _}=timer:tc(?MODULE, mnesia_read_test, [?MAX_TABLE_ROWS]),
	io:format("read times:~p, case time:~p~n", [?MAX_TABLE_ROWS, T1]),
	io:format("mnesia test finish.~n").

mnesia_write_test(Num)->
	F=fun(N)->
		R=#test_record{
			id=now(),
			name=lists:concat(["mnesta_", N]),
			pid=self()
		},
		mnesia:dirty_write(db_test_mnesia, R)
	end,
	lists:foreach(F, lists:seq(1, Num)).

mnesia_read_test(Num)->
	F=fun(N)->
		mnesia:dirty_select(db_test_mnesia, [{
			#test_record{name='$1', _='_'},
			[{'==', '$1', lists:concat(["mnesia_", N])}],
			['$_']
		}])
	end,
	lists:foreach(F, lists:seq(1, Num)).
