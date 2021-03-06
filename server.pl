:- use_module(library(http/http_server)).
:- use_module(library(http/websocket)).
:- use_module(library(http/hub)).
:- use_module(library(http/js_write)).


:- http_handler(root(.), meld, []).
:- http_handler(root(websocket),
                http_upgrade_to_websocket(
                  connect_websocket,
                  [ guarded(false)
                  ]),
                [ id(websocket)
                ]).

meld(_Request) :-
  reply_html_page(
    \head_tag(jake),
    [ \header,
      \thoughts,
      \javascript
    ]
  ).

header -->
  html(header(h1('Hive Mind'))).

head_tag(Title) -->
  html([ meta(charset='UTF-8'),
         meta([name=viewport, content='width=device-width, initial-scale=1.0']),
         meta(['http-equiv'='X-UA-Compatible', content='ie=edge']),
         title(Title)
       ]).

thoughts -->
  html([ \me(me),
         \other(other)
       ]).

info(Name) -->
  html([ li(['Name: ', Name]),
         li(['Last thought: ', span(id=last_+Name, [])])
       ]).

other(Name) -->
  html(ul(\info(Name))).

me(Name) -->
  html(ul([ \info(Name),
            li([ label(for=me, 'Thought: '),
                 input([ type=text,
                         id=me,
                         autofocus,
                         placeholder='type a thought and hit Enter...',
                         onkeypress='handleInput(event)'
                       ], [])
               ])
          ])).

javascript -->
  { http_link_to_id(websocket, [], WebSocketPath)
  },
  js_script({|javascript(WebSocketPath)||
const webSocketURL = `${window.location.host}${WebSocketPath}`
const webSocket = new WebSocket(`ws://${webSocketURL}`)

webSocket.onmessage = event => {
  const { data } = event
  console.log(`Got data: ${data}`)
  const message = JSON.parse(JSON.parse(data).data)
  console.log(`Got message: ${JSON.stringify(message)}`)
}

function handleInput(e) {
  if (e.keyCode == 13) {
    const me = document.getElementById('me')
    const my_last = document.getElementById('last_me')
    const thought = me.value
    send({ thought })
    me.value = ''
    // me.disabled = true
    my_last.innerText = thought
  }
}

function send(data) {
  webSocket.send(JSON.stringify(data))
}
  |}).


connect_websocket(WebSocket) :-
  hub_add(websocket_hub, WebSocket, _Id).

create_websocket_hub :-
  hub_create(websocket_hub, Hub, []),
  thread_create(message_handler(Hub), _, [alias(message_handler)]).

message_handler(Hub) :-
  thread_get_message(Hub.queues.event, Message),
  handle_message(Message, Hub),
  message_handler(Hub).

handle_message(Message, Hub) :-
	websocket{opcode:text} :< Message, !,
  write('got message: '), writeln(Message),
  broadcast(Hub, Message).

handle_message(Message, Hub) :-
	hub{joined:Id} :< Message, !,
  write('new join: '), writeln(Message),
  broadcast(Hub, Message).

handle_message(Message, Hub) :-
	hub{left:Id} :< Message, !,
  write('leave: '), writeln(Message),
  broadcast(Hub, Message).

handle_message(Message, Hub) :-
  write('ignored message: '), writeln(Message),
  broadcast(Hub, Message).

broadcast(Hub, Message) :-
	hub_broadcast(Hub.name, json(Message)).

server :-
  create_websocket_hub,
  http_server([port(8000)]).

:- initialization(server).
