program Examples;

{$APPTYPE CONSOLE}

uses
  SysUtils, tfNumerics;

procedure BigIntExamples;
var
  A, B, C, D, G: BigInteger;

begin
// Abs
  A:= 42;
  Writeln(BigInteger.Abs(A).ToString);    // outputs '42'
  A:= -77;
  Writeln(BigInteger.Abs(A).ToString);    // outputs '77'

// DivRem
  A:= -42;
  B:= 77;

  A:= BigInteger.DivRem(B, A, B);
  Writeln('77 div -42 = ', A.ToString);    // outputs '-1'
  Writeln('77 mod -42 = ', B.ToString);    // outputs '35'

//  Writeln('-77 div -42 = ', -77 div -42);    // outputs '-1'
//  Writeln('-77 mod -42 = ', -77 mod -42);    // outputs '35'

  A:= 10;
  Writeln(BigInteger.Pow(A, 5).ToString);    // outputs '100000'

  A:= 10;
  Writeln(BigInteger.Sqr(A).ToString);

  A:= 100;
  Writeln(BigInteger.Sqrt(A).ToString);    // outputs '10'
  A:= 99;
  Writeln(BigInteger.Sqrt(A).ToString);    // outputs '9'

  Writeln('BigInteger.GCD');
  A:= 100;
  B:= 80;
  Writeln(BigInteger.GCD(A, B).ToString);    // outputs '20'

  Writeln('BigInteger.EGCD');
  A:= 200;
  B:= 80;
  G:= BigInteger.EGCD(A, B, C, D);
  Writeln(G.ToString);    // outputs '40'
  Writeln(C.ToString);    // outputs '1'
  Writeln(D.ToString);    // outputs '-2'

  Writeln('BigInteger.ModPow');
  A:= 10;
  B:= 3;
  C:= 512;
  Writeln(BigInteger.ModPow(A, B, C).ToString);    // outputs '488'
end;

begin
  ReportMemoryLeaksOnShutdown:= True;
  try
    BigIntExamples;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  Readln;
end.
