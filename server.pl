:- use_module(library(http/websocket)).
:- use_module(library(http/http_server)).

:- http_handler(root('.'),
                meld,
                []).
:- http_handler(root(ws),
                http_upgrade_to_websocket(echo, []),
                []).

echo(WebSocket) :-
    ws_receive(WebSocket, Message),
    (   Message.opcode==close
    ->  true
    ;   ws_send(WebSocket, Message),
        echo(WebSocket)
    ).

meld(_Request) :-
    reply_html_page(
        title('Demo server'),
        [ h1('Hello World!')
        ]).

:- initialization http_server([port(3000)]).
