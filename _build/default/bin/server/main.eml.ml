let home =
  <html>
  <body>
    <form>
      <input type="text" id="room" size="32" autofocus value="default">
      <input type="submit" value="Send">
      <input type="text" id="message" size="64" autofocus>
    </form>
    <script>
      let room = document.getElementById("room");
      let message = document.getElementById("message");
      let chat = document.querySelector("body");
      let socket = new WebSocket("ws://" + window.location.host + "/chat/" + room);

      socket.onmessage = function (event) {
        let item = document.createElement("div");
        item.innerText = event.data;
        chat.appendChild(item);
      };

      document.querySelector("form").onsubmit = function () {
        if (socket.readyState != WebSocket.OPEN)
          return false;
        if (!message.value)
          return false;

        socket.send(message.value);
        message.value = "";
        return false;
      };
    </script>
  </body>
  </html>

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
