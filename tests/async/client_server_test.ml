
(** This test verifies that the client and server functions generated by the
    IDL interoperate correctly *)

let with_ok f = function
  | Ok r -> f r
  | Error _ -> Alcotest.fail "RPC call failed"

let test_call_async () =
  let open Async in

  let server =
    let module Server = Test_common.Test_interface.Interface(Rpc_async.GenServer ()) in
    Server.add (fun a b -> Rpc_async.M.return (a + b));
    Server.sub (fun a b -> Rpc_async.M.return (a - b));
    Server.mul (fun a b -> Rpc_async.M.return (a * b));
    Server.div (fun a b -> Rpc_async.M.return (a / b));
    Rpc_async.server Server.implementation
  in
  let rpc = server in
  let module Client = Test_common.Test_interface.Interface(Rpc_async.GenClient()) in
  let run () =
    Client.add rpc 1 3 |> Rpc_async.M.deferred >>=
    with_ok (fun n -> Alcotest.(check int) "add" 4 n |> return) >>= fun () ->
    Client.sub rpc 1 3 |> Rpc_async.M.deferred >>=
    with_ok (fun n -> Alcotest.(check int) "sub" (-2) n |> return) >>= fun () ->
    Client.mul rpc 2 3 |> Rpc_async.M.deferred >>=
    with_ok (fun n -> Alcotest.(check int) "mul" 6 n |> return) >>= fun () ->
    Client.div rpc 8 2 |> Rpc_async.M.deferred >>=
    with_ok (fun n -> Alcotest.(check int) "div" 4 n |> return)
  in
  Thread_safe.block_on_async_exn run

let tests =
  [ "test_call_async", `Quick, test_call_async
  ]
