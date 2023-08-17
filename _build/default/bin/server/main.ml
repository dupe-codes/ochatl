#1 "bin/server/main.eml.ml"
let home =
let ___eml_buffer = Buffer.create 4096 in
(Buffer.add_string ___eml_buffer "<html>\n<body>\n  <form>\n    <input type=\"text\" id=\"room\" size=\"32\" autofocus value=\"default\">\n    <input type=\"submit\" value=\"Send\">\n    <input type=\"text\" id=\"message\" size=\"64\" autofocus>\n  </form>\n  <script>\n    let room = document.getElementById(\"room\");\n    let message = document.getElementById(\"message\");\n    let chat = document.querySelector(\"body\");\n    let socket = new WebSocket(\"ws://\" + window.location.host + \"/chat/\" + room);\n\n    socket.onmessage = function (event) {\n      let item = document.createElement(\"div\");\n      item.innerText = event.data;\n      chat.appendChild(item);\n    };\n\n    document.querySelector(\"form\").onsubmit = function () {\n      if (socket.readyState != WebSocket.OPEN)\n        return false;\n      if (!message.value)\n        return false;\n\n      socket.send(message.value);\n      message.value = \"\";\n      return false;\n    };\n  </script>\n</body>\n</html>\n\n");
(Buffer.contents ___eml_buffer)
#35 "bin/server/main.eml.ml"
let sockets = Hashtbl.create 10

let track =
  let last_id = ref 0 in
  fun socket ->
    Hashtbl.replace sockets !last_id socket;
    let new_id = !last_id in
    last_id := !last_id + 1;
    new_id

let handler room_name =
  Printf.printf "Joining room: %s!" room_name;
  Dream.websocket (fun socket ->
      let socket_id = track socket in
      let rec loop () =
        match%lwt Dream.receive socket with
        | Some message ->
            let%lwt () = Dream.send socket message in
            loop ()
        | None ->
            Printf.printf "Removing socket %d" socket_id;
            Dream.close_websocket socket
      in
      loop ()
  )

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router
       [
         ( Dream.get "/" (fun _ -> Dream.html home));
         ( Dream.get "/chat/:room" @@ fun request ->
           handler (Dream.param request "room") );
       ]
