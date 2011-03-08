%%
%%  U.C.Engine - Unified Colloboration Engine
%%  Copyright (C) 2011 af83
%%
%%  This program is free software: you can redistribute it and/or modify
%%  it under the terms of the GNU Affero General Public License as published by
%%  the Free Software Foundation, either version 3 of the License, or
%%  (at your option) any later version.
%%
%%  This program is distributed in the hope that it will be useful,
%%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%  GNU Affero General Public License for more details.
%%
%%  You should have received a copy of the GNU Affero General Public License
%%  along with this program.  If not, see <http://www.gnu.org/licenses/>.
%%
-module(uce_http).

-author('victor.goya@af83.com').

-include("uce.hrl").
-include_lib("yaws/include/yaws_api.hrl").

-export([parse/1]).

-record(upload, {fd, filename, uri, last}).

add_file_chunk(Arg, [{part_body, Data}|Res], State) ->
    add_file_chunk(Arg, [{body, Data}|Res], State);
add_file_chunk(Arg, [], State) when State#upload.last==true,
                                    State#upload.filename /= undefined,
                                    State#upload.fd /= undefined ->

    file:close(State#upload.fd),
    Query = yaws_api:parse_query(Arg) ++ [{"_uri", State#upload.uri},
                                          {"_filename", State#upload.filename}],
    {done, {'POST', Arg#arg.pathinfo, parse_query(Query)}};

add_file_chunk(_Arg, [], State) when State#upload.last==true ->
    {done, {error, unexpected_error}};

add_file_chunk(_Arg, [], State) ->
    {cont, State};

add_file_chunk(Arg, [{head, {_Name, Opts}}|Res], State ) ->
    case lists:keysearch(filename, 1, Opts) of
        {value, {_, Fname}} ->
            Id = utils:random(),
            Dir = utils:random(3),
            file:make_dir(config:get(datas) ++ "/" ++ Dir),
            case file:open(config:get(datas) ++ "/" ++ Dir ++ "/" ++ Id ,[write]) of
                {ok, Fd} ->
                    S2 = State#upload{filename = Fname,
                                      uri="file://" ++ Dir ++ "/" ++ Id,
                                      fd = Fd},
                    add_file_chunk(Arg, Res, S2);
                Err ->
                    ?ERROR_MSG("Upload error: ~p.~n", [Err]),
                    {done, {error, unexpected_error}}
            end;
        false ->
            ?ERROR_MSG("Upload error: no filename.~n", []),
            {done, {error, unexpected_error}}
    end;

add_file_chunk(Arg, [{body, Data}|Res], State)
  when State#upload.filename /= undefined ->
    case file:write(State#upload.fd, Data) of
        ok ->
            add_file_chunk(Arg, Res, State);
        Err ->
            ?ERROR_MSG("Upload error: ~p.~n", [Err]),
            {done, {error, unexpected_error}}
    end.

extract(Arg, State) ->
    Request = Arg#arg.req,
    case Request#http_request.method of
        'GET' ->
            {Pathinfo, Parsed_query} = case rewrite:is_rewrite(Arg#arg.pathinfo) of
                                          false -> {Arg#arg.pathinfo, parse_query(yaws_api:parse_query(Arg))};
                                          {_, _} = R -> R 
                                       end,
            ?DEBUG("PathInfo : ~p~nQueryData : ~p~n", [Arg#arg.pathinfo, Parsed_query]),
            {'GET', Pathinfo, Parsed_query};
        _ ->
            case Arg#arg.headers#headers.content_type of
                "multipart/form-data;"++ _Boundary ->
                    case yaws_api:parse_multipart_post(Arg) of
                        {cont, Cont, Res} ->
                            case add_file_chunk(Arg, Res, State) of
                                {done, Result} ->
                                    Result;
                                {cont, NewState} ->
                                    {get_more, Cont, NewState}
                            end;
                        {result, Res} ->
                            case add_file_chunk(Arg, Res, State#upload{last=true}) of
                                {done, Result} ->
                                    Result;
                                {cont, _} ->
                                    {error, unexpected_error}
                            end
                    end;
                _ContentType ->
                    OriginalMethod = Request#http_request.method,
                    NewArg = Arg#arg{req = Arg#arg.req#http_request{method = 'POST'}},
                    Query = yaws_api:parse_post(NewArg) ++ yaws_api:parse_query(NewArg),
                    Method = case utils:get(Query, ["_method"]) of
                                 [none] ->
                                     OriginalMethod;
                                 [StringMethod] ->
                                     list_to_atom(string:to_upper(StringMethod))
                             end,
                    {Method, Arg#arg.pathinfo, parse_query(Query)}
            end
    end.

parse(#arg{} = Arg)
  when Arg#arg.state == undefined ->
    extract(Arg, #upload{});

parse(#arg{} = Arg) ->
    extract(Arg, Arg#arg.state).

extract_dictionary([], _) ->
    [];
extract_dictionary([{DictElem, Value}|Tail], Name) ->
    Elem = case re:run(DictElem, "^(.*)\\[([^\]]+)\\]$ ?", [{capture, all, list}]) of
               {match, [_, Name, Key]} ->
                   [{Key, Value}];
               _ ->
                   []
           end,
    Elem ++ extract_dictionary(Tail, Name).

remove_key([], _) ->
    [];
remove_key([{Key, Value}|Tail], Name) ->
    ElemName = case re:run(Key, "^(.*)\\[([^\]]+)\\]$ ?", [{capture, all, list}]) of
                   {match, [_, Name, _]} ->
                       Name;
                   _ ->
                       Key
               end,
    Elem = case ElemName of
               Name ->
                   [];
               _ ->
                   [{Key, Value}]
           end,
    Elem ++ remove_key(Tail, Name).

parse_query_elems([]) ->
    [];
parse_query_elems([{Key, Value}|Tail]=Query) ->
    Elem = case re:run(Key, "^(.*)\\[([^\]]+)\\]$ ?", [{capture, all, list}]) of
               {match, [_, Name, _]} ->
                   [{Name, extract_dictionary(Query, Name)}];
               _ ->
                   [{Key, Value}]
           end,
    [{ToRemove, _}] = Elem,
    Elem ++ parse_query_elems(remove_key(Tail, ToRemove)).

parse_query(AsciiDirtyQuery) ->
    AsciiQuery = lists:filter(fun({Key, _}) ->
                                      case Key of
                                          [] ->
                                              false;
                                          _ ->
                                              true
                                      end
                              end,
                              AsciiDirtyQuery),
    Query = lists:map(fun({Key, Value}) ->
                              case Value of
                                  undefined ->
                                      {unicode:characters_to_list(list_to_binary(Key), unicode), ""};
                                  _ ->
                                      {unicode:characters_to_list(list_to_binary(Key), unicode),
                                       unicode:characters_to_list(list_to_binary(Value), unicode)}
                              end
                      end,
                      AsciiQuery),
    parse_query_elems(Query).


-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

parse_query_test() ->
    ?assertEqual([{"Test", "test"}], parse_query([{"Test", "test"}])),
    ?assertEqual([{"test", [{"to", "test"}]}], parse_query([{"test[to]", "test"}])).

-endif.
