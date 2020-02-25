:- use_module(library(http/websocket)).
:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).


server(Port) :-
        http_server(http_dispatch, [port(Port)]).
