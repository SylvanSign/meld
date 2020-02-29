:- use_module(library(http/http_server)).


:- http_handler(root(.), meld, []).

meld(_Request) :-
  reply_html_page(
    \head_tag(jake),
    [ \thought_input(1),
      \thought_input(2)
    ]
  ).

head_tag(Title) -->
  html(
    [ meta(charset='UTF-8'),
      meta([name=viewport, content='width=device-width, initial-scale=1.0']),
      meta(['http-equiv'='X-UA-Compatible', content='ie=edge']),
      title(Title)
    ]).

thought_input(Id) -->
  html(
    ul(
      [ li(
          [ label(for=thought, 'Thought: '),
            input([type=text, id=thought_+Id])
          ])
      ])
  ).

server :-
  http_server([port(8000)]).
