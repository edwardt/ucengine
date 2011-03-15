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
-module(uce_async_ws).

-author('victor.goya@af83.com').

-export([wait/10]).

-include("uce.hrl").

wait(Domain, Location, Search, From, Types, Uid, Start, End, Parent, Socket) ->
    Pid = spawn(fun() ->
                        receive
                            {ok, WebSocket} ->
                                case uce_async:listen(Domain,
                                                      Location,
                                                      Search,
                                                      From,
                                                      Types,
                                                      Uid,
                                                      Start,
                                                      End,
                                                      Parent,
                                                      Socket) of
                                    ok ->
                                        nothing;
                                    {error, Reason} ->
                                        ?ERROR_MSG("Error in event wait: ~p~n", [Reason])
                                end,
                                yaws_api:stream_process_end(Socket, WebSocket);
                            _ ->
                                nothing
                        end
                end),
    {websocket, Pid, passive}.
