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
      match%lwt Dream.receive socket with
      | Some message -> Dream.send socket "Hello, world!"
      | None -> Dream.close_websocket socket)

let () =
  Dream.run
  @@ Dream.router
       [
         ( Dream.get "/chat/:room" @@ fun request ->
           handler (Dream.param request "room") );
       ]
