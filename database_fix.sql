PRAGMA foreign_keys = 1;

insert into names (name) values ("{.I}slah bint Yuhannah");
insert into names (name) values ("G{u:}rc{u:} {.I}skender");
insert into names (name) values ("Umm Davud Mihri bint {.I}skender");
insert into names (name) values ("El{.z}bieta Piekarska");
insert into names (name) values ("El{.z}bieta Traidenyt{.e}");
insert into names (name) values ("D{zv}iugint{.e} Litovka");

update registrations set reg_owner_name = "{.I}slah bint Yuhannah" where reg_owner_name = "{I.}slah bint Yuhannah";
update registrations set text_name = "{.I}slah bint Yuhannah" where text_name = "{I.}slah bint Yuhannah";
update notes set note_name = "{.I}slah bint Yuhannah" where note_name = "{I.}slah bint Yuhannah";
update registrations set reg_owner_name = "G{u:}rc{u:} {.I}skender" where reg_owner_name = "G{u:}rc{u:} {I.}skender";
update registrations set text_name = "G{u:}rc{u:} {.I}skender" where text_name = "G{u:}rc{u:} {I.}skender";
update notes set note_name = "G{u:}rc{u:} {.I}skender" where note_name = "G{u:}rc{u:} {I.}skender";
update registrations set reg_owner_name = "Umm Davud Mihri bint {.I}skender" where reg_owner_name = "Umm Davud Mihri bint {I.}skender";
update registrations set text_name = "Umm Davud Mihri bint {.I}skender" where text_name = "Umm Davud Mihri bint {I.}skender";
update notes set note_name = "Umm Davud Mihri bint {.I}skender" where note_name = "Umm Davud Mihri bint {I.}skender";
update registrations set reg_owner_name = "El{.z}bieta Piekarska" where reg_owner_name = "El{z.}bieta Piekarska";
update registrations set text_name = "El{.z}bieta Piekarska" where text_name = "El{z.}bieta Piekarska";
update notes set note_name = "El{.z}bieta Piekarska" where note_name = "El{z.}bieta Piekarska";
update registrations set reg_owner_name = "El{.z}bieta Traidenyt{.e}" where reg_owner_name = "El{z.}bieta Traidenyt{e.}";
update registrations set text_name = "El{.z}bieta Traidenyt{.e}" where text_name = "El{z.}bieta Traidenyt{e.}";
update notes set note_name = "El{.z}bieta Traidenyt{.e}" where note_name = "El{z.}bieta Traidenyt{e.}";
update registrations set reg_owner_name = "D{zv}iugint{.e} Litovka" where reg_owner_name = "D{zv}iugint{e.} Litovka";
update registrations set text_name = "D{zv}iugint{.e} Litovka" where text_name = "D{zv}iugint{e.} Litovka";
update notes set note_name = "D{zv}iugint{.e} Litovka" where note_name = "D{zv}iugint{e.} Litovka";

delete from names where name in
("{I.}slah bint Yuhannah",
"G{u:}rc{u:} {I.}skender",
"Umm Davud Mihri bint {I.}skender",
"El{z.}bieta Piekarska",
"El{z.}bieta Traidenyt{e.}",
"D{zv}iugint{e.} Litovka");
