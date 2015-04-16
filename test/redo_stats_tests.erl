%% Copyright (C) 2015 Heroku, Inc.
%%
%% Permission is hereby granted, free of charge, to any person
%% obtaining a copy of this software and associated documentation
%% files (the "Software"), to deal in the Software without
%% restriction, including without limitation the rights to use,
%% copy, modify, merge, publish, distribute, sublicense, and/or sell
%% copies of the Software, and to permit persons to whom the
%% Software is furnished to do so, subject to the following
%% conditions:
%%
%% The above copyright notice and this permission notice shall be
%% included in all copies or substantial portions of the Software.
%%
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
%% EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
%% OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
%% NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
%% HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
%% WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
%% FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
%% OTHER DEALINGS IN THE SOFTWARE.
-module(redo_stats_tests).
-include_lib("eunit/include/eunit.hrl").

parse_response_test() ->
    Response1 = <<"# Server\r\nversion:2.8.19\r\nsha1:00000000\r\n">>,
    ?assertEqual([{<<"Server">>, [{<<"version">>, <<"2.8.19">>}, {<<"sha1">>, <<"00000000">>}]}],
                 redo_stats:parse_response(Response1)),

    Response2 = <<"# Server\r\nversion:2.8.19\r\n\r\n# Client\r\nvalue:2000\r\n">>,
    ?assertEqual([{<<"Server">>, [{<<"version">>, <<"2.8.19">>}]},
                  {<<"Client">>, [{<<"value">>, <<"2000">>}]}],
                 redo_stats:parse_response(Response2)).

get_stats_cmd_test() ->
    ?assertEqual([<<"INFO">>, <<"default">>],
                 redo_stats:get_stats_cmd(<<"default">>)).

parse_line_test() ->
    ?assertEqual({<<"Server">>, [], []},
                 redo_stats:parse_line(<<"# Server">>, {undefined, [], []})),

    %% When we find a new key, it should be added to the current section.
    ?assertEqual({undefined, [{<<"version">>, <<"2.8.19">>}], []},
                 redo_stats:parse_line(<<"version:2.8.19">>, {undefined, [], []})),

    %% When we find another key, it should be prepended to the current section.
    ?assertEqual({undefined, [{<<"sha1">>, <<"abcdef">>}, {<<"version">>, <<"2.8.19">>}], []},
                 redo_stats:parse_line(<<"sha1:abcdef">>, {undefined, [{<<"version">>, <<"2.8.19">>}], []})),

    %% When we add a new section to the previous sections, the keys should be
    %% added in the order we identified them.
    ?assertEqual({undefined, [], [{<<"Server">>, [{<<"sha1">>, <<"abcdef">>}, {<<"version">>, <<"1.0">>}]}]},
                 redo_stats:parse_line(<<>>, {<<"Server">>, [{<<"version">>, <<"1.0">>},{<<"sha1">>, <<"abcdef">>}], []})).
