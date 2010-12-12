Program test;
Var
a,b:real; // YAY a comment !!
c: integer; /* Yet
another
comment */ s:string;
test : boolean;
Begin
a := 3;
b:=8.5;
test := (a > b);
c := 2;
s := "yay";
writeln(s, " ", a);
a := b;
writeln(b, " ", c, "yeepee");
if ( !test ) then
        writeln("youhou");
if (a < 3) then
Begin
	writeln("if");
	a := 4;
End
else
	writeln("else");	
End.

