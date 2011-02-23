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
-module(uce_sup).

-behaviour(supervisor).

-export([start_link/0, init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init(_) ->
    PubSubSup = case config:get(pubsub) of
                    mnesia ->
                        [{mnesia_pubsub,
                          {mnesia_pubsub, start_link, []},
                          permanent, brutal_kill, worker, [mnesia_pubsub]}];
                    amqp ->
                        [{amqp_pubsub,
                          {amqp_pubsub, start_link, []},
                          permanent, brutal_kill, worker, [amqp_pubsub]}]
                end,
    SolrSup = case config:get(search) of
                  solr ->
                      [{uce_solr_commiter,
                        {uce_solr_commiter, start_link, []},
                        permanent, brutal_kill, worker, [uce_solr_commiter]}];
                  _ ->
                      []
              end,
    {ok, {{one_for_one, 10, 10},
          [{routes,
            {routes, start_link, []},
            permanent, brutal_kill, worker, [routes]},
           {timeout,
            {timeout, start_link, []},
            permanent, brutal_kill, worker, [timeout]}] ++
              PubSubSup ++ SolrSup}}.
