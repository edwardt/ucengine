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
-module(uce_presence_mongodb).

-author('victor.goya@af83.com').

-behaviour(gen_uce_presence).

-export([add/1,
         list/1,
         get/2,
         delete/2,
         update/1,
         all/1]).

-include("uce.hrl").
-include("mongodb.hrl").

add(#uce_presence{domain=Domain}=Presence) ->
    case catch emongo:insert_sync(Domain, "uce_presence", to_collection(Presence)) of
        {'EXIT', Reason} ->
            ?ERROR_MSG("~p~n", [Reason]),
            throw({error, bad_parameters});
        _ ->
            {ok, Presence#uce_presence.id}
    end.

list({User, Domain}) ->
    case catch emongo:find_all(Domain, "uce_presence", [{"user", User},
                                                             {"domain", Domain}]) of
        {'EXIT', Reason} ->
            ?ERROR_MSG("~p~n", [Reason]),
            throw({error, bad_parameters});
        Collections ->
            Records = lists:map(fun(Collection) ->
                                        from_collection(Collection)
                                end,
                                Collections),
            {ok, Records}
    end.

all(Domain) ->
    case catch emongo:find_all(Domain, "uce_presence", [{"domain", Domain}]) of
        {'EXIT', Reason} ->
            ?ERROR_MSG("~p~n", [Reason]),
            throw({error, bad_parameters});
        Collections ->
            Records = lists:map(fun(Collection) ->
                                        from_collection(Collection)
                                end,
                                Collections),
            {ok, Records}
    end.

get(Domain, Id) ->
    case catch emongo:find_one(Domain, "uce_presence", [{"id", Id}]) of
        {'EXIT', Reason} ->
            ?ERROR_MSG("~p~n", [Reason]),
            throw({error, bad_parameters});
        [Collection] ->
            {ok, from_collection(Collection)};
        _ ->
            throw({error, not_found})
    end.

delete(Domain, Id) ->
    case catch emongo:delete_sync(Domain, "uce_presence", [{"id", Id}]) of
        {'EXIT', Reason} ->
            ?ERROR_MSG("~p~n", [Reason]),
            throw({error, bad_parameters});
        _ ->
            {ok, deleted}
    end.

update(#uce_presence{domain=Domain}=Presence) ->
    case catch emongo:update_sync(Domain, "uce_presence",
                                  [{"id", Presence#uce_presence.id}],
                                  to_collection(Presence), false) of
        {'EXIT', Reason} ->
            ?ERROR_MSG("~p~n", [Reason]),
            throw({error, bad_parameters});
        _ ->
            {ok, udpated}
    end.


from_collection(Collection) ->
    case utils:get(mongodb_helpers:collection_to_list(Collection),
                   ["id", "domain", "user", "auth", "last_activity", "timeout", "metadata"]) of
        [Id, Domain, User, Auth, LastActivity, Timeout, Metadata] ->
            #uce_presence{id=Id,
                          domain=Domain,
                          user={User, Domain},
                          auth=Auth,
                          last_activity=list_to_integer(LastActivity),
                          timeout=list_to_integer(Timeout),
                          metadata=Metadata};
        _ ->
            throw({error, bad_parameters})
    end.

to_collection(#uce_presence{id=Id,
                            domain=Domain,
                            user={User, _},
                            auth=Auth,
                            last_activity=LastActivity,
                            timeout=Timeout,
                            metadata=Metadata}) ->
    [{"id", Id},
     {"domain", Domain},
     {"user", User},
     {"auth", Auth},
     {"last_activity", integer_to_list(LastActivity)},
     {"timeout", integer_to_list(Timeout)},
     {"metadata", Metadata}].
