let () =
let d1 = Domain.spawn (fun ()->
  print_endline "hello from Domain 1")
in
let d2 = Domain.spawn (fun () ->
  print_endline "hello from domain 2")in
print_endline "hello from domain 0";
Domain.join d1;
Domain.join d2