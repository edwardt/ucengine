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
-module(uce_presence_mnesia).

-author('victor.goya@af83.com').

-behaviour(gen_uce_presence).

-export([init/0, drop/0]).

-export([add/2,
         list/1,
         get/2,
         delete/2,
         update/2,
         all/1]).

-include("uce.hrl").

init() ->
    mnesia:create_table(uce_presence,
                        [{disc_copies, [node()]},
                         {type, set},
                         {attributes, record_info(fields, uce_presence)}]).

add(_Domain, #uce_presence{}=Presence) ->
    case mnesia:transaction(fun() ->
                                    mnesia:write(Presence)
                            end) of
        {atomic, _} ->
            {ok, Presence#uce_presence.id};
        {aborted, _} ->
            throw({error, bad_parameters})
    end.

list(User) ->
    case mnesia:transaction(fun() ->
				    mnesia:match_object(#uce_presence{id={'_','_'},
                                                      user=User,
                                                      auth='_',
                                                      timeout='_',
                                                      last_activity='_',
                                                      resource='_',
                                                      metadata='_'})
                            end) of
        {atomic, []} ->
            {ok, []};
        {atomic, Records} ->
            {ok, Records};
        {aborted, _} ->
            throw({error, bad_parameters})
    end.

all(Domain) ->
    case  mnesia:dirty_match_object(#uce_presence{id={'_', Domain},
                                            user='_',
                                            auth='_',
                                            timeout='_',
                                            last_activity='_',
                                            resource='_',
                                            metadata='_'}) of
        Records when is_list(Records) ->
            {ok, Records};
        Error ->
            ?ERROR_MSG("uce_presence:all on domain ~s : ~p~n", [Domain, Error]),
            throw({error, bad_parameters})
    end.

get(_Domain, Id) ->
    case mnesia:transaction(fun() ->
                                    mnesia:read(uce_presence, Id)
                            end) of
        {atomic, [Record]} ->
            {ok, Record};
        {atomic, _} ->
            throw({error, not_found});
        {aborted, _} ->
            throw({error, bad_parameters})
    end.

delete(_Domain, Id) ->
    case mnesia:transaction(fun() ->
                                    mnesia:delete({uce_presence, Id})
                            end) of
        {atomic, _} ->
            {ok, deleted};
        {aborted, _} ->
            throw({error, bad_parameters})
    end.

update(_Domain, #uce_presence{}=Presence) ->
    case mnesia:transaction(fun() ->
                                    mnesia:write(Presence)
                            end) of
        {atomic, _} ->
            {ok, updated};
        {aborted, _} ->
            throw({error, bad_parameters})
    end.

drop() ->
    mnesia:clear_table(uce_presence).
